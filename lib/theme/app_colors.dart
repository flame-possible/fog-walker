import 'package:flutter/material.dart';

/// Fog Walker 색상 토큰. 여권/입국 도장 미학에서 추출.
///
/// 도장 빨강을 시그니처로, 거의 검정인 잉크 텍스트와 종이 같은 배경,
/// 여권 카드의 파스텔 홀로그램 그라데이션으로 구성한다.
class AppColors {
  AppColors._();

  /// 시그니처 — 도장 잉크 빨강.
  static const stampRed = Color(0xFFC0392B);
  static const stampRedDeep = Color(0xFF96281B);

  /// 텍스트 잉크.
  static const ink = Color(0xFF1A1A1A);
  static const inkSoft = Color(0xFF4A4A4A);
  static const inkFaint = Color(0xFF9A9A9A);

  /// 종이/배경.
  static const paper = Color(0xFFFCFBF9);
  static const paperDim = Color(0xFFF2F1ED);
  static const line = Color(0xFFE6E4DF);

  /// 안개 오버레이 색 (지도 위 반투명 회백색).
  static const fog = Color(0xFFB9BEC4);

  /// 여권 카드 홀로그램 파스텔.
  static const holoPink = Color(0xFFF7D9E3);
  static const holoBlue = Color(0xFFD6E4F0);
  static const holoMint = Color(0xFFD9F0E6);
  static const holoLilac = Color(0xFFE6DCF0);
  static const holoPeach = Color(0xFFFBE6D6);

  /// 여권 카드 그라데이션 (홀로그램 느낌).
  static const passportGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [holoPink, holoBlue, holoMint, holoLilac],
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  /// 도장 컬러 변주 (도시별 도장에 다양성 부여).
  static const stampPalette = [
    Color(0xFFC0392B), // 빨강
    Color(0xFF2C6E9B), // 파랑
    Color(0xFF2E8B57), // 초록
    Color(0xFF8E44AD), // 보라
    Color(0xFFB7791F), // 황토
    Color(0xFF1A1A1A), // 검정
  ];
}
