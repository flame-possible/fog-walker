import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/domain/location_update_policy.dart';

void main() {
  group('LocationUpdatePolicy', () {
    test('allows coarse browser positions to move the map marker', () {
      expect(LocationUpdatePolicy.canUpdateMap(accuracy: 500), isTrue);
      expect(LocationUpdatePolicy.canUpdateMap(accuracy: 2500), isTrue);
    });

    test('does not allow coarse positions to clear fog', () {
      expect(LocationUpdatePolicy.canClearFog(accuracy: 500), isFalse);
      expect(LocationUpdatePolicy.canClearFog(accuracy: 2500), isFalse);
    });

    test('allows accurate positions to update map and clear fog', () {
      expect(LocationUpdatePolicy.canUpdateMap(accuracy: 10), isTrue);
      expect(LocationUpdatePolicy.canClearFog(accuracy: 10), isTrue);
    });
  });
}
