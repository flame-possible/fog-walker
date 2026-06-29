import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cloud_sync_provider.dart';
import '../providers/profile_provider.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Settings 화면. 계정, 권한, 위치 기록, 지도 설정을 한곳에 모은다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _location = LocationService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<CloudSyncProvider>();
    final settings = context.watch<AppSettingsProvider>();

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
            subtitle: _syncSubtitle(sync),
            onTap: auth.account == null || sync.isSyncing
                ? null
                : () async {
                    final syncProvider = context.read<CloudSyncProvider>();
                    await syncProvider.sync(auth.account);
                    if (!mounted) return;
                    final error = syncProvider.errorMessage;
                    _toast(error == null ? '동기화 완료' : '동기화 실패: $error');
                  },
          ),
          const SizedBox(height: 28),
          _sectionLabel('권한'),
          _actionRow(
            title: '위치 권한',
            subtitle: '권한을 다시 표시',
            onTap: _openLocationSettings,
          ),
          const SizedBox(height: 28),
          _sectionLabel('위치와 기록'),
          _switchRow(
            title: '고정밀 위치',
            subtitle: '더 정확하지만 배터리를 더 사용합니다',
            value: settings.highAccuracy,
            onChanged: context.read<AppSettingsProvider>().setHighAccuracy,
          ),
          _switchRow(
            title: '자동 기록',
            subtitle: '앱 실행 중 위치가 준비되면 기록을 시작합니다',
            value: settings.autoRecord,
            onChanged: context.read<AppSettingsProvider>().setAutoRecord,
          ),
          const SizedBox(height: 28),
          _sectionLabel('지도'),
          _mapStyleRow(settings),
        ],
      ),
    );
  }

  Future<void> _toggleGoogleAccount(AuthProvider auth) async {
    final profile = context.read<ProfileProvider>();
    final sync = context.read<CloudSyncProvider>();
    if (auth.account != null) {
      await auth.signOut();
      profile.clearAccount();
      return;
    }

    final account = await auth.signInWithGoogle();
    if (account != null && mounted) {
      profile.syncAccount(account);
      await sync.sync(account);
    }
  }

  String _syncSubtitle(CloudSyncProvider sync) {
    if (sync.isSyncing) return '동기화 중';
    if (sync.errorMessage != null) return sync.errorMessage!;
    final last = sync.lastSyncedAt;
    if (last == null) return '기기 간 자동 백업 및 복원';
    final hh = last.hour.toString().padLeft(2, '0');
    final mm = last.minute.toString().padLeft(2, '0');
    return '마지막 동기화 $hh:$mm';
  }

  Future<void> _openLocationSettings() async {
    final opened = await _location.openAppSettings();
    if (!opened && mounted) {
      _toast('브라우저 주소창의 위치 권한을 허용한 뒤 다시 확인해 주세요.');
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

  Widget _mapStyleRow(AppSettingsProvider settings) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(child: _rowText('지도 스타일', settings.mapStyle.labelKo)),
          const SizedBox(width: 12),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.paperDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final style in MapStyle.values)
                  _mapStyleOption(settings, style),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapStyleOption(AppSettingsProvider settings, MapStyle style) {
    final selected = settings.mapStyle == style;
    return InkWell(
      onTap: () => settings.setMapStyle(style),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: AppColors.line) : null,
        ),
        child: Text(
          style.labelKo,
          style: AppType.sans(
            size: 13,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.ink : AppColors.inkFaint,
          ),
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
