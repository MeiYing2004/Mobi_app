import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_colors.dart';

/// Premium EV map dashboard — iOS 18 / Apple Maps night aesthetic.
class VehicleUi {
  VehicleUi._();

  // Core palette — alias [AppColors] để đồng bộ theme toàn app.
  static const Color background = AppColors.backgroundDark;
  static const Color card = AppColors.surfaceDark;
  static const Color accentBlue = AppColors.primaryDark;
  static const Color accentBlueGlow = Color(0x263B7DDF);
  static const Color accentBlueInnerGlow = Color(0x4D3B7DDF);
  static const Color successGreen = AppColors.secondaryDark;
  static const Color warningRed = AppColors.errorDark;
  static const Color textPrimary = AppColors.textPrimaryDark;
  static const Color textSecondary = AppColors.textSecondaryDark;

  static const Color surfaceDark = AppColors.backgroundDark;
  static const Color surfaceLight = AppColors.background;

  // Glass (dark) — subtle, not muddy
  static const Color glassFill = Color(0xB3142235);
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color glassEdgeHighlight = Color(0x2EFFFFFF);
  static const Color textMuted = textSecondary;

  static const Color glassFillLight = Color(0x8CFFFFFF);
  static const Color glassBorderLight = Color(0xB3FFFFFF);
  static const Color glassEdgeHighlightLight = Color(0xE6FFFFFF);
  static const Color textMutedLight = Color(0xFF475569);

  static const double radiusSm = 16;
  static const double radiusMd = 20;
  static const double radiusLg = 24;

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6BB6FF), accentBlue],
  );

  static const LinearGradient fuelBarGradient = LinearGradient(
    colors: [accentBlue, Color(0xFF2E68C0)],
  );

  /// Map contrast scrim — improves UI legibility over tiles.
  static const LinearGradient mapContrastGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x4D081120),
      Color(0x16081120),
      Color(0x2D081120),
      Color(0x8A081120),
    ],
    stops: [0.0, 0.42, 0.72, 1.0],
  );

  static const RadialGradient ambientRadialGlow = RadialGradient(
    center: Alignment(0, 0.25),
    radius: 0.9,
    colors: [Color(0x133B7DDF), Color(0x003B7DDF)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient screenVignette = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x2C081120), Color(0x00081120), Color(0x3C081120)],
  );

  static const List<BoxShadow> floatingShadowNear = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 10,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> floatingShadowFar = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 16,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];

  /// Neon luxury glow — Tesla / Linear accent.
  static const Color neonBlue = Color(0xFF4DA3FF);
  static const Color neonCyan = Color(0xFF00E5FF);

  static List<BoxShadow> luxuryGlow({Color color = neonBlue, int depth = 2}) {
    final blur = 12.0 + depth * 8.0;
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.22 + depth * 0.06),
        blurRadius: blur,
        spreadRadius: -4,
        offset: Offset(0, 4 + depth * 2),
      ),
    ];
  }

  static bool _isLight(Brightness b) => b == Brightness.light;

  static Color surfaceFor(Brightness b) => _isLight(b) ? surfaceLight : surfaceDark;
  static Color cardFor(Brightness b) => _isLight(b) ? const Color(0xFFF1F5F9) : card;
  static Color glassFillFor(Brightness b) => _isLight(b) ? glassFillLight : glassFill;
  static Color glassBorderFor(Brightness b) => _isLight(b) ? glassBorderLight : glassBorder;
  static Color glassEdgeHighlightFor(Brightness b) =>
      _isLight(b) ? glassEdgeHighlightLight : glassEdgeHighlight;
  static Color textMutedFor(Brightness b) => _isLight(b) ? textMutedLight : textMuted;

  static List<BoxShadow> floatingShadowNearFor(Brightness b) =>
      _isLight(b) ? floatingShadowNear : floatingShadowNear;

  static List<BoxShadow> floatingShadowFarFor(Brightness b) =>
      _isLight(b) ? floatingShadowFar : floatingShadowFar;

  static Gradient screenVignetteFor(Brightness b) =>
      _isLight(b) ? const LinearGradient(colors: [Colors.transparent, Colors.transparent]) : screenVignette;

  static Gradient ambientRadialGlowFor(Brightness b) =>
      _isLight(b) ? const RadialGradient(colors: [Colors.transparent, Colors.transparent]) : ambientRadialGlow;

  static Gradient mapContrastFor(Brightness b) =>
      _isLight(b) ? const LinearGradient(colors: [Colors.transparent, Colors.transparent]) : mapContrastGradient;

  static TextStyle statValue({Color? color, double size = 26}) => TextStyle(
        color: color ?? textPrimary,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.05,
      );

  static TextStyle statLabel({Color? color}) => TextStyle(
        color: color ?? textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.2,
      );
}
