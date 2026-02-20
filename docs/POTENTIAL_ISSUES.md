# Wish Drop — 발생 가능한 오류·문제 정리

프로젝트에서 발생할 수 있는 오류, 예외, 환경/설정 이슈를 정리한 문서입니다.

**✅ 점검 완료 (코드 반영됨):** 아래 "점검 반영" 표시된 항목은 수정 적용되어 있습니다.

---

## 1. 환경·설정 (Environment / Config)

### 1.1 `.env` 파일 없음 또는 로드 실패 ✅ 점검 반영
- **위치:** `main()` → `AppConfig.init()` → `dotenv.load(fileName: ".env")`
- **증상:** 앱 기동 시 예외로 크래시 (Flutter 앱이 아예 실행되지 않음)
- **대응:** `.env` 파일이 프로젝트 루트에 있는지 확인. 없으면 `flutter_dotenv`가 예외를 던질 수 있음.
- **적용:** `AppConfig.init()`에서 `dotenv.load()`를 try-catch로 감싸고, 실패 시 `debugPrint` 후 rethrow (명확한 에러 유지).

### 1.2 결제용 환경 변수 키 불일치 ✅ 점검 반영
- **위치:**  
  - `PaymentService` (실제 후원 결제): `STORE_ID`, `CACAO_CHANNEL_KEY`  
  - `PaymentPage`: `PORTONE_STORE_ID`, `PORTONE_CHANNEL_KEY`
- **증상:** 후원 결제 시 `PaymentService.createKakaoRequest`가 `null` 반환 → "환경 설정(.env) 오류" 스낵바
- **적용:** `PaymentService`에서 `STORE_ID` 없으면 `PORTONE_STORE_ID`, `CACAO_CHANNEL_KEY` 없으면 `PORTONE_CHANNEL_KEY` 폴백 사용. 두 가지 키 이름 모두 지원.

### 1.3 Supabase URL/Anon Key 비어 있음
- **위치:** `AppConfig.supabaseUrl`, `AppConfig.supabaseAnonKey` (빈 문자열 가능)
- **증상:** `Supabase.initialize()` 후 모든 API 호출 실패 또는 연결 오류
- **대응:** `.env`에 `SUPABASE_URL`, `SUPABASE_ANON_KEY` 값 확인

---

## 2. 인증·세션 (Auth)

### 2.1 `currentUser`가 null인데 `!` 사용 ✅ 점검 반영
- **위치 예:**  
  - `FriendRepository`: `String get _myId => supabase.auth.currentUser!.id;`  
  - `EditProfilePage._save()`: `Supabase.instance.client.auth.currentUser!.id`  
  - 기타 `currentUser!` 사용처
- **증상:** 로그아웃/세션 만료 후 해당 화면에서 동작 시 `Null check operator used on a null value` 크래시
- **적용:**  
  - `FriendRepository._myId`: `currentUser?.id ?? ''`로 변경, 공개 메서드에서 `_myId.isEmpty`일 때 early return (null/빈 리스트/0 등).  
  - `EditProfilePage._save()`: `currentUser == null`이면 에러 메시지 표시 후 return.

### 2.2 main에서 로그인 상태만으로 Home 진입
- **위치:** `MyApp` build → `home: currentUser == null ? LoginPage() : HomePage()`
- **증상:** 세션 만료 후 앱 재진입 시 잠깐 Home이 보였다가 API 실패로 에러 가능. Realtime/프로필 등이 null 가정하고 있으면 크래시 가능
- **권장:** 홈/프로필 등에서 `currentUser` null이면 로그인 페이지로 리다이렉트

---

## 3. DB·Supabase (Backend)

### 3.1 RPC/테이블 미배포
- **`check_and_complete_projects` RPC:**  
  - `project_repository.checkAndCompleteProjects()`에서 호출.  
  - 마이그레이션 `wish_completion_feature.sql` 미실행 시 RPC 없음 → 예외
- **`invite_tokens` 테이블:**  
  - 친구 초대 링크용. `FriendRepository`에서 insert/select. 테이블 없으면 쿼리 실패
- **`profiles.friend_code`:**  
  - 프로필 수정/닉네임 변경 시 사용. 컬럼 없으면 update 실패
- **대응:** Supabase 대시보드에서 마이그레이션 적용 여부 확인

### 3.2 RLS 정책으로 인한 실패
- **위치:**  
  - `donations` insert, `projects` select/update 등  
  - `profiles` update (본인만 수정 가능해야 함)
- **증상:** 네트워크는 성공이지만 0 rows / permission denied 등으로 실패
- **대응:** Supabase RLS 정책에서 해당 테이블·연산 허용 조건 확인 (예: 본인 `id = auth.uid()`)

### 3.3 `.single()` 사용 시 행 없음 ✅ 점검 반영 (일부)
- **위치:**  
  - `DonationRepository.updateCurrentAmount`: `projects` select `.single()`  
  - `FriendRepository` invite_tokens insert 후 `.select('token').single()`
- **증상:** 해당 조건의 행이 없으면 PostgREST가 예외 (PGRST116 등)
- **적용:** `DonationRepository.updateCurrentAmount`에서 `.single()` → `.maybeSingle()`로 변경, null이면 "프로젝트를 찾을 수 없습니다" 예외 throw. (invite_tokens insert 후 select는 행이 있음이 보장되므로 유지)

### 3.4 FK / CASCADE
- **프로젝트 삭제:**  
  - `donations`에 `project_id` FK가 있고 CASCADE가 아니면, 후원 내역이 있는 프로젝트 삭제 시 FK 위반.  
  - `donations_cascade_on_delete.sql` 적용 여부 확인

---

## 4. 입력·파싱 (Validation / Parse)

### 4.1 위시 만들기 — 목표 금액 ✅ 점검 반영
- **위치:** `CreateWishPage._submitWish()` → `int.parse(_amountController.text)`
- **증상:** 숫자가 아닌 문자 입력 시 `FormatException` (예: "만원", "10,000" 등)
- **적용:** `int.tryParse()` 사용, 쉼표 제거 후 파싱. null 또는 0 이하 시 스낵바 "목표 금액을 숫자로 입력해주세요. (1원 이상)" 표시 후 return.

### 4.2 후원 — projectId 파싱 ✅ 점검 반영
- **위치:** `DonationRepository.donate()` → `int.parse(projectId)`
- **증상:** `projectId`가 숫자 형식이 아니면 `FormatException`
- **적용:** `int.tryParse(projectId)` 사용, null이면 "잘못된 프로젝트 ID입니다." 예외 throw.

### 4.3 날짜/JSON 파싱
- **위치:** 여러 곳에서 `DateTime.parse(...)`, `json['created_at'] as String` 등
- **증상:** 서버가 다른 형식으로 내려주면 런타임 예외
- **대응:** 가능하면 try-catch, 기본값 또는 null 처리

---

## 5. UI·라이프사이클 (Flutter)

### 5.1 비동기 완료 후 `mounted` 미체크
- **일부 페이지:** async 작업 후 `setState` 또는 `Navigator`/`ScaffoldMessenger` 호출 시 `mounted` 확인이 없을 수 있음
- **증상:** 화면 이미 닫힌 뒤 setState → "setState() called after dispose()" 경고/에러
- **대응:** `if (!mounted) return;` 또는 `if (mounted) setState(...)` 등으로 보호 (이미 많은 곳에서 적용됨)

### 5.2 ModalRoute.of(context)! ✅ 점검 반영
- **위치:** `MyApp` routes `'/friend-invite'` → `ModalRoute.of(context)!.settings.arguments`
- **증상:** 특정 진입 경로에서 `context`가 예상과 다르면 이론적으로 null 가능 (현재는 route builder 내부라 거의 없음)
- **적용:** `ModalRoute.of(context)?.settings.arguments` 사용, `args is String ? args : ''`로 token 안전 추출.

### 5.3 Realtime 구독 타임아웃
- **위치:** 홈 피드 `getProjectsStream()` (Supabase Realtime)
- **증상:** 네트워크 불안정/RLS로 `RealtimeSubscribeException(status: timedOut)` 발생
- **대응:** 이미 “연결이 불안정합니다” + “다시 시도” UI 추가됨. 필요 시 재시도 로직 보강

---

## 6. 이미지·네트워크

### 6.1 Image.network / NetworkImage 실패
- **위치:** 프로젝트 카드, 프로필 아바타, 후원/친구 카드 등
- **증상:** URL 잘못/만료/403 등으로 이미지 로드 실패 시 빨간 에러 박스 (일부는 `errorBuilder`로 플레이스홀더 처리됨)
- **대응:** 모든 `Image.network`/`NetworkImage`에 `errorBuilder` 지정 권장

### 6.2 connection abort / 네트워크 끊김
- **위치:** 모든 Supabase/HTTP 호출
- **증상:** "Software caused connection abort", 타임아웃 등
- **대응:** 프로젝트 삭제 등 중요 동작에는 재시도 로직 이미 일부 적용. 다른 중요 플로우에도 재시도/오류 메시지 적용 권장

---

## 7. 기타·비즈니스 로직

### 7.1 회원 탈퇴
- **위치:** 내 정보 → 회원 탈퇴
- **현재:** 실제 삭제는 미구현. 로그아웃 + 로그인 페이지 이동만 수행 (TODO: Edge Function 'delete-account')
- **대응:** 실제 삭제가 필요하면 Supabase Edge Function 또는 Admin API 연동 필요

### 7.2 친구 코드 중복
- **위치:** `EditProfilePage._resolveFriendCode()` — 20회 재시도 후에도 전부 중복이면 마지막 랜덤 코드로 저장
- **증상:** 극히 드물게 다른 유저와 friend_code 충돌 가능
- **대응:** DB에 `profiles.friend_code` UNIQUE 제약 있으면 insert/update 시 예외로 감지 가능. 재시도 횟수 증가 또는 충돌 시 사용자 안내

### 7.3 검색 기록 (SharedPreferences)
- **위치:** `SearchHistoryHelper` — `getStringList`/`setStringList`
- **증상:** 기기 저장소 권한/풀 디스크 등으로 저장 실패 시 검색 기록만 동작 안 할 수 있음 (앱 크래시는 아님)
- **대응:** 필요 시 `SharedPreferences.getInstance()` 또는 `setStringList` 실패 시 try-catch로 무시 또는 토스트 안내

---

## 8. 체크리스트 요약

| 구분 | 항목 | 심각도 | 비고 |
|------|------|--------|------|
| 환경 | `.env` 없음/로드 실패 | 높음 | 앱 기동 불가 |
| 환경 | 결제 키 `STORE_ID`/`CACAO_CHANNEL_KEY` | 높음 | 후원 결제 불가 |
| Auth | `currentUser!` 로그아웃 후 | 높음 | 크래시 가능 |
| DB | RPC/테이블 미배포 | 높음 | 해당 기능 실패 |
| DB | RLS 정책 | 중간 | 권한 거부 |
| 입력 | `int.parse` 목표 금액 | 중간 | FormatException |
| 입력 | `int.parse` projectId | 중간 | FormatException |
| UI | setState after dispose | 낮음 | 경고/불안정 |
| 네트워크 | Realtime 타임아웃 | 낮음 | 이미 재시도 UI 있음 |
| 이미지 | network 이미지 실패 | 낮음 | errorBuilder 권장 |

---

*문서 기준: 프로젝트 코드베이스 검토 결과. 실제 환경/배포에 따라 추가 이슈가 있을 수 있습니다.*
