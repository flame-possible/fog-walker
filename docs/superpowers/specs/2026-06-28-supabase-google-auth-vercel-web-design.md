# Fog Walker — Supabase Google Auth and Vercel Web Design

> 작성일: 2026-06-28
> 상태: 승인된 방향 정리, 구현 계획 대기

## 1. 목표

Fog Walker에 Google 로그인을 추가하되 인증의 단일 진실 공급원은 Supabase로 둔다.
모바일 앱과 Flutter web 빌드는 같은 Supabase 프로젝트를 사용한다. 웹 배포는
Vercel에 연결해 수정사항을 빠르게 확인할 수 있게 한다.

## 2. 확정 방향

- 인증: Supabase Auth + Google OAuth.
- 웹 배포: Vercel에서 `flutter build web` 결과물을 정적 배포.
- 데이터: 현재 MVP 데이터는 계속 Hive 로컬 저장을 유지.
- 계정 연동: 로그인한 Supabase 사용자 정보를 로컬 `UserProfile`에 반영.
- 향후 확장: 산책/안개/도장 동기화는 별도 단계에서 Supabase DB로 확장.

Firebase Auth는 사용하지 않는다. Supabase Auth와 Firebase Auth를 함께 쓰면 계정
상태와 토큰 체계가 이중화되어 향후 동기화가 복잡해지기 때문이다.

## 3. 사용자 경험

로그인하지 않아도 앱은 계속 사용할 수 있다. Fog Walker는 걷기 앱이므로 GPS,
지도, 안개 걷힘, 도장 수집은 오프라인/로컬 우선으로 유지한다.

My Information 화면에 계정 영역을 추가한다.

- 로그아웃 상태: `Google로 로그인` 버튼 표시.
- 로그인 중: 진행 상태 표시.
- 로그인 성공: 이름, 이메일, 프로필 사진 URL을 프로필에 반영.
- 로그인 상태: 계정 이메일과 `로그아웃` 버튼 표시.
- 로그인 실패/취소: 로컬 프로필은 유지하고 짧은 안내 메시지 표시.

## 4. 앱 구조

새로운 인증 계층을 추가한다.

```
lib/
├── services/auth_service.dart       Supabase 초기화와 Google OAuth 호출
├── providers/auth_provider.dart     로그인 상태/로딩/에러 상태 관리
├── models/user_profile.dart         Supabase 사용자 필드 추가
└── screens/my_info_screen.dart      로그인/로그아웃 UI 연결
```

`main.dart`는 Hive 초기화 후 Supabase 초기화를 수행한다. Supabase URL과 anon key는
빌드 환경 변수로 주입한다.

## 5. 환경 변수와 비밀값

클라이언트에 들어가는 Supabase anon key는 공개 가능한 키지만, 저장소에 직접
하드코딩하지 않는다.

로컬 실행:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

Vercel 배포:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Vercel의 build command에 `--dart-define`을 포함한다.

## 6. Supabase 설정

Supabase Dashboard에서 다음을 설정한다.

- Authentication > Providers > Google 활성화.
- Google Cloud OAuth client ID/secret 등록.
- Site URL: Vercel production URL.
- Redirect URLs:
  - Vercel production URL.
  - Vercel preview URL 패턴.
  - 로컬 개발 URL.
  - 모바일 deep link URL.

모바일 deep link는 구현 단계에서 앱 scheme을 하나 정해 Android/iOS에 등록한다.
예: `fogwalker://login-callback/`

## 7. Vercel 설정

Vercel은 Flutter web 정적 결과물을 배포한다.

권장 설정:

- Framework preset: Other.
- Install command: repo의 Vercel용 Flutter SDK 설치 스크립트 사용.
- Build command:
  `flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY`
- Output directory: `build/web`.

초기 구현에서는 Vercel용 Flutter SDK 설치 스크립트와 `vercel.json`을 추가해
GitHub 연동 후 바로 빌드 설정을 재사용할 수 있게 한다.

## 8. UserProfile 확장

`UserProfile`에 다음 필드를 추가한다.

- `authProvider`: `local` 또는 `supabaseGoogle`.
- `supabaseUserId`: Supabase user id.
- `email`: 사용자 이메일.
- `photoUrl`: Google 프로필 사진 URL.
- `displayName`: Google 표시 이름.

기존 Hive type id와 필드 번호를 유지하고 새 필드만 뒤에 추가한다. 기존 사용자의
로컬 프로필은 마이그레이션 없이 기본값으로 읽히도록 optional/default 처리한다.

## 9. 데이터 동기화 범위

이번 단계에서는 인증과 로컬 프로필 연동까지만 구현한다.

하지 않는 것:

- 방문 셀 Supabase 동기화.
- 산책 기록 Supabase 동기화.
- 여러 기기 병합 규칙.
- Supabase DB 스키마 생성.
- 데이터팩 다운로드 서버 구현.

로그인 사용자는 일단 “프로필이 Google 계정과 연결된 상태”가 된다. 실제 진행도
동기화는 다음 스펙에서 다룬다.

## 10. 테스트 전략

- `AuthProvider`는 fake `AuthService`로 성공/취소/실패 흐름을 테스트한다.
- `ProfileProvider`는 Supabase 사용자 정보 반영 시 기존 도장/레벨/티어가 유지되는지 테스트한다.
- `UserProfile`은 기존 Hive 필드와 새 필드가 함께 동작하는지 테스트한다.
- `MyInfoScreen`은 최소한 로그인/로그아웃 상태별 텍스트가 보이는지 위젯 테스트로 확인한다.

실제 Google OAuth는 Supabase/Google 콘솔 설정과 브라우저/OS 콜백이 필요하므로
자동 단위 테스트 대신 수동 검증 체크리스트로 다룬다.

## 11. 성공 기준

- 앱은 Supabase 환경 변수가 없어도 로컬 모드로 실행된다.
- 환경 변수가 있으면 Supabase 초기화가 되고 Google 로그인 버튼이 동작한다.
- 로그인 성공 시 My Information의 이름/이메일/프로필 상태가 갱신된다.
- 로그아웃해도 기존 로컬 산책/안개/도장 데이터는 삭제되지 않는다.
- `flutter test`와 `flutter analyze`가 통과한다.
- `flutter build web --release`가 성공한다.
- Vercel에 필요한 환경 변수/빌드 설정이 문서화되어 있다.
