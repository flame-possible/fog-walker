import 'package:latlong2/latlong.dart';

/// 지역의 기하 정보 — 경계 폴리곤과 바운딩 박스.
///
/// 도메인 순수 타입이라 Hive/위젯에 의존하지 않는다. 점 포함 판정과
/// 빠른 1차 필터(bbox)를 제공한다. 좌표는 모두 [경도, 위도] 순서.
class RegionShape {
  RegionShape({required this.id, required this.boundary, required this.bbox});

  final String id;

  /// 외곽 경계. 각 점은 [lng, lat].
  final List<List<double>> boundary;

  /// [minLng, minLat, maxLng, maxLat].
  final List<double> bbox;

  double get minLng => bbox[0];
  double get minLat => bbox[1];
  double get maxLng => bbox[2];
  double get maxLat => bbox[3];

  /// bbox 안에 점이 들어오는지 (빠른 1차 필터).
  bool bboxContains(LatLng p) =>
      p.longitude >= minLng &&
      p.longitude <= maxLng &&
      p.latitude >= minLat &&
      p.latitude <= maxLat;

  /// 점이 폴리곤 내부에 있는지. bbox로 먼저 걸러낸 뒤 ray-casting.
  bool containsPoint(LatLng p) {
    if (!bboxContains(p)) return false;
    return _rayCasting(p.longitude, p.latitude);
  }

  /// Ray-casting 알고리즘: 점에서 오른쪽으로 수평선을 쏴 폴리곤 변과
  /// 교차하는 횟수가 홀수면 내부.
  bool _rayCasting(double x, double y) {
    bool inside = false;
    final n = boundary.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = boundary[i][0], yi = boundary[i][1];
      final xj = boundary[j][0], yj = boundary[j][1];
      final intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}
