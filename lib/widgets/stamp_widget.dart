import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 여권 입국 도장 위젯. 앱의 시그니처 비주얼.
///
/// 원형 이중 테두리 + 상단 원호 영문 텍스트 + 중앙 도시 스카이라인 실루엣 +
/// 별 3개 + 하단 라벨. 잠금 상태면 흐리게(미해금) 표시한다. 크기·색·텍스트를
/// 받아 지도 마커(소)·도시 목록(중)·상세(대) 어디서나 재사용한다.
class StampWidget extends StatelessWidget {
  const StampWidget({
    super.key,
    required this.size,
    required this.topText,
    required this.bottomText,
    this.color = AppColors.stampRed,
    this.locked = false,
    this.seed = 0,
  });

  final double size;

  /// 상단 원호 텍스트 (보통 영문 대문자, 예: "SEOUL").
  final String topText;

  /// 하단 라벨 (보통 한글, 예: "서울특별시").
  final String bottomText;

  final Color color;

  /// 미해금이면 흐리게 표시.
  final bool locked;

  /// 스카이라인 변주 시드(도시별 다양성).
  final int seed;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = locked
        ? AppColors.inkFaint.withValues(alpha: 0.35)
        : color;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StampPainter(
          color: effectiveColor,
          topText: topText,
          bottomText: bottomText,
          seed: seed,
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  _StampPainter({
    required this.color,
    required this.topText,
    required this.bottomText,
    required this.seed,
  });

  final Color color;
  final String topText;
  final String bottomText;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final stroke = (size.width * 0.022).clamp(1.0, 4.0);

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // 이중 테두리 원
    canvas.drawCircle(center, radius - stroke, ringPaint);
    canvas.drawCircle(center, radius - stroke * 3.2, ringPaint);

    // 상단 원호 텍스트
    _drawArcText(
      canvas,
      center,
      radius - stroke * 5.5,
      topText,
      size.width,
      topArc: true,
    );
    // 하단 원호 텍스트
    _drawArcText(
      canvas,
      center,
      radius - stroke * 5.5,
      bottomText,
      size.width,
      topArc: false,
    );

    // 중앙 도시 스카이라인
    _drawSkyline(canvas, center, radius, size.width);

    // 별 3개 (스카이라인 아래)
    _drawStars(canvas, center, radius, size.width);

    // 빈티지 질감: 약한 노이즈 점 몇 개 (큰 도장에서만)
    if (size.width > 120) {
      _drawInkSpecks(canvas, center, radius);
    }
  }

  void _drawArcText(
    Canvas canvas,
    Offset center,
    double radius,
    String text,
    double canvasWidth, {
    required bool topArc,
  }) {
    if (text.isEmpty) return;
    final fontSize = (canvasWidth * 0.075).clamp(6.0, 18.0);
    final chars = text.characters.toList();
    // 글자 간 각도 간격
    final anglePerChar = (canvasWidth * 0.0016).clamp(0.13, 0.32);
    final totalAngle = anglePerChar * (chars.length - 1);

    // 상단은 12시 중심 위쪽 호, 하단은 6시 중심 아래쪽 호
    final baseAngle = topArc ? -math.pi / 2 : math.pi / 2;

    for (int i = 0; i < chars.length; i++) {
      final t = chars.length == 1 ? 0.0 : (i / (chars.length - 1)) - 0.5;
      final angle = topArc
          ? baseAngle + t * totalAngle
          : baseAngle - t * totalAngle;

      final tp = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: AppType.serif(
            size: fontSize,
            weight: FontWeight.w700,
            color: color,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      // 글자를 호의 접선 방향으로 회전. 하단 호는 뒤집어 정방향 유지.
      final rotation = topArc ? angle + math.pi / 2 : angle - math.pi / 2;
      canvas.rotate(rotation);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  /// 도시 스카이라인 실루엣. seed로 건물 높이를 살짝 변주.
  void _drawSkyline(Canvas canvas, Offset center, double radius, double w) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rnd = math.Random(seed + 7);
    final innerR = radius * 0.52;
    final baseY = center.dy + innerR * 0.45;
    final left = center.dx - innerR;
    final right = center.dx + innerR;
    final spanW = right - left;

    final path = Path()..moveTo(left, baseY);

    // 여러 건물을 좌→우로
    const buildings = 7;
    final bw = spanW / buildings;
    for (int i = 0; i < buildings; i++) {
      final x = left + i * bw;
      // 가운데 건물(타워)을 가장 높게 — 남산타워 느낌
      final isCentral = i == buildings ~/ 2;
      final base = isCentral
          ? innerR * 1.05
          : innerR * (0.4 + rnd.nextDouble() * 0.5);
      final top = baseY - base;
      path.lineTo(x, top);
      path.lineTo(x + bw * 0.78, top);
      path.lineTo(x + bw * 0.78, baseY);
      // 건물 사이 약간의 틈
      path.lineTo(x + bw, baseY);
    }
    path.lineTo(right, baseY);
    path.close();
    canvas.drawPath(path, paint);

    // 중앙 타워 안테나
    final towerX =
        center.dx + bw * 0.39 - (bw * buildings) / 2 + (buildings ~/ 2) * bw;
    final antennaPaint = Paint()
      ..color = color
      ..strokeWidth = (w * 0.012).clamp(0.8, 2.5)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(towerX, baseY - innerR * 1.05),
      Offset(towerX, baseY - innerR * 1.35),
      antennaPaint,
    );
  }

  void _drawStars(Canvas canvas, Offset center, double radius, double w) {
    final starSize = (w * 0.04).clamp(2.5, 9.0);
    final y = center.dy + radius * 0.34;
    final gap = radius * 0.22;
    for (int i = -1; i <= 1; i++) {
      _drawStar(canvas, Offset(center.dx + i * gap, y), starSize);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outer = -math.pi / 2 + i * 2 * math.pi / 5;
      final inner = outer + math.pi / 5;
      final ox = c.dx + r * math.cos(outer);
      final oy = c.dy + r * math.sin(outer);
      final ix = c.dx + (r * 0.42) * math.cos(inner);
      final iy = c.dy + (r * 0.42) * math.sin(inner);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawInkSpecks(Canvas canvas, Offset center, double radius) {
    final rnd = math.Random(seed + 99);
    final paint = Paint()..color = color.withValues(alpha: 0.5);
    for (int i = 0; i < 12; i++) {
      final ang = rnd.nextDouble() * 2 * math.pi;
      final dist = rnd.nextDouble() * radius * 0.9;
      final p = Offset(
        center.dx + dist * math.cos(ang),
        center.dy + dist * math.sin(ang),
      );
      canvas.drawCircle(p, rnd.nextDouble() * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(_StampPainter old) =>
      old.color != color ||
      old.topText != topText ||
      old.bottomText != bottomText ||
      old.seed != seed;
}
