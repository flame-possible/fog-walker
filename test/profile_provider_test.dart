import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:fog_walker/models/auth_account.dart';
import 'package:fog_walker/models/user_profile.dart';
import 'package:fog_walker/providers/profile_provider.dart';

void main() {
  late Directory tempDir;
  late Box<UserProfile> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fogwalker_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AuthProviderTypeAdapter());
    }
    box = await Hive.openBox<UserProfile>('userProfile_test');
  });

  tearDown(() async {
    await box.clear();
    await box.close();
    await tempDir.delete(recursive: true);
  });

  group('ProfileProvider.syncProgress', () {
    test('박스에 프로필이 없어도 에러 없이 저장된다 (회귀: HiveError not in a box)', () {
      // 빈 박스로 시작 → initial 프로필 사용
      final provider = ProfileProvider(box: box);
      // 이전 버그: initial 객체에 .save() 호출 시 HiveError 발생
      expect(() => provider.syncProgress(stampCount: 3), returnsNormally);
      expect(provider.profile.stampCount, 3);
    });

    test('저장 후 박스에서 다시 읽으면 갱신된 값이 보인다', () {
      final provider = ProfileProvider(box: box);
      provider.syncProgress(stampCount: 10);
      final saved = box.get('me');
      expect(saved, isNotNull);
      expect(saved!.stampCount, 10);
      expect(saved.level, 1 + 10 ~/ 5); // 레벨 규칙
    });

    test('도장 수에 따라 티어가 바뀐다', () {
      final provider = ProfileProvider(box: box);
      provider.syncProgress(stampCount: 0);
      expect(provider.profile.tier, 'Newcomer');
      provider.syncProgress(stampCount: 60); // level 13 → Wanderer
      expect(provider.profile.tier, 'Wanderer');
    });

    test('Google account sync keeps progress values', () {
      final provider = ProfileProvider(box: box);
      provider.syncProgress(stampCount: 12);

      provider.syncAccount(
        const AuthAccount(
          id: 'supabase-user-1',
          email: 'yang@example.com',
          displayName: 'Yang Walker',
          photoUrl: 'https://example.com/photo.png',
        ),
      );

      expect(provider.profile.authProvider, AuthProviderType.supabaseGoogle);
      expect(provider.profile.supabaseUserId, 'supabase-user-1');
      expect(provider.profile.email, 'yang@example.com');
      expect(provider.profile.displayName, 'Yang Walker');
      expect(provider.profile.stampCount, 12);
      expect(provider.profile.level, 3);
    });
  });
}
