import 'package:flutter/material.dart';

/// Hằng số thị giác iOS 18 — chuẩn iPhone 15 Pro (393×852 pt).
abstract final class IosVisualTokens {
  static const double referenceWidth = 393;
  static const double referenceHeight = 852;

  static double scaleW(double width) => width / referenceWidth;
  static double scaleH(double height) => height / referenceHeight;

  // Springboard grid (pt @ 393).
  static const double iconSize = 60;
  static const double columnSpacing = 20;
  static const double horizontalPadding = 46.5;
  static const double labelGap = 8;
  static const double labelLineHeight = 13;
  static const double labelFontSize = 11;
  static const double rowPitch = 110;
  static const double widgetToIconGap = 22;

  // Dynamic Island — rộng giảm 8%, cao 32 pt.
  static const double islandWidth = 116;
  static const double islandHeight = 32;
  static const double islandTop = 6;

  // Dock.
  static const double dockHeight = 80;
  static const double dockIconSize = 64;
  static const double dockCornerRadius = 36;
  static const double dockHorizontalInset = 10;
  static const double dockGapAboveHomeIndicator = 16;

  // Widgets.
  static const double widgetCornerRadius = 29;
  static const double widgetPadding = 14;

  // Home indicator.
  static const double homeIndicatorWidth = 134;
  static const double homeIndicatorHeight = 5;
  static const double homeIndicatorBottom = 7;
  static const double pageDotsAboveDock = 10;

  static const double dockBottomFromScreen =
      homeIndicatorBottom + homeIndicatorHeight + dockGapAboveHomeIndicator;

  static const double iconCornerRatio = 0.2237;

  // Wallpaper — gradient mượt, không texture.
  static const Color wallpaperTop = Color(0xFF142035);
  static const Color wallpaperMid = Color(0xFF1C3250);
  static const Color wallpaperDeep = Color(0xFF060A12);
  static const Color wallpaperHighlight = Color(0xFF3D5A82);

  // Glass — dock sáng, trong, blur mạnh.
  static const double glassBlurStrong = 92;
  static const double glassBlurMedium = 68;
  static const double glassOpacityDock = 0.09;
  static const double glassOpacityWidget = 0.17;
  static const double glassBorderOpacity = 0.5;
  static const double glassSaturationBoost = 1.26;

  static BorderRadius iconRadius(double size) =>
      BorderRadius.circular(size * iconCornerRatio);

  static BorderRadius widgetRadius(double scale) =>
      BorderRadius.circular(widgetCornerRadius * scale);

  /// Bóng icon kiểu Apple — mềm, khuếch tán, một lớp chính.
  static List<BoxShadow> iconShadow(double size, Color tint) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: size * 0.11,
          offset: Offset(0, size * 0.045),
        ),
      ];

  /// Bóng widget — nhẹ, sát bề mặt.
  static List<BoxShadow> widgetShadow(double scale) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 18 * scale,
          offset: Offset(0, 6 * scale),
        ),
      ];
}
