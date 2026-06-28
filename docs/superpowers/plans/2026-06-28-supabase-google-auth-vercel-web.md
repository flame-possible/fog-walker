# Supabase Google Auth Vercel Web Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add optional Supabase Google login to Fog Walker and prepare Flutter web deployment on Vercel.

**Architecture:** Supabase is the single auth provider. The app remains local-first: when Supabase environment values are missing it runs in local mode, and when values are present it initializes Supabase, exposes Google login/logout through an `AuthProvider`, and mirrors account data into `UserProfile`. Vercel deploys the Flutter web static build from `build/web`.

**Tech Stack:** Flutter, Dart, Provider, Hive, Supabase Flutter, Flutter web, Vercel.

---

## File Structure

- `pubspec.yaml`: add `supabase_flutter`.
- `lib/config/supabase_config.dart`: read `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and OAuth redirect URLs from `--dart-define`.
- `lib/models/auth_account.dart`: pure Dart account value object used by auth/profile tests.
- `lib/services/auth_service.dart`: Supabase client wrapper with local-mode fallback and Google OAuth calls.
- `lib/providers/auth_provider.dart`: ChangeNotifier for auth state, loading state, errors, login, logout.
- `lib/models/user_profile.dart`: add auth/account fields after existing Hive field numbers.
- `lib/models/user_profile.g.dart`: update Hive adapter read/write for new optional fields.
- `lib/providers/profile_provider.dart`: add `syncAccount` and `clearAccount` methods.
- `lib/main.dart`: initialize Supabase service and inject `AuthProvider`.
- `lib/screens/my_info_screen.dart`: show Google login/logout account section.
- `lib/widgets/passport_card.dart`: use `displayName` when available.
- `android/app/src/main/AndroidManifest.xml`: add OAuth callback intent filter.
- `ios/Runner/Info.plist`: add OAuth URL scheme.
- `scripts/vercel-build.sh`: install/use Flutter SDK on Vercel and build web with `--dart-define`.
- `vercel.json`: Vercel build/output configuration for Flutter web.
- `README.md`: document Supabase/Vercel local and deploy setup.
- `test/auth_provider_test.dart`: auth provider success, cancel, failure, logout tests.
- `test/profile_provider_test.dart`: account sync preserves progress tests.
- `test/user_profile_test.dart`: profile default auth fields tests.

---

### Task 1: Dependencies and Supabase Config

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/config/supabase_config.dart`

- [ ] **Step 1: Add dependency**

Run:

```powershell
flutter pub add supabase_flutter
```

Expected: `pubspec.yaml` and `pubspec.lock` include `supabase_flutter`.

- [ ] **Step 2: Create config file**

Create `lib/config/supabase_config.dart`:

```dart
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
```

- [ ] **Step 3: Run analysis**

Run:

```powershell
flutter analyze
```

Expected: no issues.

---

### Task 2: User Profile Auth Fields

**Files:**
- Modify: `lib/models/user_profile.dart`
- Modify: `lib/models/user_profile.g.dart`
- Modify: `lib/providers/profile_provider.dart`
- Create: `lib/models/auth_account.dart`
- Create: `test/user_profile_test.dart`
- Modify: `test/profile_provider_test.dart`

- [ ] **Step 1: Write profile default test**

Create `test/user_profile_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test and verify it fails**

Run:

```powershell
flutter test test/user_profile_test.dart
```

Expected: FAIL because `AuthProviderType` and auth fields do not exist.

- [ ] **Step 3: Add account value object**

Create `lib/models/auth_account.dart`:

```dart
class AuthAccount {
  const AuthAccount({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
}
```

- [ ] **Step 4: Extend UserProfile**

In `lib/models/user_profile.dart`, add:

```dart
@HiveType(typeId: 4)
enum AuthProviderType {
  @HiveField(0)
  local,
  @HiveField(1)
  supabaseGoogle,
}
```

Add constructor fields:

```dart
this.authProvider = AuthProviderType.local,
this.supabaseUserId,
this.email,
this.photoUrl,
this.displayName,
```

Add Hive fields:

```dart
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
    displayName != null && displayName!.trim().isNotEmpty ? displayName! : name;
```

- [ ] **Step 5: Update Hive adapter**

In `lib/models/user_profile.g.dart`, update read/write to include fields 5-9 and add `AuthProviderTypeAdapter`. Register it in `AppDatabase.init()`.

Expected read fallback:

```dart
authProvider: fields[5] as AuthProviderType? ?? AuthProviderType.local,
supabaseUserId: fields[6] as String?,
email: fields[7] as String?,
photoUrl: fields[8] as String?,
displayName: fields[9] as String?,
```

- [ ] **Step 6: Add provider account sync tests**

Append to `test/profile_provider_test.dart`:

```dart
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
```

Import `AuthAccount`.

- [ ] **Step 7: Implement `syncAccount` and `clearAccount`**

In `ProfileProvider`, add:

```dart
void syncAccount(AuthAccount account) {
  _profile.authProvider = AuthProviderType.supabaseGoogle;
  _profile.supabaseUserId = account.id;
  _profile.email = account.email;
  _profile.displayName = account.displayName;
  _profile.photoUrl = account.photoUrl;
  if (account.displayName != null && account.displayName!.trim().isNotEmpty) {
    _profile.name = account.displayName!.trim().toUpperCase();
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
```

- [ ] **Step 8: Run profile tests**

Run:

```powershell
flutter test test/user_profile_test.dart test/profile_provider_test.dart
```

Expected: PASS.

---

### Task 3: Auth Service and Provider

**Files:**
- Create: `lib/services/auth_service.dart`
- Create: `lib/providers/auth_provider.dart`
- Create: `test/auth_provider_test.dart`

- [ ] **Step 1: Write provider tests**

Create `test/auth_provider_test.dart`:

```dart
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
      final provider = AuthProvider(service: FakeAuthService(configured: false));

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
      final provider = AuthProvider(service: FakeAuthService(nextAccount: null));

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
```

- [ ] **Step 2: Run test and verify it fails**

Run:

```powershell
flutter test test/auth_provider_test.dart
```

Expected: FAIL because `AuthService` and `AuthProvider` do not exist.

- [ ] **Step 3: Implement AuthService**

Create `lib/services/auth_service.dart`:

```dart
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

  SupabaseClient? get _client =>
      configured ? Supabase.instance.client : null;

  @override
  AuthAccount? get currentAccount => _accountFromUser(_client?.auth.currentUser);

  static Future<void> initialize(SupabaseConfig config) async {
    if (!config.isConfigured) return;
    await Supabase.initialize(url: config.url, anonKey: config.anonKey);
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
    return AuthAccount(
      id: user.id,
      email: user.email,
      displayName: metadata['full_name'] as String? ?? metadata['name'] as String?,
      photoUrl: metadata['avatar_url'] as String? ?? metadata['picture'] as String?,
    );
  }
}
```

- [ ] **Step 4: Implement AuthProvider**

Create `lib/providers/auth_provider.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../models/auth_account.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService service}) : _service = service {
    _account = _service.currentAccount;
  }

  final AuthService _service;
  AuthAccount? _account;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isConfigured => _service.configured;
  AuthAccount? get account => _account;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _account != null;

  Future<AuthAccount?> signInWithGoogle() async {
    if (!isConfigured) {
      _errorMessage = 'Supabase 설정이 필요해요.';
      notifyListeners();
      return null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final account = await _service.signInWithGoogle();
      _account = account;
      return account;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.signOut();
      _account = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

- [ ] **Step 5: Run auth provider tests**

Run:

```powershell
flutter test test/auth_provider_test.dart
```

Expected: PASS.

---

### Task 4: App Wiring and My Info UI

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/screens/my_info_screen.dart`
- Modify: `lib/widgets/passport_card.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: Wire Supabase and AuthProvider in main**

In `main.dart`, import config/service/provider:

```dart
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
```

In `_bootstrap`, before provider construction:

```dart
const supabaseConfig = SupabaseConfig.fromEnvironment;
await SupabaseAuthService.initialize(supabaseConfig);
final auth = AuthProvider(
  service: SupabaseAuthService(config: supabaseConfig),
);
final profile = ProfileProvider(box: AppDatabase.userProfile)
  ..syncProgress(stampCount: collection.unlockedCount);
final account = auth.account;
if (account != null) profile.syncAccount(account);
```

Add `auth` to `_AppDependencies` and `MultiProvider`.

- [ ] **Step 2: Add account UI to My Info**

In `MyInfoScreen`, watch `AuthProvider` and add a section below `PassportCard`:

```dart
final auth = context.watch<AuthProvider>();
```

Add:

```dart
_accountSection(context, auth, context.read<ProfileProvider>()),
```

Implement:

```dart
Widget _accountSection(
  BuildContext context,
  AuthProvider auth,
  ProfileProvider profileProvider,
) {
  final account = auth.account;
  if (!auth.isConfigured) {
    return _accountBox(
      title: '계정 연결 준비 중',
      subtitle: 'Supabase 환경 변수를 설정하면 Google 로그인을 사용할 수 있어요.',
      child: const SizedBox.shrink(),
    );
  }
  if (account != null) {
    return _accountBox(
      title: account.displayName ?? 'Google 계정',
      subtitle: account.email ?? '로그인됨',
      child: TextButton(
        onPressed: auth.isLoading
            ? null
            : () async {
                await auth.signOut();
                profileProvider.clearAccount();
              },
        child: const Text('로그아웃'),
      ),
    );
  }
  return _accountBox(
    title: 'Google 계정 연결',
    subtitle: '웹과 모바일에서 같은 프로필을 사용할 수 있어요.',
    child: FilledButton(
      onPressed: auth.isLoading
          ? null
          : () async {
              final account = await auth.signInWithGoogle();
              if (account != null && context.mounted) {
                profileProvider.syncAccount(account);
              }
            },
      child: Text(auth.isLoading ? '연결 중' : 'Google로 로그인'),
    ),
  );
}
```

Use existing `AppType` and `AppColors` for styling.

- [ ] **Step 3: Use effective profile name in passport card**

In `PassportCard`, change displayed name and avatar initials source from `profile.name` to `profile.effectiveName`.

- [ ] **Step 4: Add Android OAuth intent filter**

In `android/app/src/main/AndroidManifest.xml`, add inside `<activity>`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="fogwalker" android:host="login-callback"/>
</intent-filter>
```

- [ ] **Step 5: Add iOS URL scheme**

In `ios/Runner/Info.plist`, add:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>fogwalker</string>
    </array>
  </dict>
</array>
```

- [ ] **Step 6: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected: no issues.

---

### Task 5: Vercel Web Deployment Config

**Files:**
- Create: `scripts/vercel-build.sh`
- Create: `vercel.json`
- Modify: `README.md`

- [ ] **Step 1: Create Vercel build script**

Create `scripts/vercel-build.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=SUPABASE_WEB_REDIRECT_URL="${SUPABASE_WEB_REDIRECT_URL:-}"
```

- [ ] **Step 2: Create Vercel config**

Create `vercel.json`:

```json
{
  "buildCommand": "bash scripts/vercel-build.sh",
  "outputDirectory": "build/web",
  "installCommand": "",
  "framework": null,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

- [ ] **Step 3: Document setup**

Add to `README.md`:

```markdown
## Supabase 로그인과 Vercel 웹 배포

로컬에서 Supabase Auth를 켜려면:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=public-anon-key-from-dashboard
```

Vercel 환경 변수:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_WEB_REDIRECT_URL`
- `FLUTTER_VERSION` (선택, 기본 `stable`)

Vercel은 `scripts/vercel-build.sh`를 실행하고 `build/web`을 배포한다.
Supabase Dashboard의 Google provider에는 Vercel production/preview URL과
`fogwalker://login-callback/` redirect URL을 등록한다.
```

- [ ] **Step 4: Run web build without Supabase vars**

Run:

```powershell
flutter build web --release
```

Expected: build succeeds and local mode remains available.

---

### Task 6: Full Verification and Commit

**Files:**
- All touched files.

- [ ] **Step 1: Format**

Run:

```powershell
dart format lib test
```

Expected: Dart files formatted.

- [ ] **Step 2: Run tests**

Run:

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected: no issues.

- [ ] **Step 4: Check git state**

Run:

```powershell
git status --short
git diff --check
```

Expected: only planned files changed, no whitespace errors.

- [ ] **Step 5: Commit**

Run:

```powershell
git add -A
git commit -m "feat: add supabase google auth and vercel web config"
```
