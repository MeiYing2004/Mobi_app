import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';

/// Design tokens — auth screens (dark glass + neon blue).
abstract final class AuthTokens {
  static const background = LuxuryTokens.background;
  static const backgroundMid = LuxuryTokens.backgroundElevated;
  static const backgroundEnd = LuxuryTokens.background;

  static const glassFill = LuxuryTokens.surfaceGlass;
  static const glassBorder = LuxuryTokens.glassBorder;
  static const glassHighlight = Color(0x1A3B7DDF);

  static const primary = VehicleUi.accentBlue;
  static const primaryGlow = Color(0x663B7DDF);
  static const neonBlue = LuxuryTokens.neonBlue;

  static const textPrimary = LuxuryTokens.textPrimary;
  static const textSecondary = LuxuryTokens.textSecondary;
  static const textMuted = LuxuryTokens.textMuted;
  static const error = Color(0xFFFF6B6B);

  static const radiusField = 16.0;
  static const radiusCard = 24.0;
  static const radiusButton = 16.0;

  static const durationFast = Duration(milliseconds: 180);
  static const duration = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;

  static const gradientBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, backgroundMid, backgroundEnd],
  );

  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DA3FF), Color(0xFF1E5BB8), Color(0xFF0D3A7A)],
  );

  static List<BoxShadow> get glowShadow => LuxuryTokens.elevation(2, glow: neonBlue);

  static List<BoxShadow> get cardShadow => LuxuryTokens.elevation(2);
}
