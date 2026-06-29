import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/passport_filter.dart';
import '../providers/collection_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'city_stamps_screen.dart';

/// 국가별 여권 컬렉션. 대륙 탭 + 국가 카드 그리드.
///
/// MVP는 한국(서울)만 실제 데이터로 동작하고, 나머지 국가는 잠금 카드로
/// 컬렉션의 폭을 보여준다.
class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  late final TextEditingController _searchController;
  int _continent = 0;
  PassportUnlockFilter _unlock = PassportUnlockFilter.all;
  String _query = '';
  static const _continents = ['전체', '아시아', '유럽', '북미', '남미', '오세아니아'];

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
    final unlockedCities = collection.unlockedRegions.isEmpty ? 0 : 1; // 서울
    final countries = _countries(unlockedCities, collection.unlockedCount);

    final filtered = _continent == 0
        ? countries
        : countries
              .where((c) => c.continent == _continents[_continent])
              .toList();
    final searched = PassportFilter(
      unlock: _unlock,
      query: _query,
    ).apply(filtered, itemOf: _countryFilterItem);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Passport',
              style: AppType.serif(size: 30, weight: FontWeight.w800),
            ),
          ),
          _searchField(),
          _continentTabs(),
          _unlockChips(),
          const SizedBox(height: 4),
          Expanded(
            child: searched.isEmpty
                ? _empty()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: _byContinent(searched),
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
          hintText: '여권 검색',
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

  Widget _continentTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _continents.length,
        separatorBuilder: (context, index) => const SizedBox(width: 18),
        itemBuilder: (context, i) {
          final selected = i == _continent;
          return GestureDetector(
            onTap: () => setState(() => _continent = i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _continents[i],
                  style: AppType.sans(
                    size: 14,
                    weight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? AppColors.ink : AppColors.inkFaint,
                  ),
                ),
                const SizedBox(height: 4),
                if (selected)
                  Container(width: 18, height: 2, color: AppColors.ink),
              ],
            ),
          );
        },
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

  List<Widget> _byContinent(List<_Country> countries) {
    final groups = <String, List<_Country>>{};
    for (final c in countries) {
      groups.putIfAbsent(c.continent, () => []).add(c);
    }
    final widgets = <Widget>[];
    groups.forEach((continent, list) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Text(
            continent,
            style: AppType.serif(size: 20, weight: FontWeight.w700),
          ),
        ),
      );
      widgets.add(
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.72,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          children: list.map(_card).toList(),
        ),
      );
    });
    return widgets;
  }

  Widget _empty() {
    return Center(
      child: Text(
        '일치하는 여권이 없어요',
        style: AppType.sans(size: 14, color: AppColors.inkFaint),
      ),
    );
  }

  Widget _card(_Country c) {
    return GestureDetector(
      onTap: c.unlocked
          ? () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CityStampsScreen()))
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: c.unlocked ? c.color : AppColors.paperDim,
          borderRadius: BorderRadius.circular(10),
          boxShadow: c.unlocked
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              c.unlocked ? Icons.location_city : Icons.lock_outline,
              color: c.unlocked
                  ? Colors.white.withValues(alpha: 0.92)
                  : AppColors.inkFaint,
              size: 30,
            ),
            const Spacer(),
            Text(
              c.nameEn,
              style: AppType.serif(
                size: 14,
                weight: FontWeight.w700,
                color: c.unlocked ? Colors.white : AppColors.inkFaint,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              c.nameKo,
              style: AppType.sans(
                size: 11,
                color: c.unlocked
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.inkFaint,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${c.unlockedCount.toString().padLeft(2, '0')}/${c.total}',
              style: AppType.sans(
                size: 11,
                weight: FontWeight.w600,
                color: c.unlocked
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 데모용 국가 목록. 한국만 실제 진행도, 나머지는 잠금.
  List<_Country> _countries(int koreaCities, int koreaRegions) {
    return [
      _Country(
        'Republic of Korea',
        '대한민국',
        '아시아',
        const Color(0xFF2C3E50),
        true,
        koreaRegions,
        467,
      ),
      _Country('Japan', '일본', '아시아', const Color(0xFF7B4B3A), false, 0, 200),
      _Country('Thailand', '태국', '아시아', const Color(0xFF1F6F54), false, 0, 200),
      _Country('France', '프랑스', '유럽', const Color(0xFF34495E), false, 0, 200),
      _Country('Italy', '이탈리아', '유럽', const Color(0xFF6B8E23), false, 0, 200),
      _Country('Egypt', '이집트', '북미', const Color(0xFF2E8B57), false, 0, 200),
      _Country('Malawi', '말라위', '북미', const Color(0xFFB23A2E), false, 0, 200),
      _Country('Nepal', '네팔', '아시아', const Color(0xFF6A3D9A), false, 0, 200),
      _Country('Brazil', '브라질', '남미', const Color(0xFF239B56), false, 0, 200),
      _Country(
        'Australia',
        '호주',
        '오세아니아',
        const Color(0xFF2874A6),
        false,
        0,
        200,
      ),
    ];
  }

  PassportFilterItem _countryFilterItem(_Country c) {
    return PassportFilterItem(
      id: c.nameEn,
      searchableText: '${c.nameEn} ${c.nameKo} ${c.continent}',
      unlocked: c.unlocked,
    );
  }
}

class _Country {
  const _Country(
    this.nameEn,
    this.nameKo,
    this.continent,
    this.color,
    this.unlocked,
    this.unlockedCount,
    this.total,
  );
  final String nameEn;
  final String nameKo;
  final String continent;
  final Color color;
  final bool unlocked;
  final int unlockedCount;
  final int total;
}
