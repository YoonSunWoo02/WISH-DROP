// supabase/functions/portone-webhook/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// [수정 1] req에 ': Request' 타입을 명시해줘야 빨간 줄이 사라집니다.
serve(async (req: Request) => {
  try {
    // 1. POST 요청만 받음
    if (req.method !== 'POST') {
      return new Response('Method Not Allowed', { status: 405 })
    }

    // 2. 포트원 데이터 받기
    const body = await req.json()
    const { paymentId, status, totalAmount, customData } = body

    console.log(`[Webhook] 결제 수신 - ID: ${paymentId}, 상태: ${status}, 금액: ${totalAmount}`)

    // 3. 결제 완료(PAID)가 아니면 무시
    if (status !== 'PAID') {
      return new Response(JSON.stringify({ message: 'Ignored (Not PAID)' }), { status: 200 })
    }

    // 4. Supabase 관리자 권한으로 접속
    // [수정 2] 아까 'SUPABASE_' 접두사를 빼고 저장했으므로, 여기서도 이름을 맞춰야 합니다!
    const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      serviceRoleKey
    )

    // 5. 중복 저장 방지
    const { data: existing } = await supabaseAdmin
      .from('donations')
      .select('id')
      .eq('payment_id', paymentId)
      .single()

    if (existing) {
      console.log('이미 처리된 결제입니다.')
      return new Response(JSON.stringify({ message: 'Already processed' }), { status: 200 })
    }

    // 6. customData 파싱
    let userId = null;
    let projectId = null;
    
    if (customData) {
      try {
        const parsed = typeof customData === 'string' ? JSON.parse(customData) : customData;
        userId = parsed.userId;
        projectId = parsed.projectId;
      } catch (e) {
        console.error('customData 파싱 실패:', e);
      }
    }

    // 7. DB에 저장!
    const { error } = await supabaseAdmin.from('donations').insert({
      payment_id: paymentId,
      amount: totalAmount,
      user_id: userId,
      project_id: projectId,
      message: '포트원 웹훅 자동 저장',
      created_at: new Date().toISOString(),
    })

    if (error) throw error

    console.log('DB 저장 성공!')
    return new Response(JSON.stringify({ message: 'Success' }), { status: 200 })

  } catch (error: any) { 
    // [수정 3] ': any'를 붙여줘야 에러 메시지(error.message)에 접근할 수 있습니다.
    const errorMessage = error?.message || 'Unknown error';
    console.error('에러 발생:', errorMessage)
    return new Response(JSON.stringify({ error: errorMessage }), { status: 400 })
  }
})