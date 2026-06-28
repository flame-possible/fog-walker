import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/fog_repository.dart';
import '../domain/area_calculator.dart';
import '../domain/fog_grid.dart';
import '../domain/location_update_policy.dart';

/// 한 위치 이벤트를 안개 엔진에 적용한 결과.
class FogUpdate {
  const FogUpdate({required this.accepted, required this.freshCells});

  final bool accepted;
  final Set<(int, int)> freshCells;

  static const ignored = FogUpdate(accepted: false, freshCells: <(int, int)>{});
}

/// 안개의 단일 진실 공급원.
///
/// 위치를 받아 주변 셀을 "걷어내고"(visitedCells에 추가), 면적을 파생한다.
/// GPS 노이즈(정확도 불량·순간이동)는 여기서 걸러낸다. 영속화는 선택적
/// [FogRepository]에 위임하며, 없으면 메모리만 사용한다(테스트 용이).
class FogProvider extends ChangeNotifier {
  FogProvider({FogRepository? repository}) : _repo = repository;

  final FogRepository? _repo;

  /// 걷어낸 영역(방문 셀). 외부엔 읽기 전용 뷰로 노출.
  final Set<(int, int)> _visited = {};
  Set<(int, int)> get visitedCells => _visited;

  /// 직전 위치 — 순간이동 판정용.
  LatLng? _lastPoint;

  /// 새 셀이 추가됐을 때 호출 (해금 판정·세션 누적용). 추가된 셀만 전달.
  void Function(Set<(int, int)> newCells)? onNewCells;

  /// 걷어낼 반경(미터).
  static const double clearRadiusMeters = 30;

  /// 이 정확도(미터)보다 나쁜 신호는 무시.
  static const double maxAccuracyMeters =
      LocationUpdatePolicy.maxFogAccuracyMeters;

  /// 두 위치 이벤트 사이 이 거리(미터)를 넘으면 순간이동으로 보고 무시.
  static const double teleportThresholdMeters = 1000;

  static const Distance _distance = Distance();

  /// 저장된 방문 셀로 초기 상태를 채운다(앱 시작 시).
  void loadInitial(Set<(int, int)> cells) {
    _visited
      ..clear()
      ..addAll(cells);
    notifyListeners();
  }

  /// 새 위치 처리. 노이즈를 거른 뒤 주변 셀을 걷어내고 처리 결과를 반환한다.
  FogUpdate onLocation(LatLng point, {required double accuracy}) {
    // 1) 정확도 필터
    if (!LocationUpdatePolicy.canClearFog(accuracy: accuracy)) {
      return FogUpdate.ignored;
    }

    // 2) 순간이동 필터
    final last = _lastPoint;
    if (last != null && _distance(last, point) > teleportThresholdMeters) {
      return FogUpdate.ignored;
    }
    _lastPoint = point;

    // 3) 반경 안의 셀들 중 새로운 것만 추가
    final candidate = FogGrid.cellsWithinRadius(point, clearRadiusMeters);
    final fresh = <(int, int)>{};
    for (final c in candidate) {
      if (_visited.add(c)) fresh.add(c);
    }
    if (fresh.isEmpty) {
      return FogUpdate(accepted: true, freshCells: fresh);
    }

    // 4) 영속화(debounce) + 콜백 + 알림
    _repo?.markVisited(fresh, DateTime.now().millisecondsSinceEpoch);
    onNewCells?.call(fresh);
    notifyListeners();
    return FogUpdate(accepted: true, freshCells: fresh);
  }

  /// 총 걷어낸 면적(km²). 서울 기준 위도로 셀 면적 보정.
  double get totalAreaKm2 => AreaCalculator.totalAreaKm2(_visited, _refLat);

  /// 면적 보정 기준 위도. 방문 셀이 있으면 첫 셀 중심 위도, 없으면 서울.
  double get _refLat {
    if (_visited.isEmpty) return 37.5400;
    return FogGrid.cellCenter(_visited.first).latitude;
  }

  /// 특정 지역의 클리어 비율(0~100). matcher가 분모/분자를 제공.
  double clearPercentOf({
    required int visitedInRegion,
    required int totalInRegion,
  }) => AreaCalculator.clearPercent(
    visited: visitedInRegion,
    total: totalInRegion,
  );
}
