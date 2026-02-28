-- Wish Drop — SNS 공유 기능
-- ① projects에 share_count 컬럼 추가 (공유 횟수 집계)
-- ② 공유 시 호출할 RPC (increment_project_share_count)

-- ── ① share_count 컬럼 (없을 때만 추가) ─────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'projects' AND column_name = 'share_count'
  ) THEN
    ALTER TABLE projects ADD COLUMN share_count int NOT NULL DEFAULT 0;
  END IF;
END $$;

-- ── ② 공유 횟수 증가 RPC ─────────────────────────────────────
CREATE OR REPLACE FUNCTION increment_project_share_count(p_project_id int)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
  UPDATE projects
  SET share_count = share_count + 1
  WHERE id = p_project_id;
$$;
