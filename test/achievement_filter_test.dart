import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/domain/achievement.dart';
import 'package:fog_walker/domain/achievement_filter.dart';

void main() {
  const stats = UserStats(
    streakDays: 3,
    regionsUnlocked: 12,
    totalDistanceKm: 42,
    totalClearedKm2: 0.35,
  );

  const achievements = [
    Achievement(
      id: 'streak',
      titleKo: '연속 산책',
      descKo: '10일 연속 걷기',
      metric: AchievementMetric.streakDays,
      goal: 10,
    ),
    Achievement(
      id: 'regions',
      titleKo: '동네 탐험가',
      descKo: '12개 지역 발견',
      metric: AchievementMetric.regionsUnlocked,
      goal: 12,
    ),
    Achievement(
      id: 'distance',
      titleKo: '거리 수집가',
      descKo: '누적 100km 걷기',
      metric: AchievementMetric.totalDistanceKm,
      goal: 100,
    ),
    Achievement(
      id: 'area',
      titleKo: '안개 개척자',
      descKo: '안개 1km² 걷어내기',
      metric: AchievementMetric.totalClearedKm2,
      goal: 1,
    ),
  ];

  group('AchievementFilter', () {
    test('filters completed achievements', () {
      final result = const AchievementFilter(
        status: AchievementStatusFilter.completed,
      ).apply(achievements, stats);

      expect(result.map((a) => a.id), ['regions']);
    });

    test('filters by walking-focused achievement type', () {
      final result = const AchievementFilter(
        type: AchievementTypeFilter.area,
      ).apply(achievements, stats);

      expect(result.map((a) => a.id), ['area']);
    });

    test('searches title and description case-insensitively', () {
      final result = const AchievementFilter(
        query: '100km',
      ).apply(achievements, stats);

      expect(result.map((a) => a.id), ['distance']);
    });
  });
}
