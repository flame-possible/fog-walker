import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/domain/walk_stats.dart';
import 'package:fog_walker/models/walk_session.dart';

WalkSession _session({
  required DateTime day,
  double distanceKm = 2.0,
  double clearedKm2 = 0.01,
  WalkMode mode = WalkMode.walk,
  int newCells = 4,
}) {
  return WalkSession(
    id: day.toIso8601String(),
    startedAt: day,
    endedAt: day.add(const Duration(minutes: 30)),
    distanceKm: distanceKm,
    clearedKm2: clearedKm2,
    newCellsCount: newCells,
    regionIds: const ['a'],
    mode: mode,
  );
}

void main() {
  group('WalkStats.totalDistanceKm', () {
    test('모든 세션 거리의 합이다', () {
      final sessions = [
        _session(day: DateTime(2026, 6, 1), distanceKm: 2),
        _session(day: DateTime(2026, 6, 2), distanceKm: 3),
        _session(day: DateTime(2026, 6, 3), distanceKm: 1.5),
      ];
      expect(WalkStats.totalDistanceKm(sessions), closeTo(6.5, 1e-9));
    });

    test('세션이 없으면 0이다', () {
      expect(WalkStats.totalDistanceKm([]), 0);
    });
  });

  group('WalkStats.distanceByMode', () {
    test('이동 수단별로 거리를 합산한다', () {
      final sessions = [
        _session(day: DateTime(2026, 6, 1), distanceKm: 2, mode: WalkMode.walk),
        _session(day: DateTime(2026, 6, 2), distanceKm: 5, mode: WalkMode.bike),
        _session(day: DateTime(2026, 6, 3), distanceKm: 1, mode: WalkMode.walk),
      ];
      expect(
        WalkStats.distanceByMode(sessions, WalkMode.walk),
        closeTo(3, 1e-9),
      );
      expect(
        WalkStats.distanceByMode(sessions, WalkMode.bike),
        closeTo(5, 1e-9),
      );
      expect(WalkStats.distanceByMode(sessions, WalkMode.swim), 0);
    });
  });

  group('WalkStats.longestWalkKm', () {
    test('가장 긴 단일 산책 거리다', () {
      final sessions = [
        _session(day: DateTime(2026, 6, 1), distanceKm: 2),
        _session(day: DateTime(2026, 6, 2), distanceKm: 18.4),
        _session(day: DateTime(2026, 6, 3), distanceKm: 5),
      ];
      expect(WalkStats.longestWalkKm(sessions), 18.4);
    });

    test('세션이 없으면 0이다', () {
      expect(WalkStats.longestWalkKm([]), 0);
    });
  });

  group('WalkStats.currentStreakDays', () {
    test('오늘부터 연속된 날짜 수를 센다', () {
      final today = DateTime(2026, 6, 13);
      final sessions = [
        _session(day: DateTime(2026, 6, 13)),
        _session(day: DateTime(2026, 6, 12)),
        _session(day: DateTime(2026, 6, 11)),
      ];
      expect(WalkStats.currentStreakDays(sessions, today: today), 3);
    });

    test('하루 걸러 산책하면 연속이 끊긴다', () {
      final today = DateTime(2026, 6, 13);
      final sessions = [
        _session(day: DateTime(2026, 6, 13)),
        _session(day: DateTime(2026, 6, 11)), // 12일 빠짐
      ];
      expect(WalkStats.currentStreakDays(sessions, today: today), 1);
    });

    test('어제까지만 했으면 연속은 어제부터 이어진다', () {
      final today = DateTime(2026, 6, 13);
      final sessions = [
        _session(day: DateTime(2026, 6, 12)),
        _session(day: DateTime(2026, 6, 11)),
      ];
      expect(WalkStats.currentStreakDays(sessions, today: today), 2);
    });

    test('같은 날 여러 번 산책해도 하루로 센다', () {
      final today = DateTime(2026, 6, 13);
      final sessions = [
        _session(day: DateTime(2026, 6, 13, 9)),
        _session(day: DateTime(2026, 6, 13, 18)),
        _session(day: DateTime(2026, 6, 12)),
      ];
      expect(WalkStats.currentStreakDays(sessions, today: today), 2);
    });

    test('세션이 없으면 0이다', () {
      expect(WalkStats.currentStreakDays([], today: DateTime(2026, 6, 13)), 0);
    });
  });

  group('WalkStats.weekly (This Week)', () {
    test('이번 주(최근 7일) 세션만 집계한다', () {
      final today = DateTime(2026, 6, 13);
      final sessions = [
        _session(
          day: DateTime(2026, 6, 13),
          distanceKm: 2,
          clearedKm2: 0.3,
          newCells: 1,
        ),
        _session(
          day: DateTime(2026, 6, 10),
          distanceKm: 3,
          clearedKm2: 0.4,
          newCells: 2,
        ),
        _session(
          day: DateTime(2026, 6, 1),
          distanceKm: 9,
          clearedKm2: 9,
          newCells: 9,
        ), // 주 밖
      ];
      final w = WalkStats.weekly(sessions, today: today);
      expect(w.sessionCount, 2);
      expect(w.distanceKm, closeTo(5, 1e-9));
      expect(w.clearedKm2, closeTo(0.7, 1e-9));
    });
  });
}
