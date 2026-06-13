import 'dart:async';

import 'package:hive/hive.dart';

/// 방문 셀의 영속화. 셀 `(gx, gy)`를 `"gx,gy"` 문자열 키로 저장한다.
///
/// 쓰기가 잦으므로(걸을 때마다) 5초 debounce로 일괄 flush 한다. 메모리
/// 캐시는 Provider가 쥐고, 이 저장소는 디스크 입출력만 담당한다.
class FogRepository {
  FogRepository(this._box);

  final Box<int> _box;
  Timer? _flushTimer;
  final Map<(int, int), int> _pending = {};

  static const Duration flushDelay = Duration(seconds: 5);

  /// 셀 → "gx,gy".
  static String keyOf((int, int) cell) => '${cell.$1},${cell.$2}';

  /// "gx,gy" → 셀. 형식이 깨진 키는 null.
  static (int, int)? parseKey(String key) {
    final parts = key.split(',');
    if (parts.length != 2) return null;
    final gx = int.tryParse(parts[0]);
    final gy = int.tryParse(parts[1]);
    if (gx == null || gy == null) return null;
    return (gx, gy);
  }

  /// 저장된 모든 방문 셀을 로드한다.
  Set<(int, int)> loadAll() {
    final result = <(int, int)>{};
    for (final key in _box.keys) {
      final cell = parseKey(key.toString());
      if (cell != null) result.add(cell);
    }
    return result;
  }

  /// 새 셀들을 저장 예약(debounce). [timestamp]는 최초 방문 시각.
  void markVisited(Iterable<(int, int)> cells, int timestamp) {
    for (final c in cells) {
      if (!_box.containsKey(keyOf(c))) {
        _pending[c] = timestamp;
      }
    }
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(flushDelay, flush);
  }

  /// 대기 중인 셀을 즉시 디스크에 기록.
  Future<void> flush() async {
    _flushTimer?.cancel();
    if (_pending.isEmpty) return;
    final batch = {for (final e in _pending.entries) keyOf(e.key): e.value};
    _pending.clear();
    await _box.putAll(batch);
  }

  /// 앱 종료/일시정지 시 강제 저장.
  Future<void> dispose() async {
    await flush();
  }
}
