import '../domain/region_shape.dart';

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
    this.about = '',
  });

  final String id;
  final String nameKo;
  final String nameEn;
  final String cityId;
  final String districtKo;
  final String districtEn;
  final RegionShape shape;
  final String about;

  factory RegionMeta.fromJson(Map<String, dynamic> json) {
    final boundary = (json['boundary'] as List)
        .map<List<double>>((p) => [
              (p[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ])
        .toList();
    final bbox =
        (json['bbox'] as List).map<double>((v) => (v as num).toDouble()).toList();
    final id = json['id'].toString();
    return RegionMeta(
      id: id,
      nameKo: json['nameKo'] as String,
      nameEn: json['nameEn'] as String,
      cityId: json['cityId'] as String? ?? 'seoul',
      districtKo: json['districtKo'] as String? ?? '',
      districtEn: json['districtEn'] as String? ?? '',
      about: json['about'] as String? ?? '',
      shape: RegionShape(id: id, boundary: boundary, bbox: bbox),
    );
  }
}
