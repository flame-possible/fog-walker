import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../data/region_meta.dart';
import '../data/region_repository.dart';
import '../domain/achievement.dart';
import '../domain/area_calculator.dart';
import '../models/region_progress.dart';

/// 지역 해금·도장·업적 컬렉션을 관리한다.
///
/// RegionRepository(불변 메타/matcher)와 Hive regionProgress(가변 상태)를
/// 조합한다. 방문 셀이 늘면 checkUnlocks로 새 지역 해금을 판정한다.
class CollectionProvider extends ChangeNotifier {
  CollectionProvider({
    required RegionRepository repository,
    Box<RegionProgress>? progressBox,
  }) : _repo = repository,
       _progressBox = progressBox;

  final RegionRepository _repo;
  final Box<RegionProgress>? _progressBox;

  RegionRepository get repository => _repo;

  List<RegionMeta> get allRegions => _repo.regions;

  RegionProgress? progressOf(String regionId) => _progressBox?.get(regionId);

  bool isUnlocked(String regionId) =>
      _progressBox?.containsKey(regionId) ?? false;

  List<RegionMeta> get unlockedRegions =>
      _repo.regions.where((r) => isUnlocked(r.id)).toList();

  List<RegionProgress> get progressRecords =>
      _progressBox?.values.toList(growable: false) ?? const [];

  int get unlockedCount => unlockedRegions.length;
  int get countryCount {
    final countries = _repo.regions
        .map((r) => r.countryId)
        .where((id) => id.isNotEmpty);
    return countries.toSet().length;
  }

  int get unlockedCountryCount {
    final countries = unlockedRegions
        .map((r) => r.countryId)
        .where((id) => id.isNotEmpty);
    return countries.toSet().length;
  }

  /// 방문 셀 집합으로 새 지역 해금을 판정한다. 새로 해금된 지역 id 목록 반환.
  List<String> checkUnlocks(Set<(int, int)> visited) {
    final box = _progressBox;
    if (box == null) return const [];
    final newlyUnlocked = <String>[];
    final now = DateTime.now();

    // 방문 셀이 속한 지역들을 모아 미해금이면 해금한다.
    final touchedRegions = <String>{};
    for (final cell in visited) {
      final id = _repo.matcher.regionOfCell(cell);
      if (id != null) touchedRegions.add(id);
    }

    for (final id in touchedRegions) {
      if (!box.containsKey(id)) {
        box.put(id, RegionProgress(regionId: id, unlockedAt: now));
        newlyUnlocked.add(id);
      }
    }
    if (newlyUnlocked.isNotEmpty) notifyListeners();
    return newlyUnlocked;
  }

  /// 지역의 클리어 비율(0~100). 방문 셀을 입력받아 실시간 계산.
  double clearPercentOf(String regionId, Set<(int, int)> visited) {
    final total = _repo.matcher.totalCellsInRegion(regionId);
    final inRegion = _repo.matcher.visitedCellsInRegion(regionId, visited);
    return AreaCalculator.clearPercent(visited: inRegion, total: total);
  }

  /// 지역 방문 횟수 증가 (산책 종료 시 호출).
  void recordVisit(String regionId) {
    final box = _progressBox;
    if (box == null) return;
    final p = box.get(regionId);
    if (p != null) {
      p.visitCount++;
      box.put(regionId, p);
      notifyListeners();
    }
  }

  /// 서버에서 내려받은 지역 진행 상태를 로컬에 병합한다.
  Future<int> mergeProgress(Iterable<RegionProgress> remote) async {
    final box = _progressBox;
    if (box == null) return 0;
    var changed = 0;
    for (final incoming in remote) {
      final local = box.get(incoming.regionId);
      if (local == null) {
        await box.put(incoming.regionId, incoming);
        changed++;
        continue;
      }
      final unlockedAt = incoming.unlockedAt.isBefore(local.unlockedAt)
          ? incoming.unlockedAt
          : local.unlockedAt;
      final visitCount = incoming.visitCount > local.visitCount
          ? incoming.visitCount
          : local.visitCount;
      if (unlockedAt != local.unlockedAt || visitCount != local.visitCount) {
        await box.put(
          incoming.regionId,
          RegionProgress(
            regionId: incoming.regionId,
            unlockedAt: unlockedAt,
            visitCount: visitCount,
          ),
        );
        changed++;
      }
    }
    if (changed > 0) notifyListeners();
    return changed;
  }

  // --- 업적 ---

  /// 앱의 업적 카탈로그 (스크린샷 기준).
  static const List<Achievement> catalog = [
    Achievement(
      id: 'first_steps',
      titleKo: '첫 발자국',
      descKo: '처음 산책을 10일 동안 걸어보세요',
      metric: AchievementMetric.streakDays,
      goal: 10,
    ),
    Achievement(
      id: 'explorer',
      titleKo: '동네 탐험가',
      descKo: '12개의 지역을 발견하세요',
      metric: AchievementMetric.regionsUnlocked,
      goal: 12,
    ),
    Achievement(
      id: 'distance_collector',
      titleKo: '거리 수집가',
      descKo: '누적 1,000km를 걸어보세요',
      metric: AchievementMetric.totalDistanceKm,
      goal: 1000,
    ),
    Achievement(
      id: 'fog_lifter',
      titleKo: '안개 개척자',
      descKo: '안개 1km²를 걸어서 걷어내세요',
      metric: AchievementMetric.totalClearedKm2,
      goal: 1,
    ),
  ];
}
