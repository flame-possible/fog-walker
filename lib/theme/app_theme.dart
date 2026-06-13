import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// 앱 전역 ThemeData.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.stampRed,
        secondary: AppColors.stampRed,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: AppType.serif(size: 34, weight: FontWeight.w800),
        headlineMedium: AppType.serif(size: 26, weight: FontWeight.w700),
        titleLarge: AppType.serif(size: 20, weight: FontWeight.w700),
        bodyLarge: AppType.sans(size: 15),
        bodyMedium: AppType.sans(size: 14, color: AppColors.inkSoft),
        labelLarge: AppType.label(),
      ),
      dividerColor: AppColors.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
