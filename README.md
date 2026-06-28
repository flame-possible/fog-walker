# Fog Walker

**걸어서 안개를 걷어내는 산책 수집 앱**

실제 GPS로 걸으면 지도를 덮은 안개가 지나간 경로를 따라 걷히고, 실제 행정동
경계를 기준으로 동네가 해금되며 여권 도장처럼 수집된다. (MVP: 서울)

## 화면

| 화면 | 설명 |
|---|---|
| 지도 | OSM 지도 + 안개 오버레이 + GPS 추적. 걸으면 안개가 걷힌다. |
| 여권(Passport) | 국가별 여권 컬렉션. 한국 → 서울 도장들 → 동네 상세. |
| 업적(Achievement) | 거리·연속일·해금 수 기반 진행도. |
| 내 정보(My Info) | 여권 프로필 + 걸어낸 면적 + This Week 기록. |

## 실행

```bash
flutter pub get
flutter run            # 실기기/에뮬레이터 (실제 GPS 권장)
```

웹으로 빠르게 보려면:

```bash
flutter run -d chrome
```

Supabase Google 로그인을 켜서 실행하려면:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=public-anon-key-from-dashboard \
  --dart-define=SUPABASE_WEB_REDIRECT_URL=http://localhost:8080
```

> 웹/에뮬레이터처럼 GPS가 없는 환경에서는 **디버그 빌드 한정**으로 지도를
> **길게 누르면(long-press)** 그 지점으로 위치가 주입되어 안개 걷힘을 시연할 수
> 있다. (release 빌드에는 포함되지 않음)

## Supabase와 Vercel 웹 배포

앱은 Supabase 환경 변수가 없으면 로컬 모드로 실행되고, 값이 있으면 Google
로그인을 활성화한다.

Vercel 환경 변수:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_WEB_REDIRECT_URL`
- `FLUTTER_VERSION` (선택, 기본 `stable`)

Vercel은 `scripts/vercel-build.sh`를 실행하고 `build/web`을 배포한다. Supabase
Dashboard의 Google provider에는 Vercel production/preview URL과
`fogwalker://login-callback/` redirect URL을 등록한다.

## 테스트

```bash
flutter test           # 도메인/Provider 단위 테스트
flutter analyze        # 정적 분석
```

## 구조

```
lib/
├── domain/      순수 로직 (FogGrid, AreaCalculator, RegionMatcher,
│                WalkStats, Achievement) — 위젯 없이 단위 테스트
├── data/        영속화 (Hive 박스, FogRepository, RegionRepository)
├── models/      Hive 모델 (WalkSession, UserProfile, RegionProgress)
├── providers/   상태관리 (Fog/WalkSession/Collection/Profile)
├── screens/     화면
├── widgets/     공통 위젯 (StampWidget, PassportCard, FogPainter)
└── theme/       디자인 토큰
```

핵심 원칙: **저장하는 것은 사실(방문 셀·끝난 산책·해금 지역)뿐, 나머지(면적·
클리어%·통계·업적 진행도)는 거기서 파생한다.**

## 데이터 재생성 (서울 행정동)

`assets/data/seoul_dong.geojson`은 공개 행정동 경계 데이터를 가공한 것이다.
재생성하려면:

```bash
# 1) 원본 다운로드 (raqoon886/Local_HangJeongDong)
curl -sL "https://raw.githubusercontent.com/raqoon886/Local_HangJeongDong/master/hangjeongdong_서울특별시.geojson" -o tool/seoul_raw.geojson
# 2) 가공 (서울 추출 + 폴리곤 단순화)
dart run tool/build_seoul_geojson.dart
```

## 확장 방향

현재 앱은 서울 데이터를 기본 번들로 포함한다. 전세계 확장은 앱 설치 파일에 모든
경계를 넣는 방식이 아니라, 국가/지역/도시 단위 데이터팩을 선택 다운로드해 로컬에
캐시하는 방식으로 설계한다.

## 기술 스택

flutter_map (OSM) · geolocator · hive · provider · latlong2 · google_fonts
