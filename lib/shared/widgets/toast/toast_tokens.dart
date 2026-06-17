import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ToastType { success, error, warning, info }

/// Toast design tokens — glass card, top floating.
abstract final class ToastTokens {
  static const radius = 20.0;
  static const duration = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;
  static const horizontalMargin = 16.0;
  static const maxWidth = 420.0;
  static const topOffset = 14.0;
  static const blur = 24.0;

  static const successIcon = Color(0xFF22C55E);
  static const errorIcon = Color(0xFFEF4444);
  static const warningIcon = Color(0xFFF59E0B);
  static const infoIcon = Color(0xFF60A5FA);

  static const successDuration = Duration(seconds: 3);
  static const infoDuration = Duration(seconds: 3);
  static const warningDuration = Duration(seconds: 4);
  static const errorDuration = Duration(seconds: 5);

  static TextStyle titleStyle() => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.2,
        height: 1.2,
      );

  static TextStyle messageStyle() => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1.35,
      );

  static List<BoxShadow> shadow(Color glow) => [
        BoxShadow(
          color: glow.withValues(alpha: 0.35),
          blurRadius: 26,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static Gradient gradientFor(ToastType type) => switch (type) {
        ToastType.success => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          ),
        ToastType.error => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF450A0A), Color(0xFFDC2626)],
          ),
        ToastType.warning => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF78350F), Color(0xFFF59E0B)],
          ),
        ToastType.info => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
          ),
      };

  static Color iconColorFor(ToastType type) => switch (type) {
        ToastType.success => successIcon,
        ToastType.error => errorIcon,
        ToastType.warning => warningIcon,
        ToastType.info => infoIcon,
      };

  static Duration durationFor(ToastType type) => switch (type) {
        ToastType.success => successDuration,
        ToastType.info => infoDuration,
        ToastType.warning => warningDuration,
        ToastType.error => errorDuration,
      };
}
