import '../domain/region_shape.dart';

/// 앱이 사용자에게 정규화해서 보여주는 지역 계층.
enum RegionLevel { country, region, city, district, neighborhood }

/// 원자료가 표현하는 실제 행정/생활권 타입.
enum RegionKind {
  country,
  province,
  state,
  metroCity,
  city,
  district,
  gu,
  dong,
  eup,
  myeon,
  locality,
  neighborhood,
}

/// 지역의 불변 메타데이터(이름/구/도시) + 경계 도형.
///
/// assets GeoJSON에서 로드되며 변하지 않는다. 사용자 진행 상태(해금/방문)는
/// [RegionProgress]에 별도로 저장되고 regionId로 연결된다.
class RegionMeta {
  RegionMeta({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.cityId,
    required this.districtKo,
    required this.districtEn,
    required this.shape,
    required this.parentId,
    required this.countryId,
    required this.level,
    required this.kind,
    required this.localName,
    required this.dataPackId,
    required this.hierarchyPath,
    this.about = '',
  });

  final String id;
  final String nameKo;
  final String nameEn;
  final String cityId;
  final String districtKo;
  final String districtEn;
  final RegionShape shape;
  final String parentId;
  final String countryId;
  final RegionLevel level;
  final RegionKind kind;
  final String localName;
  final String dataPackId;
  final List<String> hierarchyPath;
  final String about;

  factory RegionMeta.fromJson(Map<String, dynamic> json) {
    final boundary = (json['boundary'] as List)
        .map<List<double>>(
          (p) => [(p[0] as num).toDouble(), (p[1] as num).toDouble()],
        )
        .toList();
    final bbox = (json['bbox'] as List)
        .map<double>((v) => (v as num).toDouble())
        .toList();
    final id = json['id'].toString();
    final nameKo = json['nameKo'] as String;
    final cityId = json['cityId'] as String? ?? 'seoul';
    final districtKo = json['districtKo'] as String? ?? '';
    final districtEn = json['districtEn'] as String? ?? '';
    final parentId =
        json['parentId'] as String? ?? _defaultParentId(cityId, districtEn);
    final countryId = json['countryId'] as String? ?? 'kr';
    final dataPackId = json['dataPackId'] as String? ?? '$countryId-$cityId';
    return RegionMeta(
      id: id,
      nameKo: nameKo,
      nameEn: json['nameEn'] as String,
      cityId: cityId,
      districtKo: districtKo,
      districtEn: districtEn,
      parentId: parentId,
      countryId: countryId,
      level: _parseLevel(json['level'] as String?),
      kind: _parseKind(json['kind'] as String?),
      localName: json['localName'] as String? ?? nameKo,
      dataPackId: dataPackId,
      hierarchyPath: _parseHierarchyPath(
        json['hierarchyPath'],
        countryId: countryId,
        cityId: cityId,
        parentId: parentId,
        id: id,
      ),
      about: json['about'] as String? ?? '',
      shape: RegionShape(id: id, boundary: boundary, bbox: bbox),
    );
  }

  static String _defaultParentId(String cityId, String districtEn) {
    final district = districtEn.trim().isEmpty ? 'district' : districtEn;
    final slug = district
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return '$cityId-${slug.isEmpty ? 'district' : slug}';
  }

  static RegionLevel _parseLevel(String? value) {
    for (final level in RegionLevel.values) {
      if (level.name == value) return level;
    }
    return RegionLevel.neighborhood;
  }

  static RegionKind _parseKind(String? value) {
    for (final kind in RegionKind.values) {
      if (kind.name == value) return kind;
    }
    return RegionKind.dong;
  }

  static List<String> _parseHierarchyPath(
    Object? value, {
    required String countryId,
    required String cityId,
    required String parentId,
    required String id,
  }) {
    if (value is List) {
      return value.map((v) => v.toString()).toList(growable: false);
    }
    return [countryId, cityId, parentId, id];
  }
}
