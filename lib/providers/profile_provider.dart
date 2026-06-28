import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/auth_account.dart';
import '../models/user_profile.dart';

/// 사용자 프로필(여권) 상태. 도장 수/레벨 갱신을 담당한다.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({Box<UserProfile>? box}) : _box = box {
    _profile = _box?.get(_key) ?? UserProfile.initial();
  }

  final Box<UserProfile>? _box;
  static const _key = 'me';

  late UserProfile _profile;
  UserProfile get profile => _profile;

  /// 해금 지역 수 등에 따라 도장 수/레벨/티어를 갱신한다.
  void syncProgress({required int stampCount}) {
    _profile.stampCount = stampCount;
    _profile.level = 1 + stampCount ~/ 5; // 5도장마다 레벨업(간단 규칙)
    _profile.tier = _tierFor(_profile.level);
    // put을 쓰면 박스에 없던 객체(initial)도 안전하게 저장된다.
    // (HiveObject.save()는 박스에 귀속된 객체에만 동작)
    _box?.put(_key, _profile);
    notifyListeners();
  }

  void syncAccount(AuthAccount account) {
    _profile.authProvider = AuthProviderType.supabaseGoogle;
    _profile.supabaseUserId = account.id;
    _profile.email = account.email;
    _profile.displayName = account.displayName;
    _profile.photoUrl = account.photoUrl;

    final displayName = account.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      _profile.name = displayName.toUpperCase();
    }

    _box?.put(_key, _profile);
    notifyListeners();
  }

  void clearAccount() {
    _profile.authProvider = AuthProviderType.local;
    _profile.supabaseUserId = null;
    _profile.email = null;
    _profile.displayName = null;
    _profile.photoUrl = null;
    _box?.put(_key, _profile);
    notifyListeners();
  }

  static String _tierFor(int level) {
    if (level >= 20) return 'Legend';
    if (level >= 12) return 'Wanderer';
    if (level >= 6) return 'Explorer';
    if (level >= 2) return 'Rookie';
    return 'Newcomer';
  }
}
