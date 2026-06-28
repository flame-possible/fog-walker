import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/walk_stats.dart';
import '../providers/collection_provider.dart';
import '../providers/fog_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/walk_session_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/passport_card.dart';

/// My Information 화면. 여권 카드 + 통계 + 기록.
class MyInfoScreen extends StatelessWidget {
  const MyInfoScreen({super.key});

  /// 축구장 1면 ≈ 7,140 m² = 0.00714 km².
  static const double _soccerFieldKm2 = 0.00714;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final fog = context.watch<FogProvider>();
    final walk = context.watch<WalkSessionProvider>();
    final collection = context.watch<CollectionProvider>();

    final area = fog.totalAreaKm2;
    final weekly = walk.weekly;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'My Information',
            style: AppType.serif(size: 30, weight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          PassportCard(profile: profile),
          const SizedBox(height: 28),
          _sectionTitle('Stats'),
          const SizedBox(height: 10),
          Text(
            '걸어낸 안개',
            style: AppType.sans(size: 13, color: AppColors.inkFaint),
          ),
          const SizedBox(height: 2),
          Text(
            _areaText(area),
            style: AppType.serif(size: 40, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _soccerText(area),
            style: AppType.sans(size: 13, color: AppColors.inkFaint),
          ),
          const SizedBox(height: 28),
          _sectionTitle('Records'),
          const SizedBox(height: 12),
          _weeklyCard(weekly),
          const SizedBox(height: 20),
          _statRow('도장', '${collection.unlockedCount}'),
          _statRow(
            '국가',
            '${collection.unlockedCountryCount} / ${collection.countryCount}',
          ),
          _statRow('총 거리', '${walk.totalDistanceKm.toStringAsFixed(1)} km'),
          _statRow('가장 긴 산책', '${walk.longestWalkKm.toStringAsFixed(1)} km'),
          _statRow('연속 산책', '${walk.streakDays} 일'),
          _statRow('자주 가는 곳', _favorite(collection)),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => _showAllRecords(context, walk),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '전체 기록 보기',
                    style: AppType.sans(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.ink,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) =>
      Text(t, style: AppType.serif(size: 22, weight: FontWeight.w700));

  /// 면적을 크기에 맞춰 포맷 (작으면 m², 크면 km²).
  String _areaText(double km2) {
    if (km2 >= 1) return '${km2.toStringAsFixed(1)} km²';
    final m2 = km2 * 1e6;
    if (m2 >= 1000) return '${(m2 / 1000).toStringAsFixed(2)} km²';
    return '${m2.toStringAsFixed(0)} m²';
  }

  String _soccerText(double km2) {
    final fields = km2 / _soccerFieldKm2;
    if (fields < 0.1) return '아직 안개를 걷는 중이에요';
    if (fields < 1) return '축구장 약 ${(fields * 100).toStringAsFixed(0)}% 면적';
    return '축구장 약 ${fields.toStringAsFixed(0)}개 면적';
  }

  Widget _weeklyCard(WeeklySummary w) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.passportGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: AppType.sans(size: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 4),
          Text(
            '+${(w.clearedKm2 * 1e6 / 1000).toStringAsFixed(1)}k m²',
            style: AppType.serif(size: 34, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${w.sessionCount}회 산책 · ${w.distanceKm.toStringAsFixed(1)} km · '
            '${w.newCells}칸 발견',
            style: AppType.sans(size: 13, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppType.sans(size: 14, color: AppColors.inkSoft)),
          Text(
            value,
            style: AppType.sans(
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  String _favorite(CollectionProvider collection) {
    // 방문 횟수가 가장 많은 해금 지역
    final unlocked = collection.unlockedRegions;
    if (unlocked.isEmpty) return '-';
    RegionMetaCount? best;
    DateTime? newestUnlock;
    String? newestName;
    for (final r in unlocked) {
      final p = collection.progressOf(r.id);
      final count = p?.visitCount ?? 0;
      if (best == null || count > best.count) {
        best = RegionMetaCount(r.nameKo, count);
      }
      final unlockedAt = p?.unlockedAt;
      if (unlockedAt != null &&
          (newestUnlock == null || unlockedAt.isAfter(newestUnlock))) {
        newestUnlock = unlockedAt;
        newestName = r.nameKo;
      }
    }
    if (best != null && best.count > 0) return best.name;
    return newestName ?? unlocked.first.nameKo;
  }

  void _showAllRecords(BuildContext context, WalkSessionProvider walk) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (context) {
        final sessions = walk.sessions;
        if (sessions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('아직 산책 기록이 없어요.')),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final s = sessions[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.startedAt.year}.${s.startedAt.month.toString().padLeft(2, '0')}.${s.startedAt.day.toString().padLeft(2, '0')}',
                    style: AppType.sans(size: 14, weight: FontWeight.w600),
                  ),
                  Text(
                    '${s.distanceKm.toStringAsFixed(1)}km · ${s.duration.inMinutes}분',
                    style: AppType.sans(size: 13, color: AppColors.inkFaint),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class RegionMetaCount {
  RegionMetaCount(this.name, this.count);
  final String name;
  final int count;
}
