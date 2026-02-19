-- Wish Drop — 위시 자동 종료 기능 (wish_completion_feature.md STEP 1)
-- Supabase SQL Editor에서 이 파일 내용을 실행하세요.

-- ① donations 테이블에 payment_id 컬럼 추가 (실제 DB에 없으므로 추가)
ALTER TABLE donations
  ADD COLUMN IF NOT EXISTS payment_id text;

CREATE UNIQUE INDEX IF NOT EXISTS donations_payment_id_key
  ON donations (payment_id)
  WHERE payment_id IS NOT NULL;

-- ② projects에 status 컬럼이 없으면 추가 (기본값 'active')
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';

-- ③ 기간 만료 / 금액 달성된 위시를 일괄 completed 처리하는 함수
CREATE OR REPLACE FUNCTION check_and_complete_projects()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE projects
  SET status = 'completed'
  WHERE status = 'active'
    AND (
      current_amount >= target_amount
      OR (end_date IS NOT NULL AND end_date < NOW())
    );
END;
$$;

-- ④ projects.current_amount UPDATE 시 해당 위시 자동 종료 체크 트리거
CREATE OR REPLACE FUNCTION trigger_check_project_completion()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE projects
  SET status = 'completed'
  WHERE id = NEW.id
    AND status = 'active'
    AND (
      current_amount >= target_amount
      OR (end_date IS NOT NULL AND end_date < NOW())
    );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_current_amount_update ON projects;
CREATE TRIGGER on_current_amount_update
  AFTER UPDATE OF current_amount ON projects
  FOR EACH ROW
  EXECUTE FUNCTION trigger_check_project_completion();
