import '../models/walk_session.dart';

/// 이번 주 요약 (This Week 카드).
class WeeklySummary {
  const WeeklySummary({
    required this.sessionCount,
    required this.distanceKm,
    required this.clearedKm2,
    required this.newCells,
  });

  final int sessionCount;
  final double distanceKm;
  final double clearedKm2;
  final int newCells;
}

/// 산책 세션 목록에서 통계를 집계하는 순수 함수 모음.
///
/// 총 거리·연속일·This Week 등은 저장하지 않고 여기서 파생한다. 날짜 의존
/// 함수는 [today]를 주입받아 테스트 가능하게 한다.
class WalkStats {
  WalkStats._();

  static double totalDistanceKm(List<WalkSession> sessions) {
    double sum = 0;
    for (final s in sessions) {
      sum += s.distanceKm;
    }
    return sum;
  }

  static double distanceByMode(List<WalkSession> sessions, WalkMode mode) {
    double sum = 0;
    for (final s in sessions) {
      if (s.mode == mode) sum += s.distanceKm;
    }
    return sum;
  }

  static double longestWalkKm(List<WalkSession> sessions) {
    double max = 0;
    for (final s in sessions) {
      if (s.distanceKm > max) max = s.distanceKm;
    }
    return max;
  }

  static double totalClearedKm2(List<WalkSession> sessions) {
    double sum = 0;
    for (final s in sessions) {
      sum += s.clearedKm2;
    }
    return sum;
  }

  /// 오늘부터 거꾸로 이어지는 연속 산책 일수.
  ///
  /// 오늘 또는 어제에 산책 기록이 있어야 연속이 시작된다(오늘 아직 안 걸었어도
  /// 어제까지 이어졌으면 유지). 같은 날 여러 세션은 하루로 센다.
  static int currentStreakDays(
    List<WalkSession> sessions, {
    required DateTime today,
  }) {
    if (sessions.isEmpty) return 0;

    // 산책한 날짜(연-월-일) 집합
    final days = <DateTime>{};
    for (final s in sessions) {
      days.add(_dateOnly(s.startedAt));
    }

    final t = _dateOnly(today);
    // 시작점: 오늘 기록이 있으면 오늘, 없으면 어제부터 본다.
    DateTime cursor;
    if (days.contains(t)) {
      cursor = t;
    } else if (days.contains(t.subtract(const Duration(days: 1)))) {
      cursor = t.subtract(const Duration(days: 1));
    } else {
      return 0;
    }

    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 최근 7일(오늘 포함) 요약.
  static WeeklySummary weekly(
    List<WalkSession> sessions, {
    required DateTime today,
  }) {
    final start = _dateOnly(today).subtract(const Duration(days: 6));
    int count = 0;
    double dist = 0;
    double cleared = 0;
    int cells = 0;
    for (final s in sessions) {
      final d = _dateOnly(s.startedAt);
      if (!d.isBefore(start)) {
        count++;
        dist += s.distanceKm;
        cleared += s.clearedKm2;
        cells += s.newCellsCount;
      }
    }
    return WeeklySummary(
      sessionCount: count,
      distanceKm: dist,
      clearedKm2: cleared,
      newCells: cells,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
