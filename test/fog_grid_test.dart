import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fog_walker/domain/fog_grid.dart';

void main() {
  group('FogGrid.cellOf', () {
    test('같은 좌표는 항상 같은 셀로 매핑된다', () {
      const p = LatLng(37.5400, 127.0050);
      expect(FogGrid.cellOf(p), FogGrid.cellOf(p));
    });

    test('한 셀(약 50m) 안의 가까운 두 점은 같은 셀이다', () {
      // 같은 셀 안의 두 점 (약 10m 차이)
      const a = LatLng(37.54000, 127.00500);
      const b = LatLng(37.54005, 127.00505);
      expect(FogGrid.cellOf(a), FogGrid.cellOf(b));
    });

    test('충분히 멀리 떨어진 두 점은 다른 셀이다', () {
      const a = LatLng(37.5400, 127.0050);
      const b = LatLng(37.5500, 127.0150); // 약 1km 이상
      expect(FogGrid.cellOf(a), isNot(FogGrid.cellOf(b)));
    });

    test('record 셀은 Set에서 값 동등성으로 중복 제거된다', () {
      const p = LatLng(37.5400, 127.0050);
      final set = <(int, int)>{};
      set.add(FogGrid.cellOf(p));
      set.add(FogGrid.cellOf(p));
      expect(set.length, 1);
    });
  });

  group('FogGrid.cellsWithinRadius', () {
    test('반경 0이면 중심 셀 하나만 반환한다', () {
      const center = LatLng(37.5400, 127.0050);
      final cells = FogGrid.cellsWithinRadius(center, 0);
      expect(cells, contains(FogGrid.cellOf(center)));
      expect(cells.length, 1);
    });

    test('반경 30m면 중심 셀을 포함한 여러 셀을 반환한다', () {
      const center = LatLng(37.5400, 127.0050);
      final cells = FogGrid.cellsWithinRadius(center, 30);
      expect(cells, contains(FogGrid.cellOf(center)));
      expect(cells.length, greaterThan(1));
    });

    test('반경이 클수록 더 많은 셀을 반환한다', () {
      const center = LatLng(37.5400, 127.0050);
      final small = FogGrid.cellsWithinRadius(center, 30);
      final large = FogGrid.cellsWithinRadius(center, 100);
      expect(large.length, greaterThan(small.length));
    });

    test('반환된 모든 셀은 중심에서 (반경 + 셀 대각선) 이내에 있다', () {
      const center = LatLng(37.5400, 127.0050);
      const radiusM = 50.0;
      final cells = FogGrid.cellsWithinRadius(center, radiusM);
      const distance = Distance();
      // 교차 판정이므로 셀의 가장 가까운 모서리가 반경 안이면 포함된다.
      // 따라서 셀 중심까지의 최대 거리는 반경 + (셀 대각선 ≈ 71m) + 여유.
      const maxCenterDist = radiusM + 71 + 30;
      for (final cell in cells) {
        final cc = FogGrid.cellCenter(cell);
        expect(distance(center, cc), lessThan(maxCenterDist));
      }
    });
  });

  group('FogGrid.cellCenter', () {
    test('셀 중심을 다시 cellOf하면 같은 셀이 나온다', () {
      const p = LatLng(37.5400, 127.0050);
      final cell = FogGrid.cellOf(p);
      final center = FogGrid.cellCenter(cell);
      expect(FogGrid.cellOf(center), cell);
    });
  });
}
