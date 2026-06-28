import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// My Info 상단의 여권 신상 카드. 홀로그램 파스텔 배경 위에 사진과 정보.
class PassportCard extends StatelessWidget {
  const PassportCard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.effectiveName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.passportGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PASSPORT', style: AppType.label(color: AppColors.inkSoft)),
              Text(
                'REPUBLIC OF KOREA',
                style: AppType.label(color: AppColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _photo(profile),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Name', name),
                    const SizedBox(height: 10),
                    _field('ID', profile.passportId),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _field('Level', 'LV ${profile.level}')),
                        Expanded(child: _field('Tier', profile.tier)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.label(color: AppColors.inkFaint)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppType.sans(
            size: 15,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _photo(UserProfile profile) {
    final initials = profile.effectiveName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first)
        .join();
    return Container(
      width: 84,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 18,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.82),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            child: Container(
              width: 62,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.82),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Text(
              initials.isEmpty ? 'FW' : initials,
              style: AppType.label(color: Colors.white, size: 10),
            ),
          ),
        ],
      ),
    );
  }
}
