import 'package:hive/hive.dart';

part 'region_progress.g.dart';

/// 지역별 사용자 진행 상태(가변). 지역의 이름/경계 같은 불변 메타는
/// assets GeoJSON에 있고, 여기엔 사용자가 만들어낸 사실만 저장한다.
///
/// regionId로 [RegionShape]/메타와 연결된다. 클리어 %는 방문 셀과 경계로
/// 실시간 계산하므로 저장하지 않는다.
@HiveType(typeId: 3)
class RegionProgress extends HiveObject {
  RegionProgress({
    required this.regionId,
    required this.unlockedAt,
    this.visitCount = 1,
  });

  @HiveField(0)
  final String regionId;

  /// 최초 해금 시각.
  @HiveField(1)
  final DateTime unlockedAt;

  /// 방문 횟수(별개의 산책 세션에서 이 지역을 지난 횟수).
  @HiveField(2)
  int visitCount;
}
