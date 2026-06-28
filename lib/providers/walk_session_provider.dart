import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../domain/area_calculator.dart';
import '../domain/walk_stats.dart';
import '../models/walk_session.dart';

/// 산책 세션의 생명주기와 통계 집계.
///
/// start()로 추적을 시작하면 진행 중 거리/걷어낸 면적을 누적하고, stop()으로
/// WalkSession을 저장한다. 총 거리·연속일·This Week 등은 저장된 세션에서
/// [WalkStats]로 파생한다.
class WalkSessionProvider extends ChangeNotifier {
  WalkSessionProvider({Box<WalkSession>? box}) : _box = box;

  final Box<WalkSession>? _box;

  bool _isWalking = false;
  bool get isWalking => _isWalking;

  DateTime? _startedAt;
  LatLng? _lastPoint;
  double _activeDistanceKm = 0;
  int _activeNewCells = 0;
  final Set<String> _activeRegions = {};
  WalkMode _mode = WalkMode.walk;

  /// 진행 중 산책의 누적 거리(km).
  double get activeDistanceKm => _activeDistanceKm;

  /// 진행 중 산책의 누적 면적(km²). 새 셀 수 × 셀 면적.
  double get activeClearedKm2 =>
      _activeNewCells * AreaCalculator.cellAreaKm2(37.54);

  static const Distance _distance = Distance();

  List<WalkSession> get sessions {
    final b = _box;
    if (b == null) return const [];
    final list = b.values.toList();
    list.sort((a, c) => c.startedAt.compareTo(a.startedAt)); // 최신순
    return list;
  }

  WalkMode get mode => _mode;
  set mode(WalkMode m) {
    _mode = m;
    notifyListeners();
  }

  /// 산책 시작.
  void start() {
    _isWalking = true;
    _startedAt = DateTime.now();
    _lastPoint = null;
    _activeDistanceKm = 0;
    _activeNewCells = 0;
    _activeRegions.clear();
    notifyListeners();
  }

  /// 위치 이벤트 누적 (FogProvider와 함께 호출됨).
  /// [newCellCount]는 이번 위치로 새로 걷힌 셀 수, [regionId]는 현재 지역.
  void onMove(LatLng point, {int newCellCount = 0, String? regionId}) {
    if (!_isWalking) return;
    final last = _lastPoint;
    if (last != null) {
      final meters = _distance(last, point);
      // 순간이동은 FogProvider가 이미 걸러내지만 방어적으로 한 번 더
      if (meters <= 1000) {
        _activeDistanceKm += meters / 1000.0;
      }
    }
    _lastPoint = point;
    _activeNewCells += newCellCount;
    if (regionId != null) _activeRegions.add(regionId);
    notifyListeners();
  }

  /// 산책 종료. 의미 있는 기록이면 저장하고 그 세션을 반환(없으면 null).
  Future<WalkSession?> stop() async {
    if (!_isWalking) return null;
    _isWalking = false;
    final started = _startedAt ?? DateTime.now();
    final ended = DateTime.now();

    // 너무 짧은(거리 0) 산책은 저장하지 않는다.
    if (_activeDistanceKm <= 0 && _activeNewCells == 0) {
      notifyListeners();
      return null;
    }

    final session = WalkSession(
      id: started.microsecondsSinceEpoch.toString(),
      startedAt: started,
      endedAt: ended,
      distanceKm: _activeDistanceKm,
      clearedKm2: activeClearedKm2,
      newCellsCount: _activeNewCells,
      regionIds: _activeRegions.toList(),
      mode: _mode,
    );
    await _box?.add(session);
    notifyListeners();
    return session;
  }

  // --- 파생 통계 ---
  double get totalDistanceKm => WalkStats.totalDistanceKm(sessions);
  double get longestWalkKm => WalkStats.longestWalkKm(sessions);
  int get streakDays =>
      WalkStats.currentStreakDays(sessions, today: DateTime.now());
  WeeklySummary get weekly => WalkStats.weekly(sessions, today: DateTime.now());
  double distanceByMode(WalkMode m) => WalkStats.distanceByMode(sessions, m);

  /// 특정 지역을 지난 세션들 (지역 상세 Visits).
  List<WalkSession> sessionsInRegion(String regionId) =>
      sessions.where((s) => s.regionIds.contains(regionId)).toList();
}
