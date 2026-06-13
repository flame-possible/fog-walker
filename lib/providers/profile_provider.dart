import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

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
    _profile.save();
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
