import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain/fog_grid.dart';
import '../theme/app_colors.dart';

/// 지도 위에 안개를 그리고 방문한 셀을 "걷어내는" 페인터.
///
/// 화면 전체를 반투명 안개로 덮은 뒤, 보이는 영역 안의 방문 셀마다
/// [BlendMode.clear]로 부드러운 원을 뚫는다. 줌에 따라 원 반경을 스케일해
/// 실제 50m 셀 크기에 맞춘다.
class FogPainter extends CustomPainter {
  FogPainter({
    required this.camera,
    required this.visitedCells,
  });

  final MapCamera camera;
  final Set<(int, int)> visitedCells;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 레이어를 분리해 BlendMode.clear가 안개에만 작용하도록 한다.
    canvas.saveLayer(rect, Paint());

    // 1) 화면 전체를 안개로 덮는다.
    final fogPaint = Paint()..color = AppColors.fog.withValues(alpha: 0.95);
    canvas.drawRect(rect, fogPaint);

    if (visitedCells.isNotEmpty) {
      // 2) 줌에 맞춘 원 반경(픽셀) 계산.
      final radiusPx = _cellRadiusPx();
      // 부드러운 가장자리.
      final clearPaint = Paint()
        ..blendMode = BlendMode.clear
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, radiusPx * 0.35);

      // 3) 보이는 영역 + 여유 안의 셀만 그린다(성능).
      final visibleBounds = _expandedVisibleBounds(radiusPx);
      for (final cell in visitedCells) {
        final center = FogGrid.cellCenter(cell);
        if (!visibleBounds.contains(center)) continue;
        final offset = camera.latLngToScreenOffset(center);
        canvas.drawCircle(offset, radiusPx, clearPaint);
      }
    }

    canvas.restore();
  }

  /// 50m가 현재 줌에서 몇 픽셀인지 계산. 두 LatLng의 화면 거리로 환산.
  double _cellRadiusPx() {
    final c = camera.center;
    const deltaLat = 0.00045; // ≈ 50m
    final p1 = camera.latLngToScreenOffset(c);
    final p2 = camera.latLngToScreenOffset(
      LatLng(c.latitude + deltaLat, c.longitude),
    );
    final dy = (p2.dy - p1.dy).abs();
    // 셀 크기보다 크게 잡아 인접 원들이 확실히 겹쳐 길이 매끄럽게 이어지도록.
    final r = dy * 1.4;
    return r.clamp(10.0, 400.0);
  }

  /// 화면에 보이는 위경도 범위를 반경만큼 넓힌 것.
  LatLngBounds _expandedVisibleBounds(double radiusPx) {
    final visible = camera.visibleBounds;
    final c = camera.center;
    final pCenter = camera.latLngToScreenOffset(c);
    final latLngOff = camera.screenOffsetToLatLng(
      Offset(pCenter.dx + radiusPx, pCenter.dy + radiusPx),
    );
    final padLat = (latLngOff.latitude - c.latitude).abs();
    final padLng = (latLngOff.longitude - c.longitude).abs();
    return LatLngBounds(
      LatLng(visible.south - padLat, visible.west - padLng),
      LatLng(visible.north + padLat, visible.east + padLng),
    );
  }

  @override
  bool shouldRepaint(FogPainter old) =>
      old.camera != camera ||
      !identical(old.visitedCells, visitedCells) ||
      old.visitedCells.length != visitedCells.length;
}
