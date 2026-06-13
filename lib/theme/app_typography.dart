import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// 타이포그래피 토큰. 여권 문서 느낌의 세리프 제목 + 깔끔한 산세리프 본문.
///
/// 제목은 Playfair Display(영문) + Nanum Myeongjo(한글) 폴백으로 한·영
/// 모두 세리프를 유지한다. 본문/숫자는 Noto Sans KR.
class AppType {
  AppType._();

  /// 한글 세리프 폴백 패밀리명.
  static final _serifKrFamily = GoogleFonts.nanumMyeongjo().fontFamily!;
  static final _sansKrFamily = GoogleFonts.notoSansKr().fontFamily!;

  /// 디스플레이 세리프 (큰 제목, 도장 텍스트). 영문 Playfair + 한글 명조.
  static TextStyle serif({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    ).copyWith(fontFamilyFallback: [_serifKrFamily]);
  }

  /// 본문 산세리프. 한·영 모두 Noto Sans.
  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    ).copyWith(fontFamilyFallback: [_sansKrFamily]);
  }

  /// 라벨/캡션 (작은 회색 텍스트, 대문자 트래킹).
  static TextStyle label({
    double size = 11,
    Color color = AppColors.inkFaint,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 1.2,
    ).copyWith(fontFamilyFallback: [_sansKrFamily]);
  }
}
