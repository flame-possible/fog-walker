import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/data/region_meta.dart';

void main() {
  group('RegionMeta hierarchy fields', () {
    test('legacy Seoul JSON defaults to neighborhood hierarchy', () {
      final meta = RegionMeta.fromJson({
        'id': '1111053000',
        'nameKo': '사직동',
        'nameEn': 'Sajik-dong',
        'cityId': 'seoul',
        'districtKo': '종로구',
        'districtEn': 'Jongno-gu',
        'boundary': [
          [126.97, 37.57],
          [126.98, 37.57],
          [126.98, 37.58],
          [126.97, 37.58],
          [126.97, 37.57],
        ],
        'bbox': [126.97, 37.57, 126.98, 37.58],
      });

      expect(meta.countryId, 'kr');
      expect(meta.parentId, 'seoul-jongno-gu');
      expect(meta.level, RegionLevel.neighborhood);
      expect(meta.kind, RegionKind.dong);
      expect(meta.localName, '사직동');
      expect(meta.dataPackId, 'kr-seoul');
      expect(meta.hierarchyPath, [
        'kr',
        'seoul',
        'seoul-jongno-gu',
        '1111053000',
      ]);
    });

    test('explicit data-pack hierarchy fields are preserved', () {
      final meta = RegionMeta.fromJson({
        'id': 'jp-tokyo-shibuya-ebisu',
        'parentId': 'jp-tokyo-shibuya',
        'countryId': 'jp',
        'cityId': 'tokyo',
        'level': 'neighborhood',
        'kind': 'locality',
        'nameKo': '에비스',
        'nameEn': 'Ebisu',
        'localName': '恵比寿',
        'districtKo': '시부야구',
        'districtEn': 'Shibuya City',
        'dataPackId': 'jp-tokyo',
        'hierarchyPath': [
          'jp',
          'jp-tokyo',
          'jp-tokyo-shibuya',
          'jp-tokyo-shibuya-ebisu',
        ],
        'boundary': [
          [139.70, 35.64],
          [139.71, 35.64],
          [139.71, 35.65],
          [139.70, 35.65],
          [139.70, 35.64],
        ],
        'bbox': [139.70, 35.64, 139.71, 35.65],
      });

      expect(meta.countryId, 'jp');
      expect(meta.parentId, 'jp-tokyo-shibuya');
      expect(meta.kind, RegionKind.locality);
      expect(meta.localName, '恵比寿');
      expect(meta.dataPackId, 'jp-tokyo');
      expect(meta.hierarchyPath, [
        'jp',
        'jp-tokyo',
        'jp-tokyo-shibuya',
        'jp-tokyo-shibuya-ebisu',
      ]);
    });
  });
}
