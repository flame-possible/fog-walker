import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/auth_account.dart';

abstract class AuthService {
  bool get configured;
  AuthAccount? get currentAccount;
  Future<AuthAccount?> signInWithGoogle();
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService({required this.config});

  final SupabaseConfig config;

  @override
  bool get configured => config.isConfigured;

  SupabaseClient? get _client => configured ? Supabase.instance.client : null;

  @override
  AuthAccount? get currentAccount =>
      _accountFromUser(_client?.auth.currentUser);

  static Future<void> initialize(SupabaseConfig config) async {
    if (!config.isConfigured) return;
    await Supabase.initialize(url: config.url, publishableKey: config.anonKey);
  }

  @override
  Future<AuthAccount?> signInWithGoogle() async {
    final client = _client;
    if (client == null) return null;
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: config.redirectTo,
    );
    return currentAccount;
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  AuthAccount? _accountFromUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = metadata['full_name'];
    final name = metadata['name'];
    final avatarUrl = metadata['avatar_url'];
    final picture = metadata['picture'];

    return AuthAccount(
      id: user.id,
      email: user.email,
      displayName: fullName is String
          ? fullName
          : name is String
          ? name
          : null,
      photoUrl: avatarUrl is String
          ? avatarUrl
          : picture is String
          ? picture
          : null,
    );
  }
}
