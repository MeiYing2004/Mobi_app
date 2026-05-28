import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ios_design_tokens.dart';
import 'vehicle_ui_tokens.dart';

/// Theme tối premium — iPhone 17 Pro Max.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VehicleUi.background,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: IosDesign.neonCyan,
        surface: IosDesign.titanGray,
        error: IosDesign.warningRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: IosDesign.neonCyan,
        thumbColor: IosDesign.neonCyan,
        inactiveTrackColor: IosDesign.titanGrayLight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0A84FF),
        surface: Colors.white,
        error: IosDesign.warningRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF0A84FF),
        thumbColor: const Color(0xFF0A84FF),
        inactiveTrackColor: const Color(0xFFCBD5E1),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
