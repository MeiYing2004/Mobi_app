import 'package:flutter/material.dart';

/// Bảng màu tập trung — tránh hardcode rải rác trong widget.
abstract final class AppColors {
  // --- Light theme (chuẩn slide A05) ---
  static const primary = Color(0xFF0066CC);
  static const secondary = Color(0xFF00CC99);
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF333333);
  static const textSecondary = Color(0xFF64748B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const error = Color(0xFFE85A4E);

  // --- Dark theme (Fuel Tracker night UI) ---
  static const primaryDark = Color(0xFF3B7DDF);
  static const secondaryDark = Color(0xFF00CC99);
  static const backgroundDark = Color(0xFF081120);
  static const surfaceDark = Color(0xFF142235);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFF7E8AA3);
  static const onPrimaryDark = Color(0xFFFFFFFF);
  static const errorDark = Color(0xFFE85A4E);
}
