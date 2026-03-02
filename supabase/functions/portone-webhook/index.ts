// supabase/functions/portone-webhook/index.ts
// QR 결제 등 클라이언트에서 결과를 못 받는 경우 웹훅으로 donations 저장

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') {
      return new Response('Method Not Allowed', { status: 405 })
    }

    const body = await req.json()

    // PortOne 웹훅 두 가지 형식 지원
    // 2024-04-25: { type: "Transaction.Paid", data: { paymentId, transactionId, ... } }
    // 2024-01-01: { payment_id, tx_id, status, amount?, custom_data? }
    let paymentId: string | null = null
    let totalAmount: number | null = null
    let customData: unknown = null

    if (body.type === 'Transaction.Paid' && body.data) {
      paymentId = body.data.paymentId ?? body.data.merchant_order_ref ?? null
      totalAmount = body.data.amount ?? body.data.totalAmount ?? body.data.total_amount ?? null
      customData = body.data.customData ?? body.data.custom_data ?? null
    } else {
      // 2024-01-01 형식
      paymentId = body.paymentId ?? body.payment_id ?? null
      const status = body.status ?? ''
      totalAmount = body.totalAmount ?? body.total_amount ?? body.amount ?? null
      customData = body.customData ?? body.custom_data ?? null

      if (status !== 'PAID' && status !== 'Paid') {
        return new Response(JSON.stringify({ message: 'Ignored (Not PAID)' }), { status: 200 })
      }
    }

    // 2024-04-25 형식에서 type만 체크
    if (body.type && body.type !== 'Transaction.Paid') {
      return new Response(JSON.stringify({ message: 'Ignored (Not Transaction.Paid)' }), { status: 200 })
    }

    if (!paymentId) {
      console.error('[Webhook] paymentId 없음:', JSON.stringify(body))
      return new Response(JSON.stringify({ error: 'paymentId required' }), { status: 400 })
    }

    let userId: string | null = null
    let projectId: number | null = null
    let message = '포트원 웹훅 자동 저장'

    if (customData) {
      try {
        const parsed = typeof customData === 'string' ? JSON.parse(customData) : customData
        userId = parsed.userId ?? null
        const pid = parsed.projectId ?? parsed.project_id
        projectId = pid != null ? parseInt(String(pid), 10) : null
        if (parsed.message) message = parsed.message
      } catch (e) {
        console.error('customData 파싱 실패:', e)
      }
    }

    // projectId: customData에서 없으면 paymentId에서 추출 (payment-{projectId}-{ts}-{rand})
    if (projectId == null || isNaN(projectId)) {
      const match = paymentId.match(/^payment-(\d+)-/)
      if (match) {
        projectId = parseInt(match[1], 10)
      }
    }
    if (projectId == null || isNaN(projectId)) {
      console.error('[Webhook] projectId 없음, paymentId:', paymentId, 'customData:', customData)
      return new Response(JSON.stringify({ error: 'projectId required' }), { status: 400 })
    }

    // userId가 'guest'면 null 처리 (donations FK 제약 회피)
    if (userId === 'guest') userId = null

    // totalAmount 없으면 기본값 0 (웹훅에 포함되지 않는 경우)
    const amount = totalAmount != null ? Math.round(Number(totalAmount)) : 0
    if (amount <= 0) {
      console.error('[Webhook] amount 없음 또는 0:', totalAmount)
      return new Response(JSON.stringify({ error: 'amount required' }), { status: 400 })
    }

    console.log(`[Webhook] 결제 수신 - paymentId: ${paymentId}, amount: ${amount}, projectId: ${projectId}`)

    const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''

    if (!serviceRoleKey || !supabaseUrl) {
      console.error('[Webhook] SERVICE_ROLE_KEY 또는 SUPABASE_URL 없음')
      return new Response(JSON.stringify({ error: 'Server config missing' }), { status: 500 })
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey)

    // 중복 저장 방지
    const { data: existing } = await supabaseAdmin
      .from('donations')
      .select('id')
      .eq('payment_id', paymentId)
      .maybeSingle()

    if (existing) {
      console.log('[Webhook] 이미 처리된 결제:', paymentId)
      return new Response(JSON.stringify({ message: 'Already processed' }), { status: 200 })
    }

    // donations INSERT (user_id가 null일 수 있음 - RLS/스키마 확인 필요)
    const insertPayload: Record<string, unknown> = {
      payment_id: paymentId,
      amount,
      project_id: projectId,
      message,
      is_anonymous: userId == null,
    }
    if (userId) insertPayload.user_id = userId

    const { error: insertError } = await supabaseAdmin.from('donations').insert(insertPayload)

    if (insertError) {
      console.error('[Webhook] insert 에러:', insertError)
      throw insertError
    }

    // projects.current_amount 증가
    const { error: rpcError } = await supabaseAdmin.rpc('increment_project_amount', {
      p_project_id: projectId,
      p_amount: amount,
    })

    if (rpcError) {
      console.error('[Webhook] increment_project_amount 에러:', rpcError)
      // insert는 성공했으므로 200 반환 (금액 반영은 별도 수동 조치 가능)
    }

    console.log('[Webhook] DB 저장 성공')
    return new Response(JSON.stringify({ message: 'Success' }), { status: 200 })
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    console.error('[Webhook] 에러:', errorMessage)
    return new Response(JSON.stringify({ error: errorMessage }), { status: 400 })
  }
})
