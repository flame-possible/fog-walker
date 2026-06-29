import 'package:flutter/foundation.dart';

import '../models/auth_account.dart';
import '../services/cloud_sync_service.dart';

class CloudSyncProvider extends ChangeNotifier {
  CloudSyncProvider({required AppSyncCoordinator coordinator})
    : _coordinator = coordinator;

  final AppSyncCoordinator _coordinator;

  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _errorMessage;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get errorMessage => _errorMessage;

  Future<void> sync(AuthAccount? account) async {
    if (account == null || _isSyncing) return;
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _coordinator.sync(account);
      _lastSyncedAt = DateTime.now();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
