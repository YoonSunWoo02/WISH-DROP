-- Wish Drop — 한 위시당 한 사용자당 후원 1회만 허용
-- Supabase SQL Editor에서 실행 후, 앱에서 이미 후원한 위시는 후원하기 비활성화

-- 1. 기존 중복 (같은 user_id, project_id 여러 건) 있으면 하나로 합치기
--    → (user_id, project_id)당 금액 합산 후 한 행만 남기고 나머지 삭제
WITH ranked AS (
  SELECT id, user_id, project_id, amount,
         SUM(amount) OVER (PARTITION BY user_id, project_id) AS total_amount,
         ROW_NUMBER() OVER (PARTITION BY user_id, project_id ORDER BY id DESC) AS rn
  FROM donations
),
merged AS (
  SELECT id, total_amount FROM ranked WHERE rn = 1
)
UPDATE donations d
SET amount = m.total_amount
FROM merged m
WHERE d.id = m.id;

-- 같은 (user_id, project_id)에서 id가 가장 큰 것만 남기고 삭제
DELETE FROM donations d
USING donations d2
WHERE d.user_id = d2.user_id
  AND d.project_id = d2.project_id
  AND d.id < d2.id;

-- 2. 한 사용자가 한 프로젝트에 한 번만 후원 가능하도록 UNIQUE 제약
CREATE UNIQUE INDEX IF NOT EXISTS donations_one_per_user_project
  ON donations (user_id, project_id);
