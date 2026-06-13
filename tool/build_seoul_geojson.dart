/// 서울 행정동 원본 GeoJSON을 앱 자산 형식으로 가공한다.
///
/// 입력:  tool/seoul_raw.geojson  (raqoon886/Local_HangJeongDong)
/// 출력:  assets/data/seoul_dong.geojson
///
/// 가공 내용:
///  - 각 행정동을 { id, nameKo, nameEn, cityId, districtKo, districtEn,
///    boundary, bbox } 형태로 변환
///  - Douglas-Peucker로 외곽선 좌표를 단순화 (용량/연산 절감)
///  - 좌표는 [경도, 위도] 순서 유지 (GeoJSON 표준)
///
/// 실행: dart run tool/build_seoul_geojson.dart
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'romanize.dart';

/// 단순화 허용 오차(도 단위). 약 0.00012도 ≈ 13m.
/// 산책 앱의 동 경계 판정에는 이 정도 정밀도면 충분하다.
const double kSimplifyToleranceDeg = 0.00012;

void main() {
  final inputFile = File('tool/seoul_raw.geojson');
  if (!inputFile.existsSync()) {
    stderr.writeln('입력 파일이 없습니다: ${inputFile.path}');
    exit(1);
  }

  final raw = jsonDecode(inputFile.readAsStringSync()) as Map<String, dynamic>;
  final features = raw['features'] as List;

  final regions = <Map<String, dynamic>>[];
  int totalIn = 0;
  int totalOut = 0;

  for (final f in features) {
    final feature = f as Map<String, dynamic>;
    final props = feature['properties'] as Map<String, dynamic>;
    final geom = feature['geometry'] as Map<String, dynamic>;

    final admNm = props['adm_nm'] as String; // "서울특별시 종로구 사직동"
    final parts = admNm.split(' ');
    final districtKo = parts.length >= 2 ? parts[1] : '';
    final dongKo = parts.length >= 3 ? parts.sublist(2).join(' ') : parts.last;

    // MultiPolygon에서 가장 큰 외곽 ring 하나를 대표 경계로 사용.
    // (서울 데이터는 동당 polygon이 1개이지만 안전하게 처리)
    final coords = geom['coordinates'] as List;
    List<List<double>> outerRing = _largestOuterRing(coords);

    totalIn += outerRing.length;
    final simplified = _douglasPeucker(outerRing, kSimplifyToleranceDeg);
    totalOut += simplified.length;

    final bbox = _bbox(simplified);

    regions.add({
      'id': props['adm_cd2']?.toString() ?? props['adm_cd'].toString(),
      'nameKo': dongKo,
      'nameEn': romanizeDong(dongKo),
      'cityId': 'seoul',
      'districtKo': districtKo,
      'districtEn': romanizeDong(districtKo),
      'boundary': simplified
          .map((p) => [_round(p[0]), _round(p[1])])
          .toList(),
      'bbox': bbox.map(_round).toList(),
    });
  }

  final out = {
    'city': {
      'id': 'seoul',
      'nameKo': '서울특별시',
      'nameEn': 'Seoul',
      'countryId': 'kr',
    },
    'regions': regions,
  };

  final outFile = File('assets/data/seoul_dong.geojson');
  outFile.writeAsStringSync(jsonEncode(out));

  final sizeKb = (outFile.lengthSync() / 1024).toStringAsFixed(0);
  stdout.writeln('가공 완료: ${regions.length}개 행정동');
  stdout.writeln('좌표 점: $totalIn → $totalOut '
      '(${(100 * totalOut / totalIn).toStringAsFixed(0)}%)');
  stdout.writeln('출력: ${outFile.path} ($sizeKb KB)');
  stdout.writeln('예시: ${regions.first['nameKo']} → ${regions.first['nameEn']}');
}

/// MultiPolygon/Polygon 좌표 구조에서 가장 점이 많은(=가장 큰) 외곽 ring.
List<List<double>> _largestOuterRing(List coordinates) {
  List<List<double>> best = [];
  // MultiPolygon: [ [ [ [lng,lat],... ](ring), ...rings ](polygon), ...polygons ]
  for (final polygon in coordinates) {
    if (polygon is! List || polygon.isEmpty) continue;
    final ring = polygon[0]; // 외곽 ring (구멍은 무시)
    if (ring is! List) continue;
    final pts = ring
        .map<List<double>>((p) => [
              (p[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ])
        .toList();
    if (pts.length > best.length) best = pts;
  }
  return best;
}

/// Douglas-Peucker 폴리라인 단순화.
List<List<double>> _douglasPeucker(List<List<double>> pts, double epsilon) {
  if (pts.length < 3) return pts;

  double maxDist = 0;
  int index = 0;
  final end = pts.length - 1;
  for (int i = 1; i < end; i++) {
    final d = _perpendicularDistance(pts[i], pts[0], pts[end]);
    if (d > maxDist) {
      maxDist = d;
      index = i;
    }
  }

  if (maxDist > epsilon) {
    final left = _douglasPeucker(pts.sublist(0, index + 1), epsilon);
    final right = _douglasPeucker(pts.sublist(index), epsilon);
    return [...left.sublist(0, left.length - 1), ...right];
  } else {
    return [pts[0], pts[end]];
  }
}

/// 점 p에서 선분 a-b까지의 수직 거리.
double _perpendicularDistance(
    List<double> p, List<double> a, List<double> b) {
  final dx = b[0] - a[0];
  final dy = b[1] - a[1];
  final mag = math.sqrt(dx * dx + dy * dy);
  if (mag == 0) {
    final ex = p[0] - a[0];
    final ey = p[1] - a[1];
    return math.sqrt(ex * ex + ey * ey);
  }
  // |cross product| / |b-a|
  final cross = ((p[0] - a[0]) * dy - (p[1] - a[1]) * dx).abs();
  return cross / mag;
}

List<double> _bbox(List<List<double>> pts) {
  double minLng = double.infinity, minLat = double.infinity;
  double maxLng = -double.infinity, maxLat = -double.infinity;
  for (final p in pts) {
    minLng = math.min(minLng, p[0]);
    minLat = math.min(minLat, p[1]);
    maxLng = math.max(maxLng, p[0]);
    maxLat = math.max(maxLat, p[1]);
  }
  return [minLng, minLat, maxLng, maxLat];
}

/// 좌표 자릿수 축소(6자리 ≈ 0.1m 정밀도)로 용량 절감.
double _round(double v) => (v * 1e6).round() / 1e6;
