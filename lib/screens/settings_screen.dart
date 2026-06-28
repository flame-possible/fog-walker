import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Settings 화면. 계정, 권한, 기록, 시각화 설정을 한곳에 모은다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _location = LocationService();

  bool _highAccuracy = true;
  bool _autoRecord = true;
  int _trackThickness = 1;
  int _radiusIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 34, 16, 40),
        children: [
          Text(
            'Settings',
            style: AppType.serif(size: 30, weight: FontWeight.w800),
          ),
          const SizedBox(height: 28),
          _sectionLabel('데이터 및 동기화'),
          _actionRow(
            title: auth.account == null ? 'Google 계정으로 로그인' : 'Google 계정 연결됨',
            subtitle:
                auth.account?.email ??
                auth.errorMessage ??
                '로그인 시 다른 기기와 자동 동기화',
            onTap: auth.isLoading ? null : () => _toggleGoogleAccount(auth),
          ),
          _actionRow(
            title: '클라우드 동기화',
            subtitle: '기기 간 자동 백업 및 복원',
            onTap: () => _toast('클라우드 동기화는 다음 단계에서 연결할게요.'),
          ),
          const SizedBox(height: 28),
          _sectionLabel('권한'),
          _actionRow(
            title: '위치 권한',
            subtitle: '권한을 다시 표시',
            onTap: () => _location.openAppSettings(),
          ),
          const SizedBox(height: 28),
          _sectionLabel('위치와 기록'),
          _switchRow(
            title: '고정밀 위치',
            subtitle: '더 정확하지만 배터리를 더 사용합니다',
            value: _highAccuracy,
            onChanged: (value) => setState(() => _highAccuracy = value),
          ),
          _switchRow(
            title: '자동 기록',
            subtitle: '앱을 켜자마자 기록을 시작합니다',
            value: _autoRecord,
            onChanged: (value) => setState(() => _autoRecord = value),
          ),
          const SizedBox(height: 28),
          _sectionLabel('시각화'),
          _actionRow(
            title: '안개 표현 방식',
            subtitle: '레벨 별 안개 농도',
            onTap: () => _toast('안개 표현 방식 설정은 준비 중이에요.'),
          ),
          _actionRow(
            title: '지도 스타일',
            subtitle: 'Light',
            onTap: () => _toast('지도 스타일 선택은 준비 중이에요.'),
          ),
          _stepperRow(),
          _radiusRow(),
          const SizedBox(height: 28),
          _sectionLabel('데이터'),
          _actionRow(
            title: '여기를 탐험으로 표시',
            subtitle: '현재 보고있는 지도 중심으로 공개',
            onTap: () => _toast('현재 위치 표시 기능은 준비 중이에요.'),
          ),
          _actionRow(
            title: '데모 데이터 생성',
            subtitle: '서울/도쿄/뉴욕 주변에 가상 데이터 채우기',
            onTap: () => _toast('데모 데이터 생성은 개발 모드에서 연결할게요.'),
          ),
          _actionRow(
            title: '현재 세션 되돌리기',
            subtitle: 'GPS드리프트 제거용',
            onTap: () => _toast('되돌릴 수 있는 세션이 아직 없어요.'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleGoogleAccount(AuthProvider auth) async {
    final profile = context.read<ProfileProvider>();
    if (auth.account != null) {
      await auth.signOut();
      profile.clearAccount();
      return;
    }

    final account = await auth.signInWithGoogle();
    if (account != null && mounted) {
      profile.syncAccount(account);
    }
  }

  Widget _sectionLabel(String label) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Text(
        label,
        style: AppType.sans(
          size: 12,
          weight: FontWeight.w600,
          color: AppColors.inkFaint,
        ),
      ),
    );
  }

  Widget _actionRow({
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(child: _rowText(title, subtitle)),
            const Icon(Icons.chevron_right, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(child: _rowText(title, subtitle)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.black,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _stepperRow() {
    const labels = ['얇음', '보통', '굵음'];
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(child: _rowText('트랙 두께', labels[_trackThickness])),
          _circleButton(
            icon: Icons.remove,
            onTap: _trackThickness == 0
                ? null
                : () => setState(() => _trackThickness--),
          ),
          SizedBox(
            width: 54,
            child: Text(
              labels[_trackThickness],
              textAlign: TextAlign.center,
              style: AppType.sans(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          _circleButton(
            icon: Icons.add,
            onTap: _trackThickness == labels.length - 1
                ? null
                : () => setState(() => _trackThickness++),
          ),
        ],
      ),
    );
  }

  Widget _radiusRow() {
    const labels = ['끔', '250m', '500m', '1km'];
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(child: _rowText('발견 반경', '')),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.paperDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < labels.length; i++)
                  _radiusOption(labels[i], i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _radiusOption(String label, int index) {
    final selected = _radiusIndex == index;
    return InkWell(
      onTap: () => setState(() => _radiusIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 56,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: AppColors.line) : null,
        ),
        child: Text(
          label,
          style: AppType.sans(
            size: 13,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.ink : AppColors.inkFaint,
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.paperDim,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.inkFaint : AppColors.ink,
        ),
      ),
    );
  }

  Widget _rowText(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppType.sans(
            size: 14,
            weight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: AppType.sans(size: 13, color: AppColors.inkFaint),
          ),
        ],
      ],
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(message, style: AppType.sans(color: Colors.white)),
      ),
    );
  }
}
