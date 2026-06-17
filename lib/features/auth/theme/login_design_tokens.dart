import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';

/// Login screen design system — 8px grid, premium dark glass.
abstract final class LoginDesignTokens {
  // --- 8px grid ---
  static const u1 = 8.0;
  static const u2 = 16.0;
  static const u3 = 24.0;
  static const u4 = 32.0;
  static const u5 = 40.0;
  static const u6 = 48.0;
  static const u7 = 56.0;

  // --- Header chrome (Apple / Linear) ---
  static const headerTopInset = 12.0;
  static const backButtonLeft = 20.0;
  static const backButtonSize = 44.0;
  static const backIconSize = 24.0;
  static const backRadius = 12.0;
  static const backGlassBlur = 8.0;
  static const backGlassFill = Color(0x240E1628);
  static const backGlassBorder = Color(0x1AFFFFFF);
  static const background = LuxuryTokens.background;
  static const meshBlue = Color(0xFF1A4D8C);
  static const meshPurple = Color(0xFF3D2B7A);
  static const meshCyan = Color(0xFF0E4A5A);
  static const accent = LuxuryTokens.neonBlue;
  static const accentSoft = Color(0x334DA3FF);
  static const glassFill = Color(0x520E1628);
  static const glassBorder = Color(0x38FFFFFF);
  static const glassHighlight = Color(0x18FFFFFF);
  static const fieldFill = Color(0x280A1220);
  static const textPrimary = LuxuryTokens.textPrimary;
  static const textSecondary = LuxuryTokens.textSecondary;
  static const textMuted = LuxuryTokens.textMuted;
  static const error = Color(0xFFFF6B7A);

  // --- Radii ---
  static const radiusField = 14.0;
  static const radiusCard = 28.0;
  static const radiusButton = 16.0;
  static const radiusPill = 999.0;

  // --- Motion ---
  static const durationFast = LuxuryTokens.durationFast;
  static const duration = LuxuryTokens.duration;
  static const curve = LuxuryTokens.curve;

  static const heroTag = 'fuel_tracker_auth_logo';

  static TextStyle display({Color? color}) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.1,
        color: color ?? textPrimary,
      );

  static TextStyle title({Color? color}) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
        color: color ?? textPrimary,
      );

  static TextStyle body({Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: weight,
        height: 1.45,
        color: color ?? textSecondary,
      );

  static TextStyle label({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color ?? textMuted,
      );

  static TextStyle input({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: color ?? textPrimary,
      );

  static TextStyle button({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color ?? textPrimary,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: color ?? textMuted,
      );

  static const gradientCta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5BB8FF), Color(0xFF3B7DDF), Color(0xFF1E4A9A)],
  );

  static List<BoxShadow> glow(Color color, {double intensity = 1}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35 * intensity),
          blurRadius: 32 * intensity,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.15 * intensity),
          blurRadius: 64 * intensity,
          spreadRadius: 8,
        ),
      ];
}
