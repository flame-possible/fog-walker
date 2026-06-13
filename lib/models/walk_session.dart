import 'package:hive/hive.dart';

part 'walk_session.g.dart';

/// 이동 수단. 업적 분류(걷기/자전거/수영/하이킹)에 쓰인다.
@HiveType(typeId: 1)
enum WalkMode {
  @HiveField(0)
  walk,
  @HiveField(1)
  bike,
  @HiveField(2)
  swim,
  @HiveField(3)
  hike,
}

/// 한 번의 산책 기록. 끝난 산책만 저장한다(사실).
///
/// 총 거리·연속일·This Week 같은 통계는 이 기록들을 집계해 파생하므로
/// 따로 저장하지 않는다.
@HiveType(typeId: 0)
class WalkSession extends HiveObject {
  WalkSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.clearedKm2,
    required this.newCellsCount,
    required this.regionIds,
    this.mode = WalkMode.walk,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startedAt;

  @HiveField(2)
  final DateTime endedAt;

  /// 이번 산책 동안 이동한 거리(km).
  @HiveField(3)
  final double distanceKm;

  /// 이번 산책으로 새로 걷어낸 안개 면적(km²).
  @HiveField(4)
  final double clearedKm2;

  /// 이번 산책에서 새로 발견한 셀 수.
  @HiveField(5)
  final int newCellsCount;

  /// 지나간 지역 id들.
  @HiveField(6)
  final List<String> regionIds;

  @HiveField(7)
  final WalkMode mode;

  Duration get duration => endedAt.difference(startedAt);
}
