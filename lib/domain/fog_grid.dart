import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// 안개를 측정하는 격자 시스템.
///
/// 세계를 위경도 기준 정수 격자로 나눈다. 각 셀은 `(gx, gy)` record로
/// 식별되며, 셀 크기는 **도(degree) 단위로 고정**되어 화면 줌과 무관하다.
/// 이렇게 해야 "걸어낸 면적"이 줌 레벨에 흔들리지 않는다.
///
/// 위도 방향은 도-거리 비율이 일정(위도 1도 ≈ 111km)하지만, 경도 방향은
/// 위도가 높아질수록 좁아진다. 셀을 거의 정사각형(약 50m)으로 유지하기 위해
/// 경도 셀 크기는 위도에 따라 보정한다.
class FogGrid {
  FogGrid._();

  /// 셀의 위도 방향 크기(도). 약 50m. (위도 1도 ≈ 111,320m)
  static const double cellLatDeg = 0.00045;

  /// 위도 1도당 미터.
  static const double _metersPerLatDeg = 111320.0;

  /// 주어진 위도에서 경도 1도당 미터.
  static double _metersPerLngDeg(double lat) =>
      _metersPerLatDeg * math.cos(lat * math.pi / 180.0);

  /// 주어진 위도에서 셀의 경도 방향 크기(도). 셀을 정사각형에 가깝게 유지.
  static double cellLngDeg(double lat) {
    final cosLat = math.cos(lat * math.pi / 180.0);
    // cos가 0에 가까운 극지방 방어 (서울에선 발생 안 함)
    final safeCos = cosLat.abs() < 1e-6 ? 1e-6 : cosLat;
    return cellLatDeg / safeCos;
  }

  /// 좌표가 속한 셀 `(gx, gy)`.
  static (int, int) cellOf(LatLng p) {
    final gy = (p.latitude / cellLatDeg).floor();
    final gx = (p.longitude / cellLngDeg(p.latitude)).floor();
    return (gx, gy);
  }

  /// 셀의 중심 좌표.
  static LatLng cellCenter((int, int) cell) {
    final (gx, gy) = cell;
    final lat = (gy + 0.5) * cellLatDeg;
    final lng = (gx + 0.5) * cellLngDeg(lat);
    return LatLng(lat, lng);
  }

  /// 중심점에서 반경 [radiusMeters] 원과 겹치는 셀 집합.
  ///
  /// 걸을 때 GPS 점 주변을 "걷어내는" 범위를 셀 단위로 환산한다. 셀 중심이
  /// 아니라 **셀 사각형이 원과 교차**하는지로 판정한다. 그래야 반경이 셀
  /// 크기보다 작아도(예: 반경 30m < 셀 50m) 닿는 이웃 셀들이 함께 걷힌다.
  static Set<(int, int)> cellsWithinRadius(LatLng center, double radiusMeters) {
    final result = <(int, int)>{};
    final centerCell = cellOf(center);
    result.add(centerCell);
    if (radiusMeters <= 0) return result;

    final cellLng = cellLngDeg(center.latitude);
    // 검색 범위: 반경 + 셀 한 칸 여유를 셀 개수로 환산
    final latSpanDeg = radiusMeters / _metersPerLatDeg;
    final lngSpanDeg = radiusMeters / _metersPerLngDeg(center.latitude);
    final stepsY = (latSpanDeg / cellLatDeg).ceil() + 1;
    final stepsX = (lngSpanDeg / cellLng).ceil() + 1;

    final mPerLat = _metersPerLatDeg;
    final mPerLng = _metersPerLngDeg(center.latitude);
    final (cx, cy) = centerCell;

    for (int dy = -stepsY; dy <= stepsY; dy++) {
      for (int dx = -stepsX; dx <= stepsX; dx++) {
        final gx = cx + dx;
        final gy = cy + dy;
        // 셀 사각형 경계(도) → 중심 기준 미터 좌표로 변환
        final cellMinLat = gy * cellLatDeg;
        final cellMaxLat = (gy + 1) * cellLatDeg;
        final cellMinLng = gx * cellLng;
        final cellMaxLng = (gx + 1) * cellLng;

        // 사각형에서 center에 가장 가까운 점까지의 거리(미터, 평면 근사)
        final nearLat = center.latitude.clamp(cellMinLat, cellMaxLat);
        final nearLng = center.longitude.clamp(cellMinLng, cellMaxLng);
        final dyM = (center.latitude - nearLat) * mPerLat;
        final dxM = (center.longitude - nearLng) * mPerLng;
        if (dxM * dxM + dyM * dyM <= radiusMeters * radiusMeters) {
          result.add((gx, gy));
        }
      }
    }
    return result;
  }
}
