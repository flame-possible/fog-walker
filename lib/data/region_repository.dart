import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/region_matcher.dart';
import 'region_meta.dart';

/// 도시 정보(서울 등).
class CityInfo {
  CityInfo({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.countryId,
  });

  final String id;
  final String nameKo;
  final String nameEn;
  final String countryId;

  factory CityInfo.fromJson(Map<String, dynamic> json) => CityInfo(
    id: json['id'] as String,
    nameKo: json['nameKo'] as String,
    nameEn: json['nameEn'] as String,
    countryId: json['countryId'] as String,
  );
}

/// assets GeoJSON에서 지역 메타/도형을 로드한다.
///
/// 앱 구동의 토대. 파싱 실패 시 빈 목록을 반환해 앱이 죽지 않게 한다
/// (지도는 여전히 동작).
class RegionRepository {
  RegionRepository._({
    required this.city,
    required this.regions,
    required this.matcher,
  });

  final CityInfo city;
  final List<RegionMeta> regions;
  final RegionMatcher matcher;

  Map<String, RegionMeta> get byId => {for (final r in regions) r.id: r};
  String get countryNameKo =>
      city.countryId == 'kr' ? '대한민국' : city.countryId.toUpperCase();
  String get dataPackId =>
      regions.isEmpty ? 'kr-seoul' : regions.first.dataPackId;

  static const _assetPath = 'assets/data/seoul_dong.geojson';

  /// assets에서 로드. 실패해도 예외를 던지지 않고 빈 저장소를 만든다.
  static Future<RegionRepository> load() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final city = CityInfo.fromJson(json['city'] as Map<String, dynamic>);
      final regions = (json['regions'] as List)
          .map((r) => RegionMeta.fromJson(r as Map<String, dynamic>))
          .map(_withAbout)
          .toList();
      final matcher = RegionMatcher(regions.map((r) => r.shape).toList());
      return RegionRepository._(city: city, regions: regions, matcher: matcher);
    } catch (_) {
      // 파싱 실패 시 빈 저장소 — 앱은 계속 구동된다.
      final empty = CityInfo(
        id: 'seoul',
        nameKo: '서울특별시',
        nameEn: 'Seoul',
        countryId: 'kr',
      );
      return RegionRepository._(
        city: empty,
        regions: const [],
        matcher: RegionMatcher(const []),
      );
    }
  }

  /// About 텍스트 보강. 잘 알려진 동은 실제 설명, 나머지는 구 기반 기본 문구.
  static RegionMeta _withAbout(RegionMeta r) {
    final known = _aboutByDong[r.nameKo];
    final about = known ?? '서울 ${r.districtKo}에 속한 동네. 골목을 따라 걸으며 안개를 걷어내 보세요.';
    return RegionMeta(
      id: r.id,
      nameKo: r.nameKo,
      nameEn: r.nameEn,
      cityId: r.cityId,
      districtKo: r.districtKo,
      districtEn: r.districtEn,
      shape: r.shape,
      parentId: r.parentId,
      countryId: r.countryId,
      level: r.level,
      kind: r.kind,
      localName: r.localName,
      dataPackId: r.dataPackId,
      hierarchyPath: r.hierarchyPath,
      about: about,
    );
  }

  static const Map<String, String> _aboutByDong = {
    '한남동': '서울 용산구의 외국인 거주 지역으로 잘 알려진 곳. 이국적인 식당과 카페가 골목을 따라 펼쳐져 있어 걷기 좋은 동네.',
    '이태원동': '다양한 문화가 섞인 서울의 대표 거리. 언덕을 오르내리며 만나는 풍경이 매 골목 다르다.',
    '삼청동': '경복궁 동편의 고즈넉한 한옥과 갤러리가 어우러진 길. 천천히 걷기에 어울린다.',
    '연남동': '경의선 숲길을 따라 카페와 상점이 늘어선 마포의 산책 명소.',
    '성수동': '옛 공장이 카페와 작업실로 바뀐 거리. 걸을수록 새로운 가게가 나타난다.',
    '서교동': '홍대 일대의 활기찬 거리. 골목마다 음악과 사람으로 가득하다.',
  };
}
