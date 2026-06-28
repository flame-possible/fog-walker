import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/config/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test('is not configured without URL and anon key', () {
      const config = SupabaseConfig(
        url: '',
        anonKey: '',
        mobileRedirectUrl: 'fogwalker://login-callback/',
        webRedirectUrl: '',
      );

      expect(config.isConfigured, isFalse);
    });

    test('is configured when URL and anon key exist', () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'public-anon-key',
        mobileRedirectUrl: 'fogwalker://login-callback/',
        webRedirectUrl: '',
      );

      expect(config.isConfigured, isTrue);
    });
  });
}
