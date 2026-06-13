/// 업적이 측정하는 지표.
enum AchievementMetric {
  streakDays, // 연속 산책일
  regionsUnlocked, // 해금한 지역 수
  totalDistanceKm, // 누적 걷기 거리
  bikeDistanceKm, // 누적 자전거 거리
  swimDistanceKm, // 누적 수영 거리
  hikeDistanceKm, // 누적 하이킹 거리
}

/// 업적 진행도 판정에 쓰이는 사용자 집계 통계.
///
/// walkSessions/visitedCells에서 파생되는 값들. 순수 데이터라 테스트 쉽다.
class UserStats {
  const UserStats({
    this.streakDays = 0,
    this.regionsUnlocked = 0,
    this.totalDistanceKm = 0,
    this.bikeDistanceKm = 0,
    this.swimDistanceKm = 0,
    this.hikeDistanceKm = 0,
  });

  final int streakDays;
  final int regionsUnlocked;
  final double totalDistanceKm;
  final double bikeDistanceKm;
  final double swimDistanceKm;
  final double hikeDistanceKm;

  double valueFor(AchievementMetric m) {
    switch (m) {
      case AchievementMetric.streakDays:
        return streakDays.toDouble();
      case AchievementMetric.regionsUnlocked:
        return regionsUnlocked.toDouble();
      case AchievementMetric.totalDistanceKm:
        return totalDistanceKm;
      case AchievementMetric.bikeDistanceKm:
        return bikeDistanceKm;
      case AchievementMetric.swimDistanceKm:
        return swimDistanceKm;
      case AchievementMetric.hikeDistanceKm:
        return hikeDistanceKm;
    }
  }
}

/// 하나의 업적 정의. 진행도는 사용자 통계로부터 실시간 계산한다(저장 안 함).
class Achievement {
  const Achievement({
    required this.id,
    required this.titleKo,
    required this.descKo,
    required this.metric,
    required this.goal,
  });

  final String id;
  final String titleKo;
  final String descKo;
  final AchievementMetric metric;
  final double goal;

  /// 0.0~1.0 진행도. 목표 초과 시 1.0으로 캡.
  double progress(UserStats stats) {
    if (goal <= 0) return 0;
    final ratio = stats.valueFor(metric) / goal;
    return ratio.clamp(0.0, 1.0);
  }

  bool isCompleted(UserStats stats) => stats.valueFor(metric) >= goal;
}
