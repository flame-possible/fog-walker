import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../data/region_meta.dart';
import '../models/region_progress.dart';
import '../models/walk_session.dart';
import '../providers/collection_provider.dart';
import '../providers/fog_provider.dart';
import '../providers/walk_session_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/stamp_widget.dart';

/// 지역(동) 상세. 큰 도장 + 통계 + About + 미니지도 + 방문 기록.
class RegionDetailScreen extends StatelessWidget {
  const RegionDetailScreen({super.key, required this.regionId});

  final String regionId;

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final fog = context.watch<FogProvider>();
    final walk = context.watch<WalkSessionProvider>();

    final meta = collection.repository.byId[regionId];
    if (meta == null) {
      return const Scaffold(body: Center(child: Text('지역을 찾을 수 없습니다')));
    }

    final progress = collection.progressOf(regionId);
    final pct = collection.clearPercentOf(regionId, fog.visitedCells);
    final visits = walk.sessionsInRegion(regionId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const SizedBox(height: 8),
          Center(
            child: StampWidget(
              size: 150,
              topText: meta.districtEn.isNotEmpty
                  ? meta.districtEn.split('-').first.toUpperCase()
                  : 'SEOUL',
              bottomText: meta.districtKo.isNotEmpty ? meta.districtKo : '서울',
              color: AppColors.stampRed,
              locked: progress == null,
              seed: regionId.hashCode,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              meta.nameKo,
              style: AppType.serif(size: 28, weight: FontWeight.w800),
            ),
          ),
          Center(
            child: Text(
              meta.nameEn,
              style: AppType.sans(size: 15, color: AppColors.inkFaint),
            ),
          ),
          const SizedBox(height: 24),
          _statsRow(progress, pct),
          const SizedBox(height: 24),
          _sectionTitle('About'),
          const SizedBox(height: 8),
          Text(
            meta.about,
            style: AppType.sans(
              size: 14,
              color: AppColors.inkSoft,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Location'),
          const SizedBox(height: 8),
          _miniMap(meta, fog),
          const SizedBox(height: 24),
          _sectionTitle('Visits'),
          const SizedBox(height: 4),
          if (visits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '아직 이 지역의 산책 기록이 없어요.',
                style: AppType.sans(size: 13, color: AppColors.inkFaint),
              ),
            )
          else
            ...visits.map(_visitRow),
        ],
      ),
    );
  }

  Widget _statsRow(RegionProgress? progress, double pct) {
    final unlockText = progress != null ? _fmtDate(progress.unlockedAt) : '미해금';
    final visitText = progress != null ? '${progress.visitCount}회' : '0회';
    return Row(
      children: [
        Expanded(child: _stat('해금일', unlockText)),
        _divider(),
        Expanded(child: _stat('방문 횟수', visitText)),
        _divider(),
        Expanded(child: _stat('안개 클리어', '${pct.toStringAsFixed(0)}%')),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppType.sans(size: 12, color: AppColors.inkFaint)),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppType.sans(
            size: 16,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.line);

  Widget _sectionTitle(String t) =>
      Text(t, style: AppType.serif(size: 20, weight: FontWeight.w700));

  Widget _miniMap(RegionMeta meta, FogProvider fog) {
    final pts = meta.shape.boundary.map((p) => LatLng(p[1], p[0])).toList();
    final center = LatLng(
      (meta.shape.minLat + meta.shape.maxLat) / 2,
      (meta.shape.minLng + meta.shape.maxLng) / 2,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fogwalker.app',
            ),
            PolygonLayer(
              polygons: [
                Polygon(
                  points: pts,
                  color: AppColors.stampRed.withValues(alpha: 0.18),
                  borderColor: AppColors.stampRed,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _visitRow(WalkSession session) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _fmtDate(session.startedAt),
            style: AppType.sans(
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          Text(
            '${session.distanceKm.toStringAsFixed(1)}km · '
            '${session.duration.inMinutes}분',
            style: AppType.sans(size: 13, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.'
      '${d.day.toString().padLeft(2, '0')}';
}
