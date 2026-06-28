import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/models/auth_account.dart';
import 'package:fog_walker/providers/auth_provider.dart';
import 'package:fog_walker/services/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({this.configured = true, this.nextAccount, this.nextError});

  @override
  final bool configured;

  AuthAccount? nextAccount;
  Object? nextError;
  bool signedOut = false;

  @override
  AuthAccount? get currentAccount => nextAccount;

  @override
  Future<AuthAccount?> signInWithGoogle() async {
    final error = nextError;
    if (error != null) throw error;
    return nextAccount;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    nextAccount = null;
  }
}

void main() {
  group('AuthProvider', () {
    test('reports unavailable when service is not configured', () {
      final provider = AuthProvider(
        service: FakeAuthService(configured: false),
      );

      expect(provider.isConfigured, isFalse);
      expect(provider.account, isNull);
    });

    test('stores account after Google sign-in succeeds', () async {
      final service = FakeAuthService(
        nextAccount: const AuthAccount(
          id: 'user-1',
          email: 'yang@example.com',
          displayName: 'Yang',
        ),
      );
      final provider = AuthProvider(service: service);

      final account = await provider.signInWithGoogle();

      expect(account?.id, 'user-1');
      expect(provider.account?.email, 'yang@example.com');
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('keeps account null when sign-in is cancelled', () async {
      final provider = AuthProvider(
        service: FakeAuthService(nextAccount: null),
      );

      final account = await provider.signInWithGoogle();

      expect(account, isNull);
      expect(provider.account, isNull);
      expect(provider.errorMessage, isNull);
    });

    test('captures sign-in failure message', () async {
      final provider = AuthProvider(
        service: FakeAuthService(nextError: Exception('network failed')),
      );

      final account = await provider.signInWithGoogle();

      expect(account, isNull);
      expect(provider.errorMessage, contains('network failed'));
      expect(provider.isLoading, isFalse);
    });

    test('clears account on logout', () async {
      final service = FakeAuthService(
        nextAccount: const AuthAccount(id: 'user-1', email: 'yang@example.com'),
      );
      final provider = AuthProvider(service: service);
      await provider.signInWithGoogle();

      await provider.signOut();

      expect(service.signedOut, isTrue);
      expect(provider.account, isNull);
    });
  });
}
