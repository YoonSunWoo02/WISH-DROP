-- Wish Drop — 프로젝트 삭제 시 후원 내역 함께 삭제 (CASCADE)
-- 원인: projects 삭제 시 donations가 project_id를 참조하면 FK 제약으로 삭제 실패
-- 적용: 프로젝트 삭제 시 해당 프로젝트의 후원 내역(donations)도 자동 삭제
-- 실행: Supabase 대시보드 → SQL Editor에서 이 파일 내용 실행

-- 1. 기존 FK 제약 제거 (에러 메시지에 나온 이름 우선)
ALTER TABLE donations
  DROP CONSTRAINT IF EXISTS "donations_duplicate_project_id_fkey";

ALTER TABLE donations
  DROP CONSTRAINT IF EXISTS "donations_project_id_fkey";

-- 2. CASCADE 옵션으로 FK 다시 생성
ALTER TABLE donations
  ADD CONSTRAINT "donations_project_id_fkey"
  FOREIGN KEY (project_id)
  REFERENCES projects (id)
  ON DELETE CASCADE;
