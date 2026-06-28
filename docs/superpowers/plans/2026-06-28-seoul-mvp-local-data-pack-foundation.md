# Seoul MVP Local Data Pack Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the Seoul MVP quality fixes while preparing region metadata for future local data packs.

**Architecture:** Keep the app offline-first with the current bundled Seoul asset. Extend `RegionMeta` and generated Seoul data with hierarchy fields, fix walk session distance tracking so it is independent of newly cleared cells, and remove user-visible placeholders that can be derived from current data.

**Tech Stack:** Flutter, Dart, Provider, Hive, flutter_map, latlong2, `flutter_test`.

---

## File Structure

- `lib/data/region_meta.dart`: add hierarchy enums/fields while preserving current JSON compatibility.
- `lib/data/region_repository.dart`: preserve loaded hierarchy fields when adding About text, and expose country count.
- `tool/build_seoul_geojson.dart`: generate Seoul hierarchy fields for future data pack compatibility.
- `lib/screens/map_screen.dart`: call walk distance tracking on every accepted location, not only when fresh fog cells appear.
- `lib/providers/walk_session_provider.dart`: keep `onMove` as the single session accumulation API.
- `lib/screens/my_info_screen.dart`: replace hard-coded/placeholder values with derived values and a better favorite fallback.
- `lib/widgets/passport_card.dart`: replace the generic person icon with a deterministic passport-style avatar.
- `docs/superpowers/specs/2026-06-13-fog-walker-design.md`: fix frame mapping inconsistencies.
- `test/region_meta_test.dart`: verify legacy and hierarchy JSON parsing.
- `test/walk_session_provider_test.dart`: verify distance increments even when no new cells are discovered.

---

### Task 1: Region Hierarchy Metadata

**Files:**
- Modify: `lib/data/region_meta.dart`
- Modify: `lib/data/region_repository.dart`
- Modify: `tool/build_seoul_geojson.dart`
- Create: `test/region_meta_test.dart`

- [ ] **Step 1: Write failing tests for hierarchy parsing**

Add `test/region_meta_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/data/region_meta.dart';

void main() {
  group('RegionMeta hierarchy fields', () {
    test('legacy Seoul JSON defaults to neighborhood hierarchy', () {
      final meta = RegionMeta.fromJson({
        'id': '1111053000',
        'nameKo': '사직동',
        'nameEn': 'Sajik-dong',
        'cityId': 'seoul',
        'districtKo': '종로구',
        'districtEn': 'Jongno-gu',
        'boundary': [
          [126.97, 37.57],
          [126.98, 37.57],
          [126.98, 37.58],
          [126.97, 37.58],
          [126.97, 37.57],
        ],
        'bbox': [126.97, 37.57, 126.98, 37.58],
      });

      expect(meta.countryId, 'kr');
      expect(meta.parentId, 'seoul-jongno-gu');
      expect(meta.level, RegionLevel.neighborhood);
      expect(meta.kind, RegionKind.dong);
      expect(meta.localName, '사직동');
      expect(meta.dataPackId, 'kr-seoul');
      expect(meta.hierarchyPath, ['kr', 'seoul', 'seoul-jongno-gu', '1111053000']);
    });

    test('explicit data-pack hierarchy fields are preserved', () {
      final meta = RegionMeta.fromJson({
        'id': 'jp-tokyo-shibuya-ebisu',
        'parentId': 'jp-tokyo-shibuya',
        'countryId': 'jp',
        'cityId': 'tokyo',
        'level': 'neighborhood',
        'kind': 'locality',
        'nameKo': '에비스',
        'nameEn': 'Ebisu',
        'localName': '恵比寿',
        'districtKo': '시부야구',
        'districtEn': 'Shibuya City',
        'dataPackId': 'jp-tokyo',
        'hierarchyPath': ['jp', 'jp-tokyo', 'jp-tokyo-shibuya', 'jp-tokyo-shibuya-ebisu'],
        'boundary': [
          [139.70, 35.64],
          [139.71, 35.64],
          [139.71, 35.65],
          [139.70, 35.65],
          [139.70, 35.64],
        ],
        'bbox': [139.70, 35.64, 139.71, 35.65],
      });

      expect(meta.countryId, 'jp');
      expect(meta.parentId, 'jp-tokyo-shibuya');
      expect(meta.kind, RegionKind.locality);
      expect(meta.localName, '恵比寿');
      expect(meta.dataPackId, 'jp-tokyo');
      expect(meta.hierarchyPath, [
        'jp',
        'jp-tokyo',
        'jp-tokyo-shibuya',
        'jp-tokyo-shibuya-ebisu',
      ]);
    });
  });
}
```

- [ ] **Step 2: Run the new test and verify it fails**

Run: `flutter test test/region_meta_test.dart`

Expected: FAIL because `RegionLevel`, `RegionKind`, and hierarchy getters do not exist yet.

- [ ] **Step 3: Implement hierarchy fields**

In `lib/data/region_meta.dart`, add enums:

```dart
enum RegionLevel { country, region, city, district, neighborhood }

enum RegionKind {
  country,
  province,
  state,
  metroCity,
  city,
  district,
  gu,
  dong,
  eup,
  myeon,
  locality,
  neighborhood,
}
```

Extend `RegionMeta` constructor and `fromJson` with `parentId`, `countryId`, `level`, `kind`, `localName`, `dataPackId`, and `hierarchyPath`. Use safe parsers that default legacy Seoul dong JSON to:

```dart
countryId: 'kr'
parentId: 'seoul-${districtEn.toLowerCase()}'.replaceAll(' ', '-')
level: RegionLevel.neighborhood
kind: RegionKind.dong
localName: nameKo
dataPackId: 'kr-seoul'
hierarchyPath: ['kr', cityId, parentId, id]
```

In `lib/data/region_repository.dart`, preserve those fields when `_withAbout` creates the enriched copy.

In `tool/build_seoul_geojson.dart`, write explicit hierarchy fields for each Seoul dong:

```dart
'parentId': 'seoul-${_slug(districtKo)}',
'countryId': 'kr',
'level': 'neighborhood',
'kind': 'dong',
'localName': dongKo,
'dataPackId': 'kr-seoul',
'hierarchyPath': ['kr', 'seoul', 'seoul-${_slug(districtKo)}', id],
```

- [ ] **Step 4: Run the hierarchy test**

Run: `flutter test test/region_meta_test.dart`

Expected: PASS.

---

### Task 2: Walk Distance Tracking Fix

**Files:**
- Create: `test/walk_session_provider_test.dart`
- Modify: `lib/screens/map_screen.dart`

- [ ] **Step 1: Write failing provider test**

Add `test/walk_session_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fog_walker/providers/walk_session_provider.dart';

void main() {
  group('WalkSessionProvider.onMove', () {
    test('distance accumulates even when no new cells are discovered', () {
      final walk = WalkSessionProvider();
      const distance = Distance();
      const start = LatLng(37.5400, 127.0000);
      final next = distance.offset(start, 100, 90);

      walk.start();
      walk.onMove(start, newCellCount: 4, regionId: 'hannam');
      walk.onMove(next, newCellCount: 0, regionId: 'hannam');

      expect(walk.activeDistanceKm, closeTo(0.1, 0.02));
      expect(walk.activeClearedKm2, greaterThan(0));
    });
  });
}
```

- [ ] **Step 2: Run the provider test**

Run: `flutter test test/walk_session_provider_test.dart`

Expected: PASS, proving the provider already supports the behavior.

- [ ] **Step 3: Change map orchestration**

In `lib/screens/map_screen.dart`, compute fresh cells outside the callback and call `walk.onMove` exactly once per accepted location. Use this shape:

```dart
final before = fog.visitedCells.length;
final wasWalking = walk.isWalking;
fog.onLocation(point, accuracy: accuracy);
final freshCount = fog.visitedCells.length - before;
if (wasWalking) {
  walk.onMove(point, newCellCount: freshCount, regionId: regionId);
}
if (freshCount > 0) {
  final unlocked = collection.checkUnlocks(fog.visitedCells);
  if (unlocked.isNotEmpty) {
    context.read<ProfileProvider>().syncProgress(
          stampCount: collection.unlockedCount,
        );
    _showUnlockSnack(unlocked.length);
  }
}
```

Also remove per-event assignment of `fog.onNewCells` from `MapScreen`; this screen can compute the fresh count directly.

- [ ] **Step 4: Run fog/session tests**

Run: `flutter test test/fog_provider_test.dart test/walk_session_provider_test.dart`

Expected: PASS.

---

### Task 3: My Info Placeholder Cleanup

**Files:**
- Modify: `lib/data/region_repository.dart`
- Modify: `lib/providers/collection_provider.dart`
- Modify: `lib/screens/my_info_screen.dart`
- Modify: `lib/widgets/passport_card.dart`

- [ ] **Step 1: Add derived collection counters**

In `CollectionProvider`, add:

```dart
int get countryCount =>
    _repo.regions.map((r) => r.countryId).where((id) => id.isNotEmpty).toSet().length;

int get unlockedCountryCount =>
    unlockedRegions.map((r) => r.countryId).where((id) => id.isNotEmpty).toSet().length;
```

In `RegionRepository`, expose city/country display helpers:

```dart
String get countryNameKo => city.countryId == 'kr' ? '대한민국' : city.countryId.toUpperCase();
String get dataPackId => regions.isEmpty ? 'kr-seoul' : regions.first.dataPackId;
```

- [ ] **Step 2: Replace My Info hard-coded country value**

Change `_statRow('국가', '1')` to:

```dart
_statRow('국가', '${collection.unlockedCountryCount} / ${collection.countryCount}'),
```

- [ ] **Step 3: Improve favorite fallback**

Change `_favorite` so a region with at least one visit wins first. If all visit counts are zero, return the most recently unlocked region instead of the first arbitrary unlocked item:

```dart
final unlocked = collection.unlockedRegions;
if (unlocked.isEmpty) return '-';
RegionMetaCount? best;
DateTime? newestUnlock;
String? newestName;
for (final r in unlocked) {
  final p = collection.progressOf(r.id);
  final count = p?.visitCount ?? 0;
  if (best == null || count > best.count) best = RegionMetaCount(r.nameKo, count);
  final unlockedAt = p?.unlockedAt;
  if (unlockedAt != null && (newestUnlock == null || unlockedAt.isAfter(newestUnlock))) {
    newestUnlock = unlockedAt;
    newestName = r.nameKo;
  }
}
if (best != null && best.count > 0) return best.name;
return newestName ?? unlocked.first.nameKo;
```

- [ ] **Step 4: Replace generic passport photo**

In `PassportCard`, pass the profile into `_photo(profile)` and replace `Icons.person` with a deterministic passport avatar using simple shapes and initials from `profile.name`:

```dart
Widget _photo(UserProfile profile) {
  final initials = profile.name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part.characters.first)
      .join();
  return Container(
    width: 84,
    height: 104,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 20,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 13,
          child: Container(
            width: 62,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          child: Text(
            initials.isEmpty ? 'FW' : initials,
            style: AppType.label(color: Colors.white, size: 10),
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze`

Expected: No issues.

---

### Task 4: Frame Mapping Documentation

**Files:**
- Modify: `docs/superpowers/specs/2026-06-13-fog-walker-design.md`
- Modify: `README.md`

- [ ] **Step 1: Fix frame mapping in design doc**

Update the navigation block to:

```markdown
├─ Tab 1: MapScreen            [Frame 277]  안개 지도 + GPS + 발자국 마커
├─ Tab 2: PassportScreen       [Frame 220]  국가별 여권 컬렉션 그리드
│              └─ CityStampsScreen   [Frame 279]  국가 → 도시 도장들
│                   └─ RegionDetailScreen [Frame 221]  도장 → 동네 상세
├─ Tab 3: AchievementScreen    [Frame 262]  업적 진행도 리스트
└─ Tab 4: MyInfoScreen         [Frame 281]  여권 프로필 + 통계 + 기록
```

- [ ] **Step 2: Add README note about local data pack strategy**

Add a short section:

```markdown
## 확장 방향

현재 앱은 서울 데이터를 기본 번들로 포함한다. 전세계 확장은 앱 설치 파일에 모든
경계를 넣는 방식이 아니라, 국가/지역/도시 단위 데이터팩을 선택 다운로드해 로컬에
캐시하는 방식으로 설계한다.
```

---

### Task 5: Full Verification

**Files:**
- Test all touched Dart files.

- [ ] **Step 1: Run all tests**

Run: `flutter test`

Expected: All tests pass.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`

Expected: No issues found.

- [ ] **Step 3: Check git diff**

Run: `git status --short`

Expected: only planned files are modified/added.

Run: `git diff --stat`

Expected: changes are concentrated in data metadata, map orchestration, My Info/passport card, docs, and tests.
