import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/domain/passport_filter.dart';

void main() {
  group('PassportFilter', () {
    const items = [
      PassportFilterItem(
        id: 'kr',
        searchableText: 'Republic of Korea 대한민국 Asia Seoul',
        unlocked: true,
      ),
      PassportFilterItem(
        id: 'jp',
        searchableText: 'Japan 일본 Asia Tokyo',
        unlocked: false,
      ),
      PassportFilterItem(
        id: 'fr',
        searchableText: 'France 프랑스 Europe Paris',
        unlocked: false,
      ),
    ];

    test('filters unlocked items', () {
      final result = const PassportFilter(
        unlock: PassportUnlockFilter.unlocked,
      ).apply(items);

      expect(result.map((item) => item.id), ['kr']);
    });

    test('filters locked items', () {
      final result = const PassportFilter(
        unlock: PassportUnlockFilter.locked,
      ).apply(items);

      expect(result.map((item) => item.id), ['jp', 'fr']);
    });

    test('searches Korean and English text', () {
      final result = const PassportFilter(query: '프랑').apply(items);

      expect(result.map((item) => item.id), ['fr']);
    });
  });
}
