import 'package:flutter/material.dart';

/// Design tokens — Soft Modern / Glassmorphism + Material 3 (production).
abstract final class SoftModernTokens {
  // --- Surfaces ---
  static const scaffoldBackground = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceGlass = Color(0xF2FFFFFF);
  static const surfaceMuted = Color(0xFFF2F4F8);
  static const bottomSheetBackground = Color(0xFFF0F0F0);

  // --- Header ---
  static const headerGradientStart = Color(0xFFFFFFFF);
  static const headerGradientEnd = Color(0xFFF2F4F8);

  // --- Text ---
  static const textPrimary = Color(0xFF222222);
  static const textBody = Color(0xFF333333);
  static const textSecondary = Color(0xFF666666);
  static const textMuted = Color(0xFF777777);
  static const iconDefault = Color(0xFF666666);

  // --- Accent ---
  static const primary = Color(0xFF1976D2);
  static const itemSelected = Color(0xFFE8F0FE);
  static const itemHover = Color(0xFFF5F5F5);

  // --- Borders & dividers ---
  static const divider = Color(0xFFEEEEEE);

  // --- Radii ---
  static const radiusDrawer = 20.0;
  static const radiusCard = 16.0;
  static const radiusSheet = 20.0;
  static const radiusItem = 12.0;

  // --- Sizing ---
  static const itemHeight = 48.0;
  static const itemHorizontalPadding = 12.0;
  static const avatarSize = 64.0;
  static const drawerMinWidth = 280.0;
  static const drawerMaxWidth = 320.0;
  static const drawerWidthFraction = 0.85;
  static const drawerOuterMargin = 8.0;
  static const safeAreaExtraTop = 10.0;
  static const sheetMarginH = 16.0;
  static const sheetMarginBottom = 24.0;
  static const sheetPadding = 16.0;

  // --- Animation ---
  static const animationFast = Duration(milliseconds: 150);
  static const animationDuration = Duration(milliseconds: 200);
  static const animationSlow = Duration(milliseconds: 250);
  static const tapDelay = Duration(milliseconds: 100);
  static const pressScale = 0.97;
  static const enterScale = 0.92;

  static const curve = Curves.easeInOut;
  static const curveOut = Curves.easeOutCubic;

  // --- Shadows ---
  static List<BoxShadow> get drawerShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 25,
          offset: const Offset(4, 0),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get sheetShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 15,
          offset: const Offset(0, -2),
        ),
      ];

  static List<BoxShadow> get avatarShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static ScrollPhysics get scrollPhysics =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  /// min(320, max(280, screenWidth * 0.85)) — trừ margin tránh overflow.
  static double resolveDrawerWidth(
    double screenWidth, {
    double outerMargin = drawerOuterMargin,
  }) {
    final available = screenWidth - outerMargin;
    final preferred =
        (screenWidth * drawerWidthFraction).clamp(drawerMinWidth, drawerMaxWidth);
    return preferred.clamp(0, available);
  }
}

typedef DrawerTokens = SoftModernTokens;
