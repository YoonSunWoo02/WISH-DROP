-- Wish Drop — 동시성 문제 해결
-- ① current_amount 원자적 증가 (Read-Modify-Write 제거)
-- ② invite_tokens: 유저당 사용 중인 토큰 1개만
-- ③ friendships: (A,B) / (B,A) 중복 요청 차단

-- ── ① current_amount 원자적 증가 RPC ─────────────────────────────
CREATE OR REPLACE FUNCTION increment_project_amount(
  p_project_id int,
  p_amount int
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
  UPDATE projects
  SET current_amount = current_amount + p_amount
  WHERE id = p_project_id;
$$;

-- ── ② invite_tokens: user_id당 used_at IS NULL인 행 1개만 허용 ───
CREATE UNIQUE INDEX IF NOT EXISTS invite_tokens_user_active_idx
  ON invite_tokens (user_id)
  WHERE used_at IS NULL;

-- ── ③ friendships: (requester, receiver) 쌍 중복 방지 (A→B, B→A 동일 취급) ───
-- 기존에 (A,B)와 (B,A) 둘 다 있으면 한 쪽만 남기기 (id 작은 것 유지)
DELETE FROM friendships f1
USING friendships f2
WHERE LEAST(f1.requester_id::text, f1.receiver_id::text) = LEAST(f2.requester_id::text, f2.receiver_id::text)
  AND GREATEST(f1.requester_id::text, f1.receiver_id::text) = GREATEST(f2.requester_id::text, f2.receiver_id::text)
  AND f1.id > f2.id;

CREATE UNIQUE INDEX IF NOT EXISTS friendships_unique_pair_idx
  ON friendships (
    LEAST(requester_id::text, receiver_id::text),
    GREATEST(requester_id::text, receiver_id::text)
  );
