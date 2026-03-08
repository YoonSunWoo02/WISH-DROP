# Wish Drop 요구기능서 (요구사항 명세서)

## 1. 프로젝트 개요

**Wish Drop(위시드롭)**은 사용자가 원하는 선물(위시)을 등록하고, 친구들이 함께 금액을 모아 후원할 수 있는 크라우드펀딩형 선물 플랫폼이다.

- **목적**: 생일·졸업 등 목표 금액을 정해 위시를 만들고, 친구들이 소액으로 참여해 목표 달성 시 선물 수령
- **기술 스택**: Flutter (웹·모바일), Supabase (Auth, DB, Storage), PortOne 결제(웹/앱), Kakao 공유
- **플랫폼**: 웹(kIsWeb → GoRouter 기반), 모바일(Android/iOS → MaterialApp + 명시 라우트)

---

## 2. 사용자 / 역할

| 역할 | 설명 |
|------|------|
| **일반 사용자** | 로그인 후 위시 생성·조회·후원, 친구 추가·초대, 프로필·설정 관리 |
| **비로그인 사용자** | 로그인·회원가입, 친구 초대 링크 접속(/friend-invite), 위시 상세(/project/:id) 조회 가능(일부 화면 제한) |

별도 관리자/역할 구분 없음. 모든 기능은 로그인한 단일 사용자 역할 기준.

---

## 3. 기능 요구사항

### 3.1 인증 (Auth)

| 번호 | 요구사항 | 비고 |
|------|----------|------|
| A-1 | 이메일·비밀번호로 회원가입 | Supabase Auth signUp |
| A-2 | 이메일·비밀번호로 로그인 | Supabase Auth signInWithPassword |
| A-3 | 로그아웃 | signOut 후 웹은 /login, 모바일은 LoginPage |
| A-4 | 로그인 상태에 따른 진입점 분기 | 비로그인 → 로그인/회원가입 화면, 로그인 → 홈(웹: /, 모바일: HomePage) |
| A-5 | 웹 로그인 후 redirect 쿼리 지원 | `/login?redirect=/path` 시 로그인 성공 후 해당 경로로 이동 |

### 3.2 위시(프로젝트) (Wish)

| 번호 | 요구사항 | 비고 |
|------|----------|------|
| W-1 | 위시 목록 조회(홈 피드) | 활성(status=active) 위시만, 최신순 |
| W-2 | 위시 상세 조회 | ID 기반 단건 조회, 생성자 프로필·후원 목록 표시 |
| W-3 | 위시 생성 | 제목, 설명, 목표 금액, 종료일, 썸네일(선택), 익명/메시지 허용 옵션, wish_images 스토리지 업로드 |
| W-4 | 위시 상태 관리 | active / completed; 목표 금액 달성 또는 종료일 경과 시 completed 전환(앱 기동 시·상세 갱신 시 check_and_complete_projects 호출) |
| W-5 | 내 위시 목록 조회 | creator_id=현재 사용자, 진행 중/종료 구분 가능 |
| W-6 | 위시 공유 | URL 공유(INVITE_LINK_BASE_URL/project/:id 또는 wishdrop://project/:id), share_plus·카카오 공유, share_count RPC 증가 |

### 3.3 친구 (Friend)

| 번호 | 요구사항 | 비고 |
|------|----------|------|
| F-1 | 친구 목록 조회 | friendships(status=accepted) + profiles, 활성 위시 수 표시 |
| F-2 | 친구 검색 | 닉네임·친구코드(friend_code) 검색(profiles), 본인 제외 |
| F-3 | 친구 코드로 사용자 찾기 | friend_code 일치 한 명 조회 |
| F-4 | 친구 요청 보내기 | friendships insert (requester_id, receiver_id, status=pending), 중복 시 안내 |
| F-5 | 받은 친구 요청 목록 | receiver_id=나, status=pending |
| F-6 | 보낸 친구 요청 목록 | requester_id=나, status=pending |
| F-7 | 친구 요청 수락/거절 | 수락 시 status=accepted, 거절 시 삭제 |
| F-8 | 보낸 요청 취소 | 해당 friendships 행 삭제 |
| F-9 | 친구 삭제 | friendships 행 삭제 |
| F-10 | 친구 초대 링크 생성 | invite_tokens 조회/생성, 유저당 사용 중(used_at IS NULL) 토큰 1개 |
| F-11 | 초대 링크로 진입 | /friend-invite?token=xxx, 토큰으로 초대자 프로필 표시 후 친구 요청 시 used_at 갱신 |
| F-12 | 초대 URL 형태 | INVITE_LINK_BASE_URL 설정 시 https 링크, 미설정 시 wishdrop://friend?token=xxx |
| F-13 | 웹 초대 시 앱/웹 선택 | 앱 설치하기(스토어), 앱에서 열기(딥링크), 또는 웹으로 계속 진행 |

### 3.4 후원 (Donation)

| 번호 | 요구사항 | 비고 |
|------|----------|------|
| D-1 | 위시에 후원하기 | 로그인 필수, 금액·메시지(선택)·익명 여부 입력 |
| D-2 | 한 위시당 1인 1회 후원 | donations (user_id, project_id) UNIQUE, 이미 후원 시 안내 |
| D-3 | 결제 연동 | 모바일: PortOne(portone_flutter_v2), 웹: PortOne 웹 결제 후 payment_id로 검증 |
| D-4 | 후원 처리 흐름 | 결제 성공 → insertDonationIfNew(payment_id) → increment_project_amount RPC → 성공 화면 |
| D-5 | payment_id 중복 처리 | 동일 payment_id 재요청 시 재삽입 없이 성공 화면만 표시 |
| D-6 | 내 후원 내역 조회 | user_id 기준, 프로젝트 제목·생성자 닉네임·프사 포함(월별 그룹 등) |
| D-7 | 위시별 후원 목록 조회 | 프로젝트 상세에서 참여자(닉네임·프사) 표시, 익명 시 마스킹 |

### 3.5 프로필·마이페이지 (Profile)

| 번호 | 요구사항 | 비고 |
|------|----------|------|
| P-1 | 내 프로필 조회 | profiles: nickname, friend_code, avatar_url |
| P-2 | 프로필 수정 | 닉네임 변경, update_nickname RPC로 friend_code 갱신(닉네임#숫자), 프로필 이미지 업로드(avatars 버킷 등) |
| P-3 | 마이페이지 탭 | 보낸 마음(후원 내역), 만든 위시 목록, 성공한 위시 수 표시 |
| P-4 | 내 위시 리스트 전용 화면 | MyWishListPage(진행 중/종료 위시) |
| P-5 | 활동 타임라인 | activity_timeline_page(후원·위시 관련 활동) |

### 3.6 설정 (Settings)

| 번호 | 요구사항 | 비고 |
|------|----------|------|
| S-1 | 설정 화면 | 계정(이메일) 표시, 알림 설정 진입, 로그아웃 |
| S-2 | 알림 설정 | 로컬(SharedPreferences): 후원 받음, 위시 달성, 친구 새 위시 on/off |

### 3.7 기타 화면

| 번호 | 요구사항 | 비고 |
|------|----------|------|
| O-1 | 지원/고객센터 | support_page |
| O-2 | 친구의 위시 목록 | friend_wish_page(특정 친구의 위시 목록) |

---

## 4. 비기능 요구사항

| 번호 | 구분 | 요구사항 |
|------|------|----------|
| NF-1 | 플랫폼 | 웹(브라우저) 및 모바일(Android/iOS) 지원 |
| NF-2 | 웹 라우팅 | GoRouter 기반 URL 라우팅(/, /login, /signup, /friend, /my-info, /settings, /create, /project/:id, /donation, /donation-success, /friend-invite, /edit-profile 등) |
| NF-3 | 웹 레이아웃 | 1024px 이상 시 사이드바, 미만 시 하단 네비게이션; 헤더(로고, 검색 placeholder, 알림, 프로필) |
| NF-4 | 반응형 | ShellWeb: showSidebar = width >= 1024, 하단 네비 4개(홈/친구/설정/마이페이지) |
| NF-5 | 인증 리다이렉트 | 비로그인 시 로그인 필요 경로 접근 → /login(웹) 또는 LoginPage(모바일); 예외: /login, /signup, /friend-invite, /project/:id, /edit-profile, /notification-settings |
| NF-6 | 폰트 | 웹: Google Fonts(Noto Sans KR, Plus Jakarta Sans) |
| NF-7 | 환경 설정 | .env: SUPABASE_URL, SUPABASE_ANON_KEY, KAKAO_NATIVE_APP_KEY, INVITE_LINK_BASE_URL, (선택) APP_STORE_URL, PLAY_STORE_URL, PortOne 관련 키 |

---

## 5. 데이터·연동 요구사항

### 5.1 Supabase 테이블

| 테이블 | 용도 |
|--------|------|
| **profiles** | id(auth.users 연동), nickname, friend_code, avatar_url, created_at |
| **projects** | id, creator_id, title, description, thumbnail_url, target_amount, current_amount, status(active/completed/deleted), end_date, allow_anonymous, allow_messages, welcome_message, share_count, created_at |
| **donations** | id, project_id, user_id, amount, message, is_anonymous, payment_id(유니크), created_at; (user_id, project_id) UNIQUE |
| **friendships** | id, requester_id, receiver_id, status(pending/accepted), created_at; (LEAST,GREATEST) UNIQUE로 1:1 관계 보장 |
| **invite_tokens** | token, user_id, used_at; user_id당 used_at IS NULL 1건 유니크 |

### 5.2 Supabase RPC

| RPC | 용도 |
|-----|------|
| check_and_complete_projects | 만료/목표 달성 위시 status → completed 일괄 갱신 |
| increment_project_amount(p_project_id, p_amount) | current_amount 원자적 증가 |
| update_nickname(new_nickname) | 닉네임·friend_code 갱신(닉네임#숫자 유일성 보장) |
| increment_project_share_count(p_project_id) | 공유 횟수 증가 |

### 5.3 Storage

| 버킷 | 용도 |
|------|------|
| wish_images | 위시 썸네일 업로드 (경로: {user_id}/{filename}) |
| (avatars) | 프로필 이미지(edit_profile_page에서 avatar_url 업로드 시 사용) |

### 5.4 외부 연동

| 연동 | 용도 |
|------|------|
| Supabase Auth | 로그인·회원가입·로그아웃·세션 |
| PortOne | 모바일 결제(portone_flutter_v2), 웹 결제(portone_web_service); 결제 검증·웹훅(portone-webhook) |
| Kakao SDK | 카카오 공유 템플릿(모바일만, kIsWeb이 아닐 때 초기화) |
| share_plus / url_launcher | 시스템 공유·외부 링크 |
| app_links | 딥링크(친구 초대, 결제 리다이렉트 등) |

---

## 6. 주요 화면·라우팅 요약

| 구분 | 웹(GoRouter) | 모바일 |
|------|----------------|--------|
| 진입 | main.dart → kIsWeb ? AppWeb : MyApp |
| 홈 | / → HomePageWeb | HomePage |
| 로그인/회원가입 | /login, /signup | LoginPage, SignUpPage(라우트 이름으로 이동) |
| 친구 | /friend → FriendPage | (홈 등에서 진입) |
| 마이페이지 | /my-info → MyInfoPageWeb | MyInfoPage |
| 설정 | /settings → SettingsPageWeb | (설정 메뉴) |
| 위시 만들기 | /create → CreateWishPage | CreateWishPage |
| 위시 상세 | /project/:id → ProjectDetailPageWeb | ProjectDetailPage |
| 후원 | /donation(extra: ProjectModel) → DonationPageWeb | DonationInputPage 등 |
| 후원 성공 | /donation-success?projectId= | DonationSuccessPage(Web/공통) |
| 친구 초대 | /friend-invite?token= | FriendInvitePage(token) |
| 프로필 수정 | /edit-profile(extra) | EditProfilePage |
| 알림 설정 | 설정 내 Navigator.push → NotificationSettingsPage | 동일 |

---

*문서 버전: 1.0 | 프로젝트 분석 기준: wish_drop 코드베이스*
