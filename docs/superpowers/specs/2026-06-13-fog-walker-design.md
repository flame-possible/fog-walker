# Fog Walker — 설계 문서

> 작성일: 2026-06-13
> 상태: 승인됨 (구현 계획 대기)

## 1. 한 줄 소개

**"걸어서 안개를 걷어내는 산책 수집 앱"**

실제 GPS로 걸으면 지도를 덮은 안개가 내가 지나간 경로를 따라 부드럽게 걷히고,
실제 행정동 경계를 기준으로 동네가 해금되며 여권 도장처럼 수집된다.

## 2. 핵심 컨셉

- **포그 오브 워(Fog of War)**: 걸은 경로 주변만 안개가 걷힘. 안 가본 곳은 안개로 덮여 있음.
- **여권/도장 메타포**: 해금한 동네가 여권 도장으로 수집됨. 국가 → 도시 → 동네 계층.
- **실제 GPS 추적**: 기기의 실제 위치로 안개가 걷힘. 진짜 걸어다니는 앱.
- **실제 행정구역**: 한국 실제 행정동 경계 기준으로 해금/진행도 계산. (MVP: 서울)

## 3. 사용자 결정 사항 (확정)

| 항목 | 결정 |
|---|---|
| 범위 | 동작하는 MVP 전체 (5개 화면 + GPS + 안개 + 로컬 저장) |
| 안개 걷힘 방식 | 실제 GPS 추적 |
| 지도 SDK | flutter_map (OpenStreetMap) |
| 안개 렌더링 | 원(circle) 누적 마스크 — `BlendMode.clear`로 부드럽게 지우고, 면적은 그리드 셀로 별도 측정 (접근 A) |
| 상태관리 | provider |
| 로컬 DB | Hive |
| 행정구역 데이터 | 실제 행정동 GeoJSON, **서울만** 시작 (전국은 추후 확장) |

## 4. 아키텍처

```
┌─────────────────────────────────────────────┐
│  UI Layer (5 screens + 1 detail)            │
│  Map · Passport · CityStamps · Detail        │
│  Achievement · MyInfo                         │
├─────────────────────────────────────────────┤
│  State (Provider/ChangeNotifier)             │
│  FogProvider · WalkSessionProvider           │
│  CollectionProvider                           │
├─────────────────────────────────────────────┤
│  Domain (순수 Dart, 테스트 대상)             │
│  FogGrid · AreaCalculator · RegionMatcher     │
├─────────────────────────────────────────────┤
│  Data (영속화)                               │
│  Hive — 방문 셀, 산책 기록, 컬렉션, 프로필   │
├─────────────────────────────────────────────┤
│  Services                                    │
│  LocationService (geolocator)                │
│  flutter_map (지도 렌더링)                    │
└─────────────────────────────────────────────┘
```

### 기술 스택

| 분류 | 패키지 | 이유 |
|---|---|---|
| 지도 | `flutter_map` | OSM 기반. 안개 오버레이를 `OverlayLayer`로 자유롭게 얹음 |
| 위치 | `geolocator` | 실제 GPS 추적 + 권한 처리 표준 |
| 로컬 저장 | `hive` / `hive_flutter` | 방문 셀이 수천 개로 늘어남 → 가볍고 빠른 key-value DB |
| 상태관리 | `provider` | MVP 규모에 적정 |
| 좌표/거리 | `latlong2` | 위경도 거리 계산 (flutter_map 동반) |

### 핵심 설계 원칙

안개 로직(`FogGrid`, `AreaCalculator`, `RegionMatcher`)을 Flutter UI에서 완전히 분리.
순수 Dart 클래스로 만들어 위젯 없이 단위 테스트 가능하게 한다.
저장하는 것은 **사실(fact)** — 방문 셀, 끝난 산책, 해금 지역. 나머지는 거기서 파생.

## 5. 안개 엔진 (핵심)

### 두 개의 분리된 데이터

**1) 측정용 — FogGrid (방문 셀 집합)**
- 세계를 위경도 격자로 분할. 각 셀은 정수 좌표 `(gx, gy)`로 식별.
- 셀 크기는 **도(degree) 단위로 고정** → 줌 무관.

```dart
// 셀 크기: 약 50m. 위도 1도 ≈ 111km
const double kCellDeg = 0.00045; // ≈ 50m

(int, int) cellOf(LatLng p) =>
    ((p.longitude / kCellDeg).floor(), (p.latitude / kCellDeg).floor());
```

- 방문 셀은 `Set<(int,int)>`로 저장.
- GPS 점이 들어오면 그 점 주변 **반경 R = 30m 안의 셀들을 모두 방문 처리** (원으로 지우는 시각과 일치).

**2) 시각용 — 원 좌표 (걸은 경로 점들)**
- 화면에 그릴 때 현재 viewport 안의 점들만 `BlendMode.clear` 원으로 렌더링.
- 가장자리는 `MaskFilter.blur`로 부드럽게.
- 영속화는 "방문 셀"만 → 재시작 시 셀 중심마다 원 복원해서 그림. (원 점 전부 저장 불필요)

### 면적 계산 (줌 무관, 안정적)

```dart
double areaKm2(Set<(int,int)> cells) {
  // 평균 위도 기준 셀 면적 × 셀 개수 (위도에 따른 경도 거리 축소 보정)
  return cells.length * cellAreaKm2;
}
```

- **지역별 클리어 %** = `boundary 안 visited 셀 수 / boundary 전체 셀 수`
  → 스크린샷 "58.02%", "38%"가 여기서 나옴.
- **누적 면적** = `visitedCells.length × cellArea` → "1224.8 km²"

### "걸으면 안개가 걷힌다" 흐름

```
GPS 위치 업데이트 (geolocator stream)
   ↓
FogProvider.onLocation(LatLng)
   ↓
반경 30m 안의 셀들을 visitedCells에 추가
   ↓ (새 셀이 추가됐으면)
1. Hive에 저장 (debounce: 5초마다 일괄)
2. notifyListeners() → 지도 다시 그림
3. 면적/% 재계산 → 통계 화면 갱신
```

## 6. 데이터 모델 (Hive Box 4개)

**Box 1: `visitedCells`** — 안개 엔진 핵심
```
key: "gx,gy" 문자열, value: 최초 방문 timestamp(int)
```

**Box 2: `walkSessions`** — 산책 기록
```dart
@HiveType(typeId: 0)
class WalkSession {
  String id;
  DateTime startedAt;
  DateTime endedAt;
  double distanceKm;      // 이동 거리
  double clearedKm2;      // 이번 산책으로 걷어낸 면적
  int newCellsCount;      // 새로 발견한 셀 수
  List<String> regionIds; // 지나간 지역들
  WalkMode mode;          // walk / bike / swim / hike (업적용)
}
```

**Box 3: `regions`** — 지역/도시 메타
```dart
@HiveType(typeId: 1)
class Region {
  String id;              // "hannam-dong"
  String nameKo;          // "한남동"
  String nameEn;          // "Hannam-dong"
  String cityId;          // "seoul"
  String countryId;       // "kr"
  String about;
  List<List<double>> boundary; // 폴리곤 (셀 포함 판정 + 클리어% 계산)
  DateTime? unlockedAt;   // 해금일 (null = 미해금)
  int visitCount;
  // clearPercent는 실시간 계산 (저장 안 함)
}
```

**Box 4: `userProfile`** — My Info 여권
```dart
@HiveType(typeId: 2)
class UserProfile {
  String name;            // "HONG GILDONG"
  String passportId;      // "FW-2024-0927"
  int level;              // 12
  String tier;            // "Wanderer"
  int stampCount;
}
```

### 파생 값 (저장 안 함 — 중복 저장은 버그의 원천)

- 클리어 % = boundary 안 visited 셀 / boundary 전체 셀
- 누적 면적 = visitedCells.length × cellArea
- 총 거리, 연속 산책일, 가장 긴 산책 = walkSessions 집계
- 업적 진행도 = 집계값으로 실시간 판정

## 7. 행정구역 데이터 파이프라인

### 소스
- **출처**: GitHub [vuski/admdongkor](https://github.com/vuski/admdongkor) (전국 행정동 경계)
- **백업**: [raqoon886/Local_HangJeongDong](https://github.com/raqoon886/Local_HangJeongDong)
- **형식**: 행정동별 폴리곤(MultiPolygon) GeoJSON

### 가공 (빌드 타임)
원본은 수십~수백 MB → 통째 번들 불가. 다음 단계로 가공:
1. **지역 한정** — 서울 행정동만 추출 (MVP)
2. **폴리곤 단순화** — Douglas-Peucker로 좌표 점 수 축소 (산책 앱에 충분한 정밀도 유지)
3. **자산 번들** — `assets/seoul_dong.geojson` → 첫 실행 시 Hive `regions` Box로 로드

### 셀 ↔ 행정동 매핑 (성능)
- 각 행정동 **바운딩 박스**로 1차 필터
- 박스에 걸리는 동만 정밀 point-in-polygon 검사
- **셀→regionId 캐시**로 재계산 방지

## 8. 화면 & 네비게이션

```
BottomNavigationBar (4 tabs)
├─ Tab 1: 🗺️  MapScreen          [Frame 277]  안개 지도 + GPS + 발자국 마커
├─ Tab 2: 📷  PassportScreen      [Frame 220]  국가별 여권 컬렉션 그리드
│              └─ CityStampsScreen [Frame 279]  국가 → 도시 도장들
│                   └─ RegionDetailScreen [Frame 262]  도장 → 동네 상세
├─ Tab 3: 🎖️  AchievementScreen   [Frame 281]  업적 진행도 리스트
└─ Tab 4: ⚙️  MyInfoScreen        [Frame 221]  여권 프로필 + 통계 + 기록
```

> 4번째 탭 아이콘은 톱니처럼 보이나 내용은 "My Information". 별도 설정 화면은 MVP 제외 (YAGNI).

### 화면별 핵심

**① MapScreen** (가장 복잡)
- flutter_map (OSM) + 안개 OverlayLayer + 발자국 마커
- 상단 좌측: 현재 지역 + 클리어% 칩 ("인사동 58.02%")
- 우측 하단: 내 위치 이동 FAB
- GPS 추적 on/off, 실시간 안개 걷힘

**② PassportScreen**
- 대륙 탭 (전체/아시아/유럽/북미/남미/오세아니아)
- 국가별 여권 카드 그리드, 진행도 "06/200" = 해금 도시 / 전체
- MVP는 한국만 데이터, 나머지 잠금 카드

**③ CityStampsScreen**
- 상단: "South Korea" + 도시 드롭다운
- 수집 도장들이 흩뿌려진 레이아웃
- 미해금 흐리게 / 해금 선명하게 → 탭 시 RegionDetail

**④ RegionDetailScreen**
- 큰 도장 + 한글/영문명
- 3개 통계: 해금일 / 방문 횟수 / 안개 클리어%
- About 텍스트
- Location: 그 지역만 보여주는 미니 지도 (경계 + 걷힌 부분)
- Visits: 그 지역 방문 기록 리스트

**⑤ AchievementScreen**
- 탭: 전체/진행중/완료
- 카드: 아이콘 + 제목 + 설명 + 진행바 + "90/100"
- walkSessions/visitedCells 집계로 실시간 판정

**⑥ MyInfoScreen**
- 여권 카드 (사진/이름/ID/레벨/티어)
- Stats: 걸어낸 안개 큰 숫자
- Records: This Week 카드 + 상세 통계 리스트
- "전체 기록 보기" → walkSessions 리스트

### 디자인 토큰 (스크린샷에서 추출)
- 메인 컬러: 도장 빨강 `#C0392B` 계열, 텍스트 거의 블랙
- 여권 그라데이션: 파스텔 홀로그램 (My Info 카드 배경)
- 폰트: 제목 세리프(여권 느낌), 본문 산세리프
- 도장: 원형 테두리 + 별 3개 + 도시 일러스트

## 9. 상태관리 (Provider 3개)

**① FogProvider** — 안개의 단일 진실 공급원
```dart
class FogProvider extends ChangeNotifier {
  final Set<(int,int)> _visitedCells;
  final FogRepository _repo;
  Set<(int,int)> get visitedCells;
  double get totalAreaKm2;
  void onLocation(LatLng p);
  double clearPercentOf(Region r);
  // 5초 debounce로 Hive 저장
}
```
사용처: MapScreen, RegionDetail, MyInfo

**② WalkSessionProvider** — 산책 세션 생명주기
```dart
class WalkSessionProvider extends ChangeNotifier {
  WalkSession? _active;
  bool get isWalking;
  void start();
  void stop();
  // 진행 중 distance/clearedKm2 누적, 집계 통계
}
```
사용처: MapScreen, MyInfo, RegionDetail

**③ CollectionProvider** — 지역/도장/업적
```dart
class CollectionProvider extends ChangeNotifier {
  List<Region> get regions;
  List<Region> get unlockedRegions;
  void checkUnlocks(Set<(int,int)> visited);
  List<Achievement> get achievements;
}
```
사용처: Passport, CityStamps, RegionDetail, Achievement

### 데이터 흐름 (걸을 때)
```
LocationService (geolocator stream)
        │ LatLng
        ▼
   FogProvider.onLocation(p)
        ├─ 반경 30m 셀들 visitedCells에 추가
        ├─ 새 셀 있으면:
        │     ├─ WalkSessionProvider에 거리/면적 누적
        │     ├─ CollectionProvider.checkUnlocks() → 새 동 해금?
        │     └─ Hive 저장 (debounce 5초)
        └─ notifyListeners() → MapScreen 안개 다시 그림 + 통계 갱신
```

### Provider 간 결합
FogProvider는 자기 셀만 안다. 해금 판정은 CollectionProvider가 visited 셋을
입력받아 독립 수행하는 **단방향 흐름**. 조율은 MapScreen 또는 ProxyProvider로.

### 부팅 시퀀스
```
main()
 ├─ Hive 초기화 + Box 열기
 ├─ 첫 실행이면: assets/seoul_dong.geojson → regions Box 시드
 ├─ visitedCells / sessions / profile 로드
 ├─ 위치 권한 요청
 └─ Provider 주입 후 runApp
```

## 10. 에러 처리 · 권한

| 상황 | 처리 |
|---|---|
| 권한 미요청 | 첫 진입 시 권한 요청 |
| 권한 거부 | 지도는 보이되 "위치 권한 필요" 배너 + 설정 이동 |
| 위치 서비스 OFF | "위치 서비스를 켜주세요" 안내 |
| 정확도 낮음 | accuracy > 50m 신호 무시 |
| 영구 거부 | `Geolocator.openAppSettings()` 유도 |

### GPS 노이즈 방어
- 정확도 필터: `accuracy > 50m` 점 버림
- 거리 필터: `distanceFilter: 10m`
- 순간이동 방어: 비현실적으로 먼 점(1초에 1km 등) 무시

### 방어적 설계
- Hive 저장 실패해도 메모리 캐시 유지 → 다음 debounce 재시도
- GeoJSON 파싱 실패 시 빈 목록으로라도 앱 구동
- 빈 상태(Empty State): 기록 0개 / 해금 0개 시 안내 문구

## 11. 테스트 전략 (TDD)

### 순수 로직 단위 테스트 (핵심)
```
test/
├─ fog_grid_test.dart       — cellOf 일관성, 반경 30m 셀 집합, 재방문 중복 없음
├─ area_calculator_test.dart — 셀 수 → 정확한 km², 위도 보정
├─ region_matcher_test.dart  — point-in-polygon, 바운딩 박스 필터, 캐시
└─ achievement_test.dart     — 진행도 집계 (1000km 중 900km → 90%)
```

### Provider 단위 테스트
- FogProvider.onLocation → 셀 증가, notifyListeners
- WalkSessionProvider start/stop 생명주기
- CollectionProvider.checkUnlocks 해금 판정

### 위젯 테스트 (핵심 화면만)
- MapScreen: 권한 거부 시 배너
- 안개 페인터: 방문 셀 있을 때 구멍 렌더

### 수동 검증
- 시뮬레이터 mock location으로 경로 주입 → 안개 걷힘
- 실기기 실제 산책 테스트

## 12. 검증 가능한 성공 기준

1. mock 위치로 직선 이동 → 안개가 경로 따라 걷힘
2. 한남동 경계 안 걸으면 → 한남동 해금 + % 증가
3. 면적이 줌 레벨 바꿔도 일정
4. 앱 재시작 후 걷힌 안개 복원
5. 단위 테스트 전부 통과

## 13. MVP 범위 밖 (명시적 제외)

- 전국 행정구역 (서울만)
- 한국 외 국가 데이터 (잠금 카드만 표시)
- 별도 설정 화면
- 소셜/공유/계정 (전부 로컬)
- 카메라/사진 첨부 (탭 아이콘은 Passport로 사용)
