import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/models/user_profile.dart';

void main() {
  group('UserProfile auth fields', () {
    test('initial profile starts in local auth mode', () {
      final profile = UserProfile.initial();

      expect(profile.authProvider, AuthProviderType.local);
      expect(profile.supabaseUserId, isNull);
      expect(profile.email, isNull);
      expect(profile.photoUrl, isNull);
      expect(profile.displayName, isNull);
      expect(profile.effectiveName, 'HONG GILDONG');
    });

    test('effectiveName prefers displayName when present', () {
      final profile = UserProfile.initial()..displayName = 'Yang Walker';

      expect(profile.effectiveName, 'Yang Walker');
    });
  });
}
