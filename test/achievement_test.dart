import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/domain/achievement.dart';

void main() {
  group('Achievement.progress', () {
    test('목표의 절반을 달성하면 진행도 0.5다', () {
      const a = Achievement(
        id: 'dist',
        titleKo: '거리 수집가',
        descKo: '누적 1,000km를 걸어보세요',
        metric: AchievementMetric.totalDistanceKm,
        goal: 1000,
      );
      final p = a.progress(const UserStats(totalDistanceKm: 500));
      expect(p, closeTo(0.5, 1e-9));
    });

    test('목표를 초과 달성해도 진행도는 1.0으로 캡된다', () {
      const a = Achievement(
        id: 'dist',
        titleKo: '거리 수집가',
        descKo: '누적 1,000km',
        metric: AchievementMetric.totalDistanceKm,
        goal: 1000,
      );
      final p = a.progress(const UserStats(totalDistanceKm: 1500));
      expect(p, 1.0);
    });

    test('아무것도 안 했으면 진행도 0이다', () {
      const a = Achievement(
        id: 'regions',
        titleKo: '동네 탐험가',
        descKo: '12개 지역 발견',
        metric: AchievementMetric.regionsUnlocked,
        goal: 12,
      );
      expect(a.progress(const UserStats()), 0.0);
    });

    test('연속 산책일 지표로 진행도를 계산한다', () {
      const a = Achievement(
        id: 'streak',
        titleKo: '첫 발자국',
        descKo: '처음 산책을 10일 동안',
        metric: AchievementMetric.streakDays,
        goal: 10,
      );
      final p = a.progress(const UserStats(streakDays: 9));
      expect(p, closeTo(0.9, 1e-9));
    });

    test('안개를 걷어낸 면적 지표로 진행도를 계산한다', () {
      const area = Achievement(
        id: 'area',
        titleKo: '안개 개척자',
        descKo: '안개 1km² 걷어내기',
        metric: AchievementMetric.totalClearedKm2,
        goal: 1,
      );
      final p = area.progress(const UserStats(totalClearedKm2: 0.25));
      expect(p, closeTo(0.25, 1e-9));
    });
  });

  group('Achievement.isCompleted', () {
    const a = Achievement(
      id: 'dist',
      titleKo: '거리 수집가',
      descKo: '누적 1,000km',
      metric: AchievementMetric.totalDistanceKm,
      goal: 1000,
    );

    test('목표 도달 시 완료다', () {
      expect(a.isCompleted(const UserStats(totalDistanceKm: 1000)), isTrue);
    });

    test('목표 미달 시 미완료다', () {
      expect(a.isCompleted(const UserStats(totalDistanceKm: 999)), isFalse);
    });
  });

  group('Achievement.current (현재 수치 표시용)', () {
    test('현재 진행 수치를 정수로 반환한다 (예: 90/100)', () {
      const a = Achievement(
        id: 'dist',
        titleKo: '거리 수집가',
        descKo: '누적 1,000km',
        metric: AchievementMetric.totalDistanceKm,
        goal: 1000,
      );
      // 화면은 0~100 스케일로 표시 (진행도 × 100)
      final shown = (a.progress(const UserStats(totalDistanceKm: 900)) * 100)
          .round();
      expect(shown, 90);
    });
  });
}
