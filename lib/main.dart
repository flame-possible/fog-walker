import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'data/fog_repository.dart';
import 'data/region_repository.dart';
import 'providers/collection_provider.dart';
import 'providers/fog_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/walk_session_provider.dart';
import 'screens/home_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FogWalkerBootstrap());
}

/// 비동기 초기화(Hive·GeoJSON 로드)를 수행한 뒤 앱을 띄우는 부트스트랩.
///
/// 로딩 중에는 스플래시를, 완료되면 Provider를 주입한 [HomeShell]을 보여준다.
class FogWalkerBootstrap extends StatefulWidget {
  const FogWalkerBootstrap({super.key});

  @override
  State<FogWalkerBootstrap> createState() => _FogWalkerBootstrapState();
}

class _FogWalkerBootstrapState extends State<FogWalkerBootstrap> {
  late final Future<_AppDependencies> _init;

  @override
  void initState() {
    super.initState();
    _init = _bootstrap();
  }

  Future<_AppDependencies> _bootstrap() async {
    await AppDatabase.init();
    final regionRepo = await RegionRepository.load();
    final fogRepo = FogRepository(AppDatabase.visitedCells);

    final fog = FogProvider(repository: fogRepo)
      ..loadInitial(fogRepo.loadAll());
    final walk = WalkSessionProvider(box: AppDatabase.walkSessions);
    final collection = CollectionProvider(
      repository: regionRepo,
      progressBox: AppDatabase.regionProgress,
    );
    final profile = ProfileProvider(box: AppDatabase.userProfile)
      ..syncProgress(stampCount: collection.unlockedCount);

    return _AppDependencies(
      fog: fog,
      walk: walk,
      collection: collection,
      profile: profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppDependencies>(
      future: _init,
      builder: (context, snapshot) {
        // 로딩/에러 단계: Provider 없는 단순 MaterialApp.
        if (snapshot.connectionState != ConnectionState.done) {
          return _wrapApp(const _SplashScreen());
        }
        if (snapshot.hasError) {
          return _wrapApp(_ErrorScreen(error: snapshot.error.toString()));
        }
        // 준비 완료: Provider를 MaterialApp '위'에 두어 모든 라우트
        // (Navigator.push로 연 화면 포함)가 Provider에 접근하게 한다.
        final deps = snapshot.data!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: deps.fog),
            ChangeNotifierProvider.value(value: deps.walk),
            ChangeNotifierProvider.value(value: deps.collection),
            ChangeNotifierProvider.value(value: deps.profile),
          ],
          child: _wrapApp(const HomeShell()),
        );
      },
    );
  }

  Widget _wrapApp(Widget home) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fog Walker',
      theme: AppTheme.light(),
      home: home,
    );
  }
}

class _AppDependencies {
  _AppDependencies({
    required this.fog,
    required this.walk,
    required this.collection,
    required this.profile,
  });
  final FogProvider fog;
  final WalkSessionProvider walk;
  final CollectionProvider collection;
  final ProfileProvider profile;
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore,
                size: 64, color: AppColors.stampRed),
            const SizedBox(height: 16),
            Text('Fog Walker',
                style: AppType.serif(size: 28, weight: FontWeight.w800)),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.stampRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('초기화 중 문제가 발생했어요:\n$error',
              textAlign: TextAlign.center,
              style: AppType.sans(size: 14, color: AppColors.inkSoft)),
        ),
      ),
    );
  }
}
