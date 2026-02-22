-- Wish Drop — 같은 위시 '하루 1회' → '24시간 후 재후원' 규칙으로 변경
-- (user_id, project_id, 날짜) 유니크 인덱스 제거 → 24시간은 앱에서만 체크

DROP INDEX IF EXISTS one_donation_per_day_idx;
