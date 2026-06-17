import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_colors.dart';

/// Design tokens — iPhone 17 Pro Max (logical ~430×932) + Apple premium palette.
class IosDesign {
  IosDesign._();

  /// Kích thước tham chiếu iPhone 17 Pro Max.
  static const double phoneWidth = 430;
  static const double phoneHeight = 932;

  static const Color bgBlack = Color(0xFF000000);
  static const Color titanGray = Color(0xFF2C2C2E);
  static const Color titanGrayLight = Color(0xFF3A3A3C);
  // Replace aggressive neon with calm "electric blue" used for highlights only.
  static const Color neonCyan = AppColors.primaryDark;
  static const Color neonCyanDim = Color(0x663B7DDF);
  static const Color warningRed = AppColors.errorDark;
  static const Color warningRedGlow = Color(0x33E85A4E);

  static const double radiusXL = 28;
  static const double radiusLG = 22;
  static const double radiusMD = 16;
  static const double radiusSM = 12;

  static List<BoxShadow> appleShadow({Color? color, double blur = 24}) => [
        BoxShadow(
          color: (color ?? Colors.black).withValues(alpha: 0.45),
          blurRadius: blur,
          offset: const Offset(0, 12),
        ),
      ];

  static const LinearGradient ambientGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0A0B),
      Color(0xFF1A1A1E),
      Color(0xFF0D1117),
    ],
  );

  static const LinearGradient neonAccentGradient = LinearGradient(
    colors: [neonCyan, Color(0xFF2E6DD0)],
  );
}
