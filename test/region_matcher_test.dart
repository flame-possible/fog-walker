import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fog_walker/domain/region_matcher.dart';
import 'package:fog_walker/domain/region_shape.dart';
import 'package:fog_walker/domain/fog_grid.dart';

/// 테스트용 정사각형 지역 (경도 0~0.01, 위도 0~0.01).
RegionShape _square(String id, double minLng, double minLat, double size) {
  final maxLng = minLng + size;
  final maxLat = minLat + size;
  return RegionShape(
    id: id,
    boundary: [
      [minLng, minLat],
      [maxLng, minLat],
      [maxLng, maxLat],
      [minLng, maxLat],
      [minLng, minLat],
    ],
    bbox: [minLng, minLat, maxLng, maxLat],
  );
}

void main() {
  group('RegionShape.containsPoint (point-in-polygon)', () {
    final sq = _square('a', 127.0, 37.5, 0.01);

    test('폴리곤 내부 점은 true', () {
      expect(sq.containsPoint(const LatLng(37.505, 127.005)), isTrue);
    });

    test('폴리곤 외부 점은 false', () {
      expect(sq.containsPoint(const LatLng(37.6, 127.6)), isFalse);
    });

    test('bbox 밖의 점은 빠르게 false', () {
      expect(sq.containsPoint(const LatLng(0, 0)), isFalse);
    });
  });

  group('RegionMatcher.regionOfCell', () {
    final regions = [
      _square('jongno', 127.0, 37.5, 0.01),
      _square('jung', 127.02, 37.5, 0.01), // 떨어진 다른 지역
    ];
    final matcher = RegionMatcher(regions);

    test('지역 내부 셀은 해당 지역 id를 반환한다', () {
      final cell = FogGrid.cellOf(const LatLng(37.505, 127.005));
      expect(matcher.regionOfCell(cell), 'jongno');
    });

    test('어느 지역에도 없는 셀은 null을 반환한다', () {
      final cell = FogGrid.cellOf(const LatLng(37.505, 127.05));
      expect(matcher.regionOfCell(cell), isNull);
    });

    test('두 번째 지역 내부 셀은 그 지역 id를 반환한다', () {
      final cell = FogGrid.cellOf(const LatLng(37.505, 127.025));
      expect(matcher.regionOfCell(cell), 'jung');
    });

    test('같은 셀을 두 번 조회해도 같은 결과 (캐시 동작)', () {
      final cell = FogGrid.cellOf(const LatLng(37.505, 127.005));
      final first = matcher.regionOfCell(cell);
      final second = matcher.regionOfCell(cell);
      expect(first, second);
      expect(first, 'jongno');
    });
  });

  group('RegionMatcher.visitedCellsInRegion', () {
    final regions = [_square('jongno', 127.0, 37.5, 0.01)];
    final matcher = RegionMatcher(regions);

    test('지역 안 방문 셀만 카운트한다', () {
      final inside = FogGrid.cellOf(const LatLng(37.505, 127.005));
      final outside = FogGrid.cellOf(const LatLng(37.505, 127.05));
      final visited = {inside, outside};
      expect(matcher.visitedCellsInRegion('jongno', visited), 1);
    });
  });

  group('RegionMatcher.totalCellsInRegion', () {
    final regions = [_square('jongno', 127.0, 37.5, 0.01)];
    final matcher = RegionMatcher(regions);

    test('지역을 덮는 전체 셀 수는 0보다 크다', () {
      final total = matcher.totalCellsInRegion('jongno');
      expect(total, greaterThan(0));
    });

    test('같은 지역 전체 셀 수는 캐시되어 일정하다', () {
      final a = matcher.totalCellsInRegion('jongno');
      final b = matcher.totalCellsInRegion('jongno');
      expect(a, b);
    });
  });
}
