import 'package:flutter/foundation.dart';

class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    required this.mobileRedirectUrl,
    required this.webRedirectUrl,
  });

  static const fromEnvironment = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    mobileRedirectUrl: String.fromEnvironment(
      'SUPABASE_MOBILE_REDIRECT_URL',
      defaultValue: 'fogwalker://login-callback/',
    ),
    webRedirectUrl: String.fromEnvironment('SUPABASE_WEB_REDIRECT_URL'),
  );

  final String url;
  final String anonKey;
  final String mobileRedirectUrl;
  final String webRedirectUrl;

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  String? get redirectTo {
    if (kIsWeb) {
      return webRedirectUrl.isEmpty ? null : webRedirectUrl;
    }
    return mobileRedirectUrl;
  }
}
