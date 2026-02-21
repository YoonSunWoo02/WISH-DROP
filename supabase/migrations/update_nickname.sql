-- Wish Drop — 닉네임 변경 + friend_code 결정 (RPC)
-- Supabase 대시보드 > SQL Editor에서 실행 후, edit_profile_page에서 rpc('update_nickname') 호출

CREATE OR REPLACE FUNCTION update_nickname(new_nickname text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_code   text;
  current_number text;
  candidate_code text;
  new_number     text;
  digit_length   int := 4;
  max_val        bigint;
  rand_num       bigint;
  attempt        int := 0;
  max_attempts   int := 100;
BEGIN
  -- 1. 현재 내 friend_code 조회
  SELECT friend_code INTO current_code
  FROM profiles
  WHERE id = auth.uid();

  -- 2. 숫자 부분 추출 (#뒤 문자열). 없거나 형식 다르면 새 코드 발급 루프로
  current_number := NULL;
  IF current_code IS NOT NULL AND position('#' IN current_code) > 0 THEN
    current_number := split_part(current_code, '#', 2);
    IF current_number ~ '^\d{4,8}$' THEN
      -- 3. 새 닉네임 + 기존 숫자 조합 먼저 시도
      candidate_code := new_nickname || '#' || current_number;
      IF NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE friend_code = candidate_code
          AND id != auth.uid()
      ) THEN
        UPDATE profiles
        SET nickname = new_nickname,
            friend_code = candidate_code
        WHERE id = auth.uid();
        RETURN candidate_code;
      END IF;
    END IF;
  END IF;

  -- 4. 중복 있음 또는 기존 코드 없음 → 새 숫자 코드 발급
  --    4자리(0001~9999) → 소진 시 5자리(00001~99999) 자동 확장
  LOOP
    attempt := attempt + 1;

    IF attempt > max_attempts THEN
      digit_length := digit_length + 1;
      attempt      := 0;
      IF digit_length > 8 THEN
        RAISE EXCEPTION '사용 가능한 친구 코드가 없습니다.';
      END IF;
    END IF;

    max_val  := (10::bigint ^ digit_length) - 1;
    rand_num := FLOOR(RANDOM() * max_val)::bigint + 1;
    new_number     := LPAD(rand_num::text, digit_length, '0');
    candidate_code := new_nickname || '#' || new_number;

    -- 중복 체크 (본인 제외: 업데이트 전 본인 행도 제외)
    IF NOT EXISTS (
      SELECT 1 FROM profiles
      WHERE friend_code = candidate_code
        AND id != auth.uid()
    ) THEN
      UPDATE profiles
      SET nickname = new_nickname,
          friend_code = candidate_code
      WHERE id = auth.uid();
      RETURN candidate_code;
    END IF;
  END LOOP;
END;
$$;
