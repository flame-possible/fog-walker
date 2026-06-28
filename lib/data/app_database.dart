import 'package:hive_flutter/hive_flutter.dart';

import '../models/region_progress.dart';
import '../models/user_profile.dart';
import '../models/walk_session.dart';

/// Hive 초기화와 박스 접근을 한곳에서 관리한다.
///
/// 박스 4개:
///  - visitedCells: key "gx,gy" → 최초 방문 timestamp(int)  [안개 엔진]
///  - walkSessions: WalkSession 목록
///  - regionProgress: regionId → RegionProgress
///  - userProfile: 'me' → UserProfile
class AppDatabase {
  AppDatabase._();

  static const visitedCellsBox = 'visitedCells';
  static const walkSessionsBox = 'walkSessions';
  static const regionProgressBox = 'regionProgress';
  static const userProfileBox = 'userProfile';

  static late Box<int> visitedCells;
  static late Box<WalkSession> walkSessions;
  static late Box<RegionProgress> regionProgress;
  static late Box<UserProfile> userProfile;

  /// 앱 시작 시 1회 호출. Hive 초기화 + 어댑터 등록 + 박스 오픈.
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(WalkSessionAdapter());
    Hive.registerAdapter(WalkModeAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(AuthProviderTypeAdapter());
    Hive.registerAdapter(RegionProgressAdapter());

    visitedCells = await Hive.openBox<int>(visitedCellsBox);
    walkSessions = await Hive.openBox<WalkSession>(walkSessionsBox);
    regionProgress = await Hive.openBox<RegionProgress>(regionProgressBox);
    userProfile = await Hive.openBox<UserProfile>(userProfileBox);
  }

  /// 테스트/초기화용 — 모든 사용자 데이터 삭제.
  static Future<void> clearAll() async {
    await visitedCells.clear();
    await walkSessions.clear();
    await regionProgress.clear();
    await userProfile.clear();
  }
}
