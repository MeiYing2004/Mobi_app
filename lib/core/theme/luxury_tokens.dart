import 'package:flutter/material.dart';

/// Luxury dark design system — Tesla · Apple Wallet · Linear · Stripe.
abstract final class LuxuryTokens {
  // --- Palette ---
  static const background = Color(0xFF030508);
  static const backgroundElevated = Color(0xFF0A1220);
  static const surfaceGlass = Color(0x66142235);
  static const surfaceGlassHeavy = Color(0x99142235);

  static const neonBlue = Color(0xFF4DA3FF);
  static const neonCyan = Color(0xFF00E5FF);
  static const neonPurple = Color(0xFF7B61FF);
  static const gold = Color(0xFFFFD700);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8B9BB5);
  static const textMuted = Color(0xFF5C6B82);

  // --- Glass ---
  static const blurLight = 16.0;
  static const blurMedium = 24.0;
  static const blurHeavy = 40.0;

  static const glassBorder = Color(0x33FFFFFF);
  static const glassBorderBright = Color(0x664DA3FF);

  // --- Radii ---
  static const radiusSm = 14.0;
  static const radiusMd = 20.0;
  static const radiusLg = 28.0;
  static const radiusXl = 36.0;

  // --- Motion ---
  static const durationFast = Duration(milliseconds: 180);
  static const duration = Duration(milliseconds: 320);
  static const durationSlow = Duration(milliseconds: 520);
  static const curve = Curves.easeOutCubic;
  static const springCurve = Curves.elasticOut;

  // --- Gradients ---
  static const gradientBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonBlue, neonPurple, Color(0x334DA3FF)],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const gradientHero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D2847), Color(0xFF061020), background],
  );

  static const gradientCta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonBlue, Color(0xFF1E5BB8)],
  );

  static const gradientAvatarGlow = RadialGradient(
    colors: [Color(0x664DA3FF), Color(0x004DA3FF)],
  );

  // --- Breakpoints ---
  static bool isMobile(double width) => width < 600;
  static bool isTablet(double width) => width >= 600 && width < 1024;
  static bool isDesktop(double width) => width >= 1024;

  static double drawerWidth(double screenWidth) {
    if (isDesktop(screenWidth)) return 380;
    if (isTablet(screenWidth)) return 340;
    return (screenWidth * 0.88).clamp(280, 360);
  }

  static double contentMaxWidth(double screenWidth) {
    if (isDesktop(screenWidth)) return 960;
    if (isTablet(screenWidth)) return 720;
    return screenWidth;
  }

  static int planColumns(double width) {
    if (isDesktop(width)) return 3;
    if (isTablet(width)) return 3;
    return 1;
  }

  /// Dynamic elevation shadows — depth 0–4.
  static List<BoxShadow> elevation(int level, {Color? glow}) {
    final base = 4.0 + level * 4.0;
    final blur = 12.0 + level * 10.0;
    final alpha = 0.12 + level * 0.06;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: -base,
        offset: Offset(0, base),
      ),
      if (glow != null)
        BoxShadow(
          color: glow.withValues(alpha: 0.18 + level * 0.06),
          blurRadius: blur * 1.6,
          spreadRadius: -blur * 0.5,
          offset: Offset(0, base * 0.5),
        ),
    ];
  }

  static List<BoxShadow> get neonGlow => elevation(3, glow: neonBlue);
}
