import 'dart:math' as math;

import 'fog_grid.dart';

/// 방문 셀로부터 면적과 클리어 비율을 계산한다.
///
/// 화면 픽셀이 아니라 격자 셀 개수로 면적을 재므로 줌 레벨과 무관하게
/// 안정적이다. 한 셀은 약 50m×50m이며, 위도에 따른 경도 보정으로 면적이
/// 위도에 거의 흔들리지 않는다.
class AreaCalculator {
  AreaCalculator._();

  static const double _metersPerLatDeg = 111320.0;

  /// 주어진 위도에서 한 셀의 면적(km²).
  static double cellAreaKm2(double lat) {
    final latMeters = FogGrid.cellLatDeg * _metersPerLatDeg;
    final lngDeg = FogGrid.cellLngDeg(lat);
    final lngMeters =
        lngDeg * _metersPerLatDeg * math.cos(lat * math.pi / 180.0);
    final areaM2 = latMeters * lngMeters;
    return areaM2 / 1e6; // m² → km²
  }

  /// 방문 셀 집합의 총 면적(km²). [refLat]은 셀 면적 보정용 기준 위도.
  static double totalAreaKm2(Set<(int, int)> cells, double refLat) {
    if (cells.isEmpty) return 0;
    return cells.length * cellAreaKm2(refLat);
  }

  /// 클리어 비율(0~100). 전체 셀이 0이면 0을 반환(0으로 나누기 방어).
  static double clearPercent({required int visited, required int total}) {
    if (total <= 0) return 0;
    return 100.0 * visited / total;
  }
}
