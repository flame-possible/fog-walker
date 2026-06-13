import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 업적/진행도용 얇은 둥근 진행바.
class ThinProgressBar extends StatelessWidget {
  const ThinProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.stampRed,
    this.height = 5,
  });

  /// 0.0 ~ 1.0.
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: AppColors.line),
          FractionallySizedBox(
            widthFactor: v,
            child: Container(height: height, color: color),
          ),
        ],
      ),
    );
  }
}
