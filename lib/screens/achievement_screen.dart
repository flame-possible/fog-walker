import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/achievement.dart';
import '../domain/achievement_filter.dart';
import '../providers/collection_provider.dart';
import '../providers/fog_provider.dart';
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
  late final TextEditingController _searchController;
  AchievementStatusFilter _status = AchievementStatusFilter.all;
  AchievementTypeFilter _type = AchievementTypeFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walk = context.watch<WalkSessionProvider>();
    final collection = context.watch<CollectionProvider>();
    final fog = context.watch<FogProvider>();
    final stats = _buildStats(walk, collection, fog);

    final all = CollectionProvider.catalog;
    final filtered = AchievementFilter(
      status: _status,
      type: _type,
      query: _query,
    ).apply(all, stats);

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
          _searchField(),
          _statusTabs(),
          _typeChips(),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, i) => _card(filtered[i], stats),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        style: AppType.sans(size: 14, color: AppColors.ink),
        decoration: InputDecoration(
          isDense: true,
          hintText: '업적 검색',
          hintStyle: AppType.sans(size: 14, color: AppColors.inkFaint),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: '검색 지우기',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.ink),
          ),
        ),
      ),
    );
  }

  Widget _statusTabs() {
    const tabs = [
      (AchievementStatusFilter.all, '전체'),
      (AchievementStatusFilter.inProgress, '진행 중'),
      (AchievementStatusFilter.completed, '완료'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final item = tabs[i];
          final selected = item.$1 == _status;
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => setState(() => _status = item.$1),
              child: Column(
                children: [
                  Text(
                    item.$2,
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

  Widget _typeChips() {
    const filters = [
      (AchievementTypeFilter.all, '전체'),
      (AchievementTypeFilter.streak, '연속'),
      (AchievementTypeFilter.region, '지역'),
      (AchievementTypeFilter.distance, '거리'),
      (AchievementTypeFilter.area, '면적'),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final selected = item.$1 == _type;
          return ChoiceChip(
            label: Text(item.$2),
            selected: selected,
            onSelected: (_) => setState(() => _type = item.$1),
            labelStyle: AppType.sans(
              size: 12,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
            selectedColor: AppColors.ink,
            backgroundColor: Colors.white.withValues(alpha: 0.72),
            side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _card(Achievement a, UserStats stats) {
    final progress = a.progress(stats);
    final shown = (progress * 100).round();
    final color = switch (a.category) {
      AchievementCategory.streak => AppColors.stampPalette[0],
      AchievementCategory.region => AppColors.stampPalette[2],
      AchievementCategory.distance => AppColors.stampPalette[1],
      AchievementCategory.area => AppColors.stampPalette[4],
    };

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

  Widget _empty() {
    return Center(
      child: Text(
        '일치하는 업적이 없어요',
        style: AppType.sans(size: 14, color: AppColors.inkFaint),
      ),
    );
  }

  /// 화면에 필요한 사용자 통계를 Provider들에서 조립.
  UserStats _buildStats(
    WalkSessionProvider walk,
    CollectionProvider collection,
    FogProvider fog,
  ) {
    return UserStats(
      streakDays: walk.streakDays,
      regionsUnlocked: collection.unlockedCount,
      totalDistanceKm: walk.totalDistanceKm,
      totalClearedKm2: fog.totalAreaKm2,
    );
  }
}
