import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fog_walker/domain/fog_grid.dart';
import 'package:fog_walker/providers/fog_provider.dart';

void main() {
  group('FogProvider.onLocation', () {
    test('첫 위치를 받으면 셀이 추가된다', () {
      final fog = FogProvider();
      expect(fog.visitedCells, isEmpty);

      fog.onLocation(const LatLng(37.5400, 127.0050), accuracy: 10);

      expect(fog.visitedCells, isNotEmpty);
      expect(
        fog.visitedCells,
        contains(FogGrid.cellOf(const LatLng(37.5400, 127.0050))),
      );
    });

    test('새 셀이 추가되면 리스너에게 알린다', () {
      final fog = FogProvider();
      var notified = 0;
      fog.addListener(() => notified++);

      fog.onLocation(const LatLng(37.5400, 127.0050), accuracy: 10);

      expect(notified, greaterThan(0));
    });

    test('정확도가 나쁜(>50m) 위치는 무시한다', () {
      final fog = FogProvider();
      fog.onLocation(const LatLng(37.5400, 127.0050), accuracy: 80);
      expect(fog.visitedCells, isEmpty);
    });

    test('같은 자리를 반복해 받아도 면적이 늘지 않는다', () {
      final fog = FogProvider();
      fog.onLocation(const LatLng(37.5400, 127.0050), accuracy: 10);
      final after1 = fog.visitedCells.length;
      fog.onLocation(const LatLng(37.5400, 127.0050), accuracy: 10);
      fog.onLocation(const LatLng(37.5400, 127.0050), accuracy: 10);
      expect(fog.visitedCells.length, after1);
    });

    test('순간이동(직전 점에서 비현실적으로 먼 점)은 무시한다', () {
      final fog = FogProvider();
      fog.onLocation(const LatLng(37.5400, 127.0050), accuracy: 10);
      final before = fog.visitedCells.length;
      // 바로 다음 이벤트가 수십 km 떨어짐 → 무시되어야 함
      fog.onLocation(const LatLng(38.0000, 128.0000), accuracy: 10);
      expect(fog.visitedCells.length, before);
    });

    test('새 셀 추가 시 onNewCells 콜백에 추가된 셀들이 전달된다', () {
      final fog = FogProvider();
      Set<(int, int)>? received;
      fog.onNewCells = (cells) => received = cells;

      fog.onLocation(const LatLng(37.5400, 127.0050), accuracy: 10);

      expect(received, isNotNull);
      expect(received, isNotEmpty);
    });

    test('onLocation은 이번 위치에서 새로 추가된 셀만 반환한다', () {
      final fog = FogProvider();
      final first = fog.onLocation(
        const LatLng(37.5400, 127.0050),
        accuracy: 10,
      );
      final second = fog.onLocation(
        const LatLng(37.5400, 127.0050),
        accuracy: 10,
      );

      expect(first.accepted, isTrue);
      expect(first.freshCells, isNotEmpty);
      expect(second.accepted, isTrue);
      expect(second.freshCells, isEmpty);
    });

    test('onLocation은 무시된 GPS 신호를 accepted=false로 표시한다', () {
      final fog = FogProvider();
      final update = fog.onLocation(
        const LatLng(37.5400, 127.0050),
        accuracy: 80,
      );

      expect(update.accepted, isFalse);
      expect(update.freshCells, isEmpty);
    });
  });

  group('FogProvider.totalAreaKm2', () {
    test('걸을수록 면적이 증가한다', () {
      final fog = FogProvider();
      const distance = Distance();
      const start = LatLng(37.5400, 127.0000);

      fog.onLocation(start, accuracy: 10);
      final area1 = fog.totalAreaKm2;

      // 동쪽으로 500m 이동
      for (double m = 50; m <= 500; m += 50) {
        fog.onLocation(distance.offset(start, m, 90), accuracy: 10);
      }
      final area2 = fog.totalAreaKm2;

      expect(area2, greaterThan(area1));
    });

    test('아무 위치도 없으면 면적은 0이다', () {
      expect(FogProvider().totalAreaKm2, 0);
    });
  });

  group('FogProvider.loadInitial', () {
    test('기존 방문 셀로 초기화할 수 있다', () {
      final fog = FogProvider();
      final cells = {(1, 2), (3, 4), (5, 6)};
      fog.loadInitial(cells);
      expect(fog.visitedCells.length, 3);
      expect(fog.visitedCells, containsAll(cells));
    });
  });
}
