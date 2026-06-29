import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/data/sync_payload.dart';
import 'package:fog_walker/models/region_progress.dart';
import 'package:fog_walker/models/user_profile.dart';
import 'package:fog_walker/models/walk_session.dart';

void main() {
  group('SyncPayload', () {
    test('serializes visited cells for Supabase upsert', () {
      final row = SyncVisitedCell(
        cell: (12, -3),
        visitedAtMillis: DateTime.utc(2026, 6, 29).millisecondsSinceEpoch,
      ).toRow();

      expect(row['cell_x'], 12);
      expect(row['cell_y'], -3);
      expect(row['visited_at'], '2026-06-29T00:00:00.000Z');
    });

    test('round-trips walk sessions through a Supabase row', () {
      final session = WalkSession(
        id: 's1',
        startedAt: DateTime.utc(2026, 6, 29, 1),
        endedAt: DateTime.utc(2026, 6, 29, 2),
        distanceKm: 3.4,
        clearedKm2: 0.02,
        newCellsCount: 8,
        regionIds: const ['hannam', 'itaewon'],
      );

      final row = SyncWalkSession.fromModel(session).toRow();
      final restored = SyncWalkSession.fromRow(row).toModel();

      expect(restored.id, session.id);
      expect(restored.distanceKm, session.distanceKm);
      expect(restored.regionIds, session.regionIds);
      expect(restored.mode, WalkMode.walk);
    });

    test('round-trips region progress through a Supabase row', () {
      final progress = RegionProgress(
        regionId: 'hannam',
        unlockedAt: DateTime.utc(2026, 6, 29),
        visitCount: 3,
      );

      final row = SyncRegionProgress.fromModel(progress).toRow();
      final restored = SyncRegionProgress.fromRow(row).toModel();

      expect(restored.regionId, progress.regionId);
      expect(restored.visitCount, progress.visitCount);
    });

    test('serializes profile fields without local-only auth state', () {
      final profile = UserProfile.initial()
        ..displayName = 'Yang Walker'
        ..email = 'yang@example.com';

      final row = SyncUserProfile.fromModel(profile).toRow();

      expect(row['display_name'], 'Yang Walker');
      expect(row['email'], 'yang@example.com');
      expect(row, isNot(contains('auth_provider')));
    });
  });
}
