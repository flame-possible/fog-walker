import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/achievement.dart';
import '../models/walk_session.dart';
import '../providers/collection_provider.dart';
import '../providers/walk_session_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/progress_bar.dart';
import '../widgets/stamp_widget.dart';

/// 업적 화면. 전체/진행중/완료 탭 + 진행도 카드.
class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  int _tab = 0;
  static const _tabs = ['전체', '진행 중', '완료'];

  @override
  Widget build(BuildContext context) {
    final walk = context.watch<WalkSessionProvider>();
    final collection = context.watch<CollectionProvider>();
    final stats = _buildStats(walk, collection);

    final all = CollectionProvider.catalog;
    final filtered = all.where((a) {
      final done = a.isCompleted(stats);
      if (_tab == 1) return !done;
      if (_tab == 2) return done;
      return true;
    }).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Achievement',
              style: AppType.serif(size: 30, weight: FontWeight.w800),
            ),
          ),
          _tabBar(),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) => _card(filtered[i], stats),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = i == _tab;
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Column(
                children: [
                  Text(
                    _tabs[i],
                    style: AppType.sans(
                      size: 15,
                      weight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? AppColors.ink : AppColors.inkFaint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (selected)
                    Container(width: 20, height: 2, color: AppColors.ink),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _card(Achievement a, UserStats stats) {
    final progress = a.progress(stats);
    final shown = (progress * 100).round();
    final color = a.metric.toString().contains('bike')
        ? AppColors.stampPalette[1]
        : AppColors.stampRed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StampWidget(
            size: 56,
            topText: a.titleKo.characters.take(1).toString(),
            bottomText: '',
            color: a.isCompleted(stats)
                ? AppColors.stampRed
                : AppColors.inkFaint.withValues(alpha: 0.6),
            seed: a.id.hashCode,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.titleKo,
                  style: AppType.sans(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.descKo,
                  style: AppType.sans(size: 12, color: AppColors.inkFaint),
                ),
                const SizedBox(height: 10),
                ThinProgressBar(value: progress, color: color),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$shown/100',
              style: AppType.sans(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 화면에 필요한 사용자 통계를 Provider들에서 조립.
  UserStats _buildStats(
    WalkSessionProvider walk,
    CollectionProvider collection,
  ) {
    return UserStats(
      streakDays: walk.streakDays,
      regionsUnlocked: collection.unlockedCount,
      totalDistanceKm: walk.totalDistanceKm,
      bikeDistanceKm: walk.distanceByMode(WalkMode.bike),
      swimDistanceKm: walk.distanceByMode(WalkMode.swim),
      hikeDistanceKm: walk.distanceByMode(WalkMode.hike),
    );
  }
}
