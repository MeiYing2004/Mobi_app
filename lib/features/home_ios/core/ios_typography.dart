import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography SF Pro — sắc nét, tracking chuẩn Apple.
abstract final class IosTypography {
  static bool get _useSystemSf =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static String? get displayFamily =>
      _useSystemSf ? '.SF Pro Display' : GoogleFonts.poppins().fontFamily;

  static String? get textFamily =>
      _useSystemSf ? '.SF Pro Text' : GoogleFonts.openSans().fontFamily;

  static TextStyle _finalize(TextStyle style) => style.copyWith(
        inherit: false,
        textBaseline: TextBaseline.alphabetic,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        leadingDistribution: TextLeadingDistribution.even,
      );

  static TextStyle _display({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
  }) {
    if (_useSystemSf) {
      return _finalize(TextStyle(
        fontFamily: displayFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      ));
    }
    return _finalize(GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    ));
  }

  static TextStyle _text({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.white,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    if (_useSystemSf) {
      return _finalize(TextStyle(
        fontFamily: textFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        shadows: shadows,
      ));
    }
    return _finalize(GoogleFonts.openSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    ));
  }

  static TextStyle statusTime(double size) => _display(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.43,
        height: 1.0,
      );

  static TextStyle homeLabel(double size) => _text(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.12,
        height: 1.06,
        shadows: const [
          Shadow(color: Color(0x88000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      );

  static TextStyle widgetTitle(double size) => _text(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.24,
        height: 1.08,
      );

  static TextStyle widgetBody(double size, {Color? color}) => _text(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? Colors.white.withValues(alpha: 0.88),
        letterSpacing: -0.18,
        height: 1.12,
      );

  static TextStyle widgetCaption(double size, {Color? color}) => _text(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? Colors.white.withValues(alpha: 0.65),
        letterSpacing: -0.1,
        height: 1.1,
      );

  static TextStyle widgetLargeNumber(double size) => _display(
        fontSize: size,
        fontWeight: FontWeight.w200,
        letterSpacing: -3.2,
        height: 0.88,
      );

  static TextStyle calendarWeekday(double size) => _text(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFF3B30),
        letterSpacing: 0.45,
        height: 1.0,
      );

  static TextStyle calendarDay(double size) => _display(
        fontSize: size,
        fontWeight: FontWeight.w200,
        color: Colors.black,
        letterSpacing: -2.0,
        height: 0.95,
      );

  static TextStyle calendarFooter(double size) => _text(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: const Color(0x993C3C43),
        letterSpacing: -0.12,
        height: 1.1,
      );
}
