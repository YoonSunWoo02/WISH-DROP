-- Wish Drop — 위시당 1회 → 같은 위시 하루 1회 제한으로 변경
-- 1. (user_id, project_id) UNIQUE 제거
-- 2. 이미 있는 중복 (같은 유저·같은 프로젝트·같은 날) 합치기 → 금액 합산 후 한 행만 유지
-- 3. (user_id, project_id, 날짜) UNIQUE 인덱스 생성

DROP INDEX IF EXISTS donations_one_per_user_project;

-- 2a. 중복 그룹에서 '남길 행(min id)'의 amount를 그룹 합계로 업데이트
UPDATE donations d
SET amount = sub.total
FROM (
  SELECT
    user_id,
    project_id,
    (created_at AT TIME ZONE 'Asia/Seoul')::date AS d,
    SUM(amount) AS total,
    MIN(id) AS keep_id
  FROM donations
  GROUP BY user_id, project_id, (created_at AT TIME ZONE 'Asia/Seoul')::date
  HAVING COUNT(*) > 1
) sub
WHERE d.user_id = sub.user_id
  AND d.project_id = sub.project_id
  AND (d.created_at AT TIME ZONE 'Asia/Seoul')::date = sub.d
  AND d.id = sub.keep_id;

-- 2b. 중복 그룹에서 '남길 행' 제외한 나머지 삭제
DELETE FROM donations d
USING (
  SELECT
    user_id,
    project_id,
    (created_at AT TIME ZONE 'Asia/Seoul')::date AS d,
    MIN(id) AS keep_id
  FROM donations
  GROUP BY user_id, project_id, (created_at AT TIME ZONE 'Asia/Seoul')::date
  HAVING COUNT(*) > 1
) dup
WHERE d.user_id = dup.user_id
  AND d.project_id = dup.project_id
  AND (d.created_at AT TIME ZONE 'Asia/Seoul')::date = dup.d
  AND d.id <> dup.keep_id;

-- 3. 같은 유저·같은 프로젝트·같은 날(한국 기준) 1건만 허용
CREATE UNIQUE INDEX one_donation_per_day_idx
ON donations (user_id, project_id, ((created_at AT TIME ZONE 'Asia/Seoul')::date));
