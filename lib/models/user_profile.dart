import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 4)
enum AuthProviderType {
  @HiveField(0)
  local,
  @HiveField(1)
  supabaseGoogle,
}

/// My Info 상단 여권에 표시되는 사용자 프로필.
///
/// 레벨/티어/도장 수는 진행에 따라 갱신된다. 총 거리·연속일 등은
/// walkSessions에서 집계하므로 여기 저장하지 않는다.
@HiveType(typeId: 2)
class UserProfile extends HiveObject {
  UserProfile({
    required this.name,
    required this.passportId,
    this.level = 1,
    this.tier = 'Newcomer',
    this.stampCount = 0,
    this.authProvider = AuthProviderType.local,
    this.supabaseUserId,
    this.email,
    this.photoUrl,
    this.displayName,
  });

  @HiveField(0)
  String name;

  @HiveField(1)
  String passportId;

  @HiveField(2)
  int level;

  @HiveField(3)
  String tier;

  @HiveField(4)
  int stampCount;

  @HiveField(5)
  AuthProviderType authProvider;

  @HiveField(6)
  String? supabaseUserId;

  @HiveField(7)
  String? email;

  @HiveField(8)
  String? photoUrl;

  @HiveField(9)
  String? displayName;

  String get effectiveName =>
      displayName != null && displayName!.trim().isNotEmpty
      ? displayName!.trim()
      : name;

  /// 기본 프로필 (첫 실행 시드).
  factory UserProfile.initial() => UserProfile(
    name: 'HONG GILDONG',
    passportId: 'FW-2024-0927',
    level: 1,
    tier: 'Newcomer',
    stampCount: 0,
  );
}
