import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../domain/fog_grid.dart';
import '../providers/collection_provider.dart';
import '../providers/fog_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/walk_session_provider.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/fog_painter.dart';

/// 안개 지도 화면. GPS로 걸으면 안개가 걷힌다.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _location = LocationService();

  StreamSubscription<Position>? _posSub;
  LocationStatus _status = LocationStatus.ready;
  LatLng _center = const LatLng(37.5400, 127.0050); // 서울 기본 중심
  String? _currentRegionId;
  bool _followMe = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final status = await _location.ensurePermission();
    if (!mounted) return;
    setState(() => _status = status);

    if (status == LocationStatus.ready) {
      // 빠른 초기 중심: 마지막 위치
      final last = await _location.lastKnown();
      if (last != null && mounted) {
        setState(() => _center = LatLng(last.latitude, last.longitude));
        _mapController.move(_center, 16);
      }
      _startTracking();
    }
  }

  void _startTracking() {
    _posSub?.cancel();
    _posSub = _location.positionStream().listen(_handleLocation);
  }

  /// 실제 GPS 위치 이벤트.
  void _handleLocation(Position pos) {
    _applyPoint(LatLng(pos.latitude, pos.longitude), pos.accuracy);
  }

  /// 위치를 받아 세 Provider를 조율한다(단방향 흐름). 실제 GPS와 디버그
  /// 위치 주입이 공유하는 경로.
  void _applyPoint(LatLng point, double accuracy) {
    final fog = context.read<FogProvider>();
    final walk = context.read<WalkSessionProvider>();
    final collection = context.read<CollectionProvider>();

    // 현재 지역 갱신
    final cell = FogGrid.cellOf(point);
    final regionId = collection.repository.matcher.regionOfCell(cell);

    final update = fog.onLocation(point, accuracy: accuracy);

    if (!update.accepted) return;

    if (walk.isWalking) {
      walk.onMove(
        point,
        newCellCount: update.freshCells.length,
        regionId: regionId,
      );
    }

    if (update.freshCells.isNotEmpty) {
      final unlocked = collection.checkUnlocks(update.freshCells);
      if (unlocked.isNotEmpty) {
        context.read<ProfileProvider>().syncProgress(
          stampCount: collection.unlockedCount,
        );
        _showUnlockSnack(unlocked.length);
      }
    }

    if (mounted) {
      setState(() {
        _center = point;
        _currentRegionId = regionId;
      });
      if (_followMe) _mapController.move(point, _mapController.camera.zoom);
    }
  }

  void _showUnlockSnack(int count) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(
          '새로운 지역 $count곳 해금!',
          style: AppType.sans(color: Colors.white, weight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _recenter() {
    setState(() => _followMe = true);
    _mapController.move(_center, 16);
  }

  @override
  Widget build(BuildContext context) {
    final fog = context.watch<FogProvider>();
    final walk = context.watch<WalkSessionProvider>();

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(fog),
          _buildTopChip(),
          if (_status != LocationStatus.ready) _buildPermissionBanner(),
          _buildRecenterButton(),
          _buildWalkButton(walk),
        ],
      ),
    );
  }

  Widget _buildMap(FogProvider fog) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 16,
        minZoom: 11,
        maxZoom: 18,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _followMe) {
            setState(() => _followMe = false);
          }
        },
        // 디버그: 길게 누른 지점으로 위치를 주입해 안개 걷힘을 시연/검증.
        onLongPress: kDebugMode
            ? (tapPosition, point) {
                setState(() => _followMe = false);
                _applyPoint(point, 10);
              }
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fogwalker.app',
          tileProvider: NetworkTileProvider(),
        ),
        // 안개 오버레이 — 카메라 변경에 자동 반응
        Builder(
          builder: (context) {
            final camera = MapCamera.of(context);
            return IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: FogPainter(
                  camera: camera,
                  visitedCells: fog.visitedCells,
                ),
              ),
            );
          },
        ),
        // 내 위치 발자국 마커
        MarkerLayer(
          markers: [
            Marker(point: _center, width: 44, height: 44, child: _meMarker()),
          ],
        ),
      ],
    );
  }

  Widget _meMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stampRed,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.stampRed.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.directions_walk, color: Colors.white, size: 22),
    );
  }

  Widget _buildTopChip() {
    final collection = context.watch<CollectionProvider>();
    final fog = context.watch<FogProvider>();
    final meta = _currentRegionId != null
        ? collection.repository.byId[_currentRegionId]
        : null;
    final name = meta?.nameKo ?? '서울 어딘가';
    final pct = _currentRegionId != null
        ? collection.clearPercentOf(_currentRegionId!, fog.visitedCells)
        : 0.0;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 18, color: AppColors.ink),
            const SizedBox(width: 7),
            Text(
              name,
              style: AppType.sans(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '${pct.toStringAsFixed(2)}%',
              style: AppType.sans(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.stampRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Positioned(
      right: 16,
      bottom: 110,
      child: Material(
        color: AppColors.paper,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _recenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              _followMe ? Icons.my_location : Icons.location_searching,
              color: _followMe ? AppColors.stampRed : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalkButton(WalkSessionProvider walk) {
    final walking = walk.isWalking;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 28,
      child: Center(
        child: GestureDetector(
          onTap: () => _toggleWalk(walk),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
            decoration: BoxDecoration(
              color: walking ? AppColors.ink : AppColors.stampRed,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: (walking ? AppColors.ink : AppColors.stampRed)
                      .withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  walking ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  walking
                      ? '산책 종료 · ${walk.activeDistanceKm.toStringAsFixed(2)}km'
                      : '산책 시작',
                  style: AppType.sans(
                    size: 15,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleWalk(WalkSessionProvider walk) async {
    if (walk.isWalking) {
      final session = await walk.stop();
      if (session != null && mounted) {
        // 지나간 지역 방문 횟수 기록
        final collection = context.read<CollectionProvider>();
        for (final id in session.regionIds) {
          collection.recordVisit(id);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '산책 완료 · ${session.distanceKm.toStringAsFixed(2)}km · '
              '${session.newCellsCount}칸 발견',
              style: AppType.sans(color: Colors.white),
            ),
            backgroundColor: AppColors.stampRed,
          ),
        );
      }
    } else {
      if (_status != LocationStatus.ready) {
        await _initLocation();
        if (_status != LocationStatus.ready) return;
      }
      walk.start();
    }
  }

  Widget _buildPermissionBanner() {
    String msg;
    String action;
    VoidCallback onTap;
    switch (_status) {
      case LocationStatus.serviceDisabled:
        msg = '위치 서비스(GPS)가 꺼져 있어요.';
        action = '다시 시도';
        onTap = _initLocation;
        break;
      case LocationStatus.deniedForever:
        msg = '안개를 걷으려면 위치 권한이 필요해요.';
        action = '설정 열기';
        onTap = () => _location.openAppSettings();
        break;
      case LocationStatus.denied:
        msg = '안개를 걷으려면 위치 권한이 필요해요.';
        action = '권한 허용';
        onTap = _initLocation;
        break;
      case LocationStatus.ready:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 64,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: AppType.sans(size: 13, color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(
                action,
                style: AppType.sans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.holoPink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
