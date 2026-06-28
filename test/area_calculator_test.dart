import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fog_walker/domain/area_calculator.dart';
import 'package:fog_walker/domain/fog_grid.dart';

void main() {
  group('AreaCalculator.cellAreaKm2', () {
    test('서울 위도에서 한 셀은 약 50m×50m = 0.0025 km²이다', () {
      final area = AreaCalculator.cellAreaKm2(37.54);
      // 50m × 50m = 2500 m² = 0.0025 km². ±10% 허용 (위도 보정/근사)
      expect(area, closeTo(0.0025, 0.0003));
    });

    test('위도가 높아져도 셀 면적은 거의 일정하다 (정사각형 유지)', () {
      // 경도 셀 크기를 위도로 보정하므로 면적이 위도에 크게 안 흔들려야 한다
      final seoul = AreaCalculator.cellAreaKm2(37.54);
      final busan = AreaCalculator.cellAreaKm2(35.18);
      expect(seoul, closeTo(busan, 0.0002));
    });
  });

  group('AreaCalculator.totalAreaKm2', () {
    test('빈 셀 집합은 0 면적이다', () {
      expect(AreaCalculator.totalAreaKm2(<(int, int)>{}, 37.54), 0);
    });

    test('셀 N개의 면적은 한 셀 면적의 N배다', () {
      final cells = <(int, int)>{(0, 0), (1, 0), (2, 0), (0, 1)};
      final total = AreaCalculator.totalAreaKm2(cells, 37.54);
      final one = AreaCalculator.cellAreaKm2(37.54);
      expect(total, closeTo(one * 4, 1e-9));
    });

    test('직선 1km를 걸으면 대략 그에 맞는 면적이 걷힌다', () {
      // 서울에서 동쪽으로 약 1km 직선 이동을 시뮬레이션
      const start = LatLng(37.5400, 127.0000);
      const distance = Distance();
      final visited = <(int, int)>{};
      for (double m = 0; m <= 1000; m += 10) {
        final p = distance.offset(start, m, 90); // 동쪽으로 m미터
        visited.addAll(FogGrid.cellsWithinRadius(p, 30));
      }
      final area = AreaCalculator.totalAreaKm2(visited, 37.54);
      // 폭 60m(반경30 양쪽) × 길이 1000m ≈ 0.06 km². 넉넉한 범위로 검증.
      expect(area, greaterThan(0.03));
      expect(area, lessThan(0.15));
    });
  });

  group('AreaCalculator.clearPercent', () {
    test('방문 셀이 없으면 0%다', () {
      expect(AreaCalculator.clearPercent(visited: 0, total: 100), 0);
    });

    test('전체 셀을 다 방문하면 100%다', () {
      expect(AreaCalculator.clearPercent(visited: 100, total: 100), 100);
    });

    test('절반 방문하면 50%다', () {
      expect(
        AreaCalculator.clearPercent(visited: 50, total: 100),
        closeTo(50, 0.001),
      );
    });

    test('전체 셀이 0이면 0%를 반환한다 (0으로 나누기 방어)', () {
      expect(AreaCalculator.clearPercent(visited: 0, total: 0), 0);
    });
  });
}
