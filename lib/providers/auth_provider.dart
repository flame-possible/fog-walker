import 'package:flutter/foundation.dart';

import '../models/auth_account.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService service}) : _service = service {
    _account = _service.currentAccount;
  }

  final AuthService _service;
  AuthAccount? _account;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isConfigured => _service.configured;
  AuthAccount? get account => _account;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _account != null;

  Future<AuthAccount?> signInWithGoogle() async {
    if (!isConfigured) {
      _errorMessage = 'Supabase 설정이 필요해요.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final account = await _service.signInWithGoogle();
      _account = account;
      return account;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.signOut();
      _account = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
