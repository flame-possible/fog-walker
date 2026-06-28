import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:fog_walker/providers/walk_session_provider.dart';

void main() {
  group('WalkSessionProvider.onMove', () {
    test('distance accumulates even when no new cells are discovered', () {
      final walk = WalkSessionProvider();
      const distance = Distance();
      const start = LatLng(37.5400, 127.0000);
      final next = distance.offset(start, 100, 90);

      walk.start();
      walk.onMove(start, newCellCount: 4, regionId: 'hannam');
      walk.onMove(next, newCellCount: 0, regionId: 'hannam');

      expect(walk.activeDistanceKm, closeTo(0.1, 0.02));
      expect(walk.activeClearedKm2, greaterThan(0));
    });
  });
}
