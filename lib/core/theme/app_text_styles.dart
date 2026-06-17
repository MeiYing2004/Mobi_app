import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fuel_tracker_app/core/theme/app_colors.dart';

/// Typography tập trung — Poppins (headline), Open Sans (body).
abstract final class AppTextStyles {
  static TextStyle displayLarge({Color? color}) => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.15,
      );

  static TextStyle heading({Color? color}) => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  static TextStyle title({Color? color}) => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.25,
      );

  static TextStyle titleSmall({Color? color}) => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle body({Color? color}) => GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle label({Color? color}) => GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.35,
      );

  /// [TextTheme] cho light mode.
  static TextTheme lightTextTheme() => TextTheme(
        displayLarge: displayLarge(color: AppColors.textPrimary),
        displayMedium: title(color: AppColors.textPrimary),
        displaySmall: titleSmall(color: AppColors.textPrimary),
        headlineLarge: heading(color: AppColors.textPrimary),
        headlineMedium: title(color: AppColors.textPrimary),
        headlineSmall: titleSmall(color: AppColors.textPrimary),
        titleLarge: heading(color: AppColors.textPrimary),
        titleMedium: title(color: AppColors.textPrimary),
        titleSmall: titleSmall(color: AppColors.textPrimary),
        bodyLarge: body(color: AppColors.textPrimary),
        bodyMedium: body(color: AppColors.textPrimary),
        bodySmall: bodyMedium(color: AppColors.textSecondary),
        labelLarge: label(color: AppColors.textSecondary),
        labelMedium: label(color: AppColors.textSecondary),
        labelSmall: label(color: AppColors.textSecondary),
      );

  /// [TextTheme] cho dark mode.
  static TextTheme darkTextTheme() => TextTheme(
        displayLarge: displayLarge(color: AppColors.textPrimaryDark),
        displayMedium: title(color: AppColors.textPrimaryDark),
        displaySmall: titleSmall(color: AppColors.textPrimaryDark),
        headlineLarge: heading(color: AppColors.textPrimaryDark),
        headlineMedium: title(color: AppColors.textPrimaryDark),
        headlineSmall: titleSmall(color: AppColors.textPrimaryDark),
        titleLarge: heading(color: AppColors.textPrimaryDark),
        titleMedium: title(color: AppColors.textPrimaryDark),
        titleSmall: titleSmall(color: AppColors.textPrimaryDark),
        bodyLarge: body(color: AppColors.textPrimaryDark),
        bodyMedium: body(color: AppColors.textPrimaryDark),
        bodySmall: bodyMedium(color: AppColors.textSecondaryDark),
        labelLarge: label(color: AppColors.textSecondaryDark),
        labelMedium: label(color: AppColors.textSecondaryDark),
        labelSmall: label(color: AppColors.textSecondaryDark),
      );
}
