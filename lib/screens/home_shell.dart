import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'achievement_screen.dart';
import 'map_screen.dart';
import 'my_info_screen.dart';
import 'passport_screen.dart';
import 'settings_screen.dart';

/// 하단 탭 5개를 묶는 앱 셸.
///
/// 지도 / 여권(컬렉션) / 업적 / 내 정보 / 설정. IndexedStack으로 탭 전환 시 각 화면
/// 상태(지도 위치 등)를 보존한다.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    MapScreen(),
    PassportScreen(),
    AchievementScreen(),
    MyInfoScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _tab(0, Icons.map_outlined, Icons.map),
                _tab(1, Icons.wallet_outlined, Icons.wallet),
                _tab(
                  2,
                  Icons.workspace_premium_outlined,
                  Icons.workspace_premium,
                ),
                _tab(3, Icons.person_outline, Icons.person),
                _tab(4, Icons.settings_outlined, Icons.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, IconData activeIcon) {
    final selected = _index == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: Center(
          child: Icon(
            selected ? activeIcon : icon,
            color: selected ? AppColors.ink : AppColors.inkFaint,
            size: 26,
          ),
        ),
      ),
    );
  }
}
