import 'package:latlong2/latlong.dart';

import 'fog_grid.dart';
import 'region_shape.dart';

/// 격자 셀과 행정동을 잇는 매처.
///
/// GPS로 방문 셀이 늘어날 때마다 모든 폴리곤을 검사하면 느리므로,
/// bbox 1차 필터 + 셀→지역 결과 캐시로 비용을 줄인다. 지역의 전체 셀 수도
/// (클리어 % 분모) 한 번 계산해 캐시한다.
class RegionMatcher {
  RegionMatcher(List<RegionShape> regions)
      : _regions = regions,
        _byId = {for (final r in regions) r.id: r};

  final List<RegionShape> _regions;
  final Map<String, RegionShape> _byId;

  /// 셀 → 지역 id (또는 null). 한 번 판정한 셀은 재계산하지 않는다.
  final Map<(int, int), String?> _cellRegionCache = {};

  /// 지역 id → 그 지역을 덮는 전체 셀 수 (클리어 % 분모).
  final Map<String, int> _totalCellsCache = {};

  /// 셀이 속한 지역 id. 어느 지역에도 없으면 null.
  String? regionOfCell((int, int) cell) {
    final cached = _cellRegionCache[cell];
    if (cached != null || _cellRegionCache.containsKey(cell)) return cached;

    final center = FogGrid.cellCenter(cell);
    String? found;
    for (final r in _regions) {
      // bbox 1차 필터 후 정밀 판정
      if (r.bboxContains(center) && r.containsPoint(center)) {
        found = r.id;
        break;
      }
    }
    _cellRegionCache[cell] = found;
    return found;
  }

  /// 방문 셀 중 특정 지역에 속하는 셀 개수.
  int visitedCellsInRegion(String regionId, Set<(int, int)> visited) {
    int count = 0;
    for (final cell in visited) {
      if (regionOfCell(cell) == regionId) count++;
    }
    return count;
  }

  /// 특정 지역을 덮는 전체 셀 수 (캐시됨).
  int totalCellsInRegion(String regionId) {
    final cached = _totalCellsCache[regionId];
    if (cached != null) return cached;

    final r = _byId[regionId];
    if (r == null) {
      _totalCellsCache[regionId] = 0;
      return 0;
    }

    // bbox를 셀 격자로 훑으며 셀 중심이 폴리곤 안인 것을 센다.
    final minCell = FogGrid.cellOf(LatLng(r.minLat, r.minLng));
    final maxCell = FogGrid.cellOf(LatLng(r.maxLat, r.maxLng));
    int count = 0;
    for (int gy = minCell.$2; gy <= maxCell.$2; gy++) {
      for (int gx = minCell.$1; gx <= maxCell.$1; gx++) {
        final center = FogGrid.cellCenter((gx, gy));
        if (r.containsPoint(center)) count++;
      }
    }
    // 매우 작은 폴리곤이 셀 중심을 하나도 안 품는 경우 최소 1로 보정
    if (count == 0) count = 1;
    _totalCellsCache[regionId] = count;
    return count;
  }

  RegionShape? shapeOf(String regionId) => _byId[regionId];
  Iterable<RegionShape> get shapes => _regions;
}
