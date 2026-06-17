import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fuel_tracker_app/core/theme/app_colors.dart';
import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/core/theme/app_text_styles.dart';

/// Theme toàn app — ThemeData + ColorScheme + TextTheme (chuẩn A05).
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: AppColors.onPrimary,
        ),
        scaffoldBackground: AppColors.background,
        textTheme: AppTextStyles.lightTextTheme(),
        appBarForeground: AppColors.onPrimary,
        appBarBackground: AppColors.primary,
        sliderActive: AppColors.primary,
        sliderInactive: const Color(0xFFCBD5E1),
        systemOverlay: SystemUiOverlayStyle.dark,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryDark,
          onPrimary: AppColors.onPrimaryDark,
          secondary: AppColors.secondaryDark,
          onSecondary: AppColors.onPrimaryDark,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
          error: AppColors.errorDark,
          onError: AppColors.onPrimaryDark,
        ),
        scaffoldBackground: AppColors.backgroundDark,
        textTheme: AppTextStyles.darkTextTheme(),
        appBarForeground: AppColors.textPrimaryDark,
        appBarBackground: Colors.transparent,
        sliderActive: AppColors.primaryDark,
        sliderInactive: const Color(0xFF3A3A3C),
        systemOverlay: SystemUiOverlayStyle.light,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required TextTheme textTheme,
    required Color appBarForeground,
    required Color appBarBackground,
    required Color sliderActive,
    required Color sliderInactive,
    required SystemUiOverlayStyle systemOverlay,
  }) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: GoogleFonts.openSans().fontFamily,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => Icon(
          Icons.arrow_back_ios_new_rounded,
          color: colorScheme.onSurface,
          size: 20,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title(color: appBarForeground),
        systemOverlayStyle: systemOverlay,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTextStyles.bodyMedium(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: AppTextStyles.body(color: colorScheme.onPrimary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: sliderActive,
        thumbColor: sliderActive,
        inactiveTrackColor: sliderInactive,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.textPrimary : AppColors.surfaceDark,
        contentTextStyle: AppTextStyles.bodyMedium(
          color: isLight ? AppColors.onPrimary : AppColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight ? AppColors.surface : AppColors.surfaceDark,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: isLight
            ? AppColors.textSecondary
            : AppColors.textSecondaryDark,
        selectedLabelStyle: AppTextStyles.label(color: colorScheme.primary),
        unselectedLabelStyle: AppTextStyles.label(
          color: isLight
              ? AppColors.textSecondary
              : AppColors.textSecondaryDark,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: isLight
            ? AppColors.textSecondary
            : AppColors.textSecondaryDark,
        labelStyle: AppTextStyles.label(color: colorScheme.primary),
        unselectedLabelStyle: AppTextStyles.label(
          color: isLight
              ? AppColors.textSecondary
              : AppColors.textSecondaryDark,
        ),
        indicatorColor: colorScheme.primary,
      ),
      dividerColor: isLight
          ? AppColors.textSecondary.withValues(alpha: 0.2)
          : AppColors.textSecondaryDark.withValues(alpha: 0.25),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? AppColors.surface : AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isLight
                ? Colors.black.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: isLight
            ? AppColors.surface
            : const Color(0x99142235),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
