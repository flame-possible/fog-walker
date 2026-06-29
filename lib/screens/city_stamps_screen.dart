import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/region_meta.dart';
import '../domain/passport_filter.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/stamp_widget.dart';
import 'region_detail_screen.dart';

/// 한 도시(서울)의 도장 컬렉션. 도장들이 자유롭게 흩뿌려진 레이아웃.
///
/// 해금한 지역은 선명한 도장, 미해금은 흐린 도장으로 섞어 컬렉션의 깊이를
/// 보여준다. 도장을 탭하면 지역 상세로 이동.
class CityStampsScreen extends StatefulWidget {
  const CityStampsScreen({super.key});

  @override
  State<CityStampsScreen> createState() => _CityStampsScreenState();
}

class _CityStampsScreenState extends State<CityStampsScreen> {
  late final TextEditingController _searchController;
  PassportUnlockFilter _unlock = PassportUnlockFilter.all;
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
    final collection = context.watch<CollectionProvider>();
    final stamps = _selectStamps(collection, query: _query, unlock: _unlock);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
              child: Text(
                'South Korea',
                style: AppType.serif(size: 30, weight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'All Cities',
                    style: AppType.sans(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.inkSoft,
                  ),
                ],
              ),
            ),
            _searchField(),
            _unlockChips(),
            Expanded(child: _scatter(context, stamps)),
            _pageDots(stamps.length),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        style: AppType.sans(size: 14, color: AppColors.ink),
        decoration: InputDecoration(
          isDense: true,
          hintText: '도장 검색',
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

  Widget _unlockChips() {
    const filters = [
      (PassportUnlockFilter.all, '전체'),
      (PassportUnlockFilter.unlocked, '획득'),
      (PassportUnlockFilter.locked, '미획득'),
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
          final selected = item.$1 == _unlock;
          return ChoiceChip(
            label: Text(item.$2),
            selected: selected,
            onSelected: (_) => setState(() => _unlock = item.$1),
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

  /// 도장 흩뿌리기. 의사난수로 위치/회전을 정해 자연스럽게 배치.
  Widget _scatter(BuildContext context, List<_StampData> stamps) {
    if (stamps.isEmpty) {
      return Center(
        child: Text(
          '일치하는 도장이 없어요',
          style: AppType.sans(size: 14, color: AppColors.inkFaint),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final rnd = math.Random(42);
        final children = <Widget>[];

        // 화면을 격자로 나눠 겹침을 줄이면서 각 칸 안에서 흔든다.
        const cols = 2;
        final rows = (stamps.length / cols).ceil();
        final cellW = w / cols;
        final cellH = h / rows;

        for (int i = 0; i < stamps.length; i++) {
          final s = stamps[i];
          final col = i % cols;
          final row = i ~/ cols;
          final jitterX = (rnd.nextDouble() - 0.5) * cellW * 0.3;
          final jitterY = (rnd.nextDouble() - 0.5) * cellH * 0.3;
          final size = cellW * (0.62 + rnd.nextDouble() * 0.12);
          final rot = (rnd.nextDouble() - 0.5) * 0.5; // ±0.25 rad

          final left = col * cellW + (cellW - size) / 2 + jitterX;
          final top = row * cellH + (cellH - size) / 2 + jitterY;

          children.add(
            Positioned(
              left: left.clamp(0, w - size),
              top: top.clamp(0, h - size),
              child: Transform.rotate(
                angle: rot,
                child: GestureDetector(
                  onTap: s.meta == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RegionDetailScreen(regionId: s.meta!.id),
                          ),
                        ),
                  child: StampWidget(
                    size: size,
                    topText: s.topText,
                    bottomText: s.bottomText,
                    color: s.color,
                    locked: s.locked,
                    seed: i,
                  ),
                ),
              ),
            ),
          );
        }
        return Stack(children: children);
      },
    );
  }

  Widget _pageDots(int count) {
    final dots = math.min(count, 10);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dots, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == 0 ? 7 : 5,
          height: i == 0 ? 7 : 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == 0 ? AppColors.ink : AppColors.line,
          ),
        );
      }),
    );
  }

  /// 화면에 보일 도장 8개 선택: 해금된 것 우선, 부족하면 대표 동으로 채움.
  List<_StampData> _selectStamps(
    CollectionProvider collection, {
    required String query,
    required PassportUnlockFilter unlock,
  }) {
    final searching =
        query.trim().isNotEmpty || unlock != PassportUnlockFilter.all;
    if (searching) {
      return _searchStamps(collection, query: query, unlock: unlock);
    }

    final result = <_StampData>[];

    // 항상 보이는 시그니처 도장 2개 (한강, 서울)
    result.add(
      _StampData(
        id: 'hangang',
        topText: 'HANGANG',
        bottomText: '한강',
        color: AppColors.stampPalette[1],
        locked: false,
        meta: null,
      ),
    );
    result.add(
      _StampData(
        id: 'seoul',
        topText: 'SEOUL',
        bottomText: '서울특별시',
        color: AppColors.stampPalette[0],
        locked: false,
        meta: null,
      ),
    );

    // 해금된 지역 도장
    final unlocked = collection.unlockedRegions;
    for (final r in unlocked.take(6)) {
      result.add(_stampOf(r, false, result.length));
    }

    // 미해금이면 대표 동 몇 개를 흐리게 채워 컬렉션 느낌
    if (result.length < 8) {
      final locked = collection.allRegions
          .where((r) => !collection.isUnlocked(r.id))
          .take(8 - result.length);
      for (final r in locked) {
        result.add(_stampOf(r, true, result.length));
      }
    }
    return result;
  }

  List<_StampData> _searchStamps(
    CollectionProvider collection, {
    required String query,
    required PassportUnlockFilter unlock,
  }) {
    final regionStamps = collection.allRegions.map((region) {
      final unlocked = collection.isUnlocked(region.id);
      return _stampOf(region, !unlocked, region.id.hashCode);
    }).toList();

    return PassportFilter(unlock: unlock, query: query)
        .apply(regionStamps, itemOf: _stampFilterItem)
        .take(12)
        .toList(growable: false);
  }

  _StampData _stampOf(RegionMeta r, bool locked, int idx) {
    return _StampData(
      id: r.id,
      topText: r.nameEn.split('-').first.toUpperCase(),
      bottomText: r.nameKo,
      color: AppColors.stampPalette[idx.abs() % AppColors.stampPalette.length],
      locked: locked,
      meta: r,
    );
  }

  PassportFilterItem _stampFilterItem(_StampData stamp) {
    final meta = stamp.meta;
    final text = meta == null
        ? '${stamp.topText} ${stamp.bottomText}'
        : '${meta.nameKo} ${meta.nameEn} ${meta.districtKo} ${meta.districtEn}';
    return PassportFilterItem(
      id: stamp.id,
      searchableText: text,
      unlocked: !stamp.locked,
    );
  }
}

class _StampData {
  _StampData({
    required this.id,
    required this.topText,
    required this.bottomText,
    required this.color,
    required this.locked,
    required this.meta,
  });
  final String id;
  final String topText;
  final String bottomText;
  final Color color;
  final bool locked;
  final RegionMeta? meta;
}
