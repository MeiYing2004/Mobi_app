import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';

/// Premium luxury dark theme tokens.
abstract final class PremiumTokens {
  static const background = Color(0xFF030508);
  static const backgroundGlow = Color(0xFF0A1A35);
  static const card = Color(0x1A1E3A5F);
  static const cardSelected = Color(0x331E5BB8);
  static const border = Color(0x33FFFFFF);
  static const borderGlow = Color(0x664DA3FF);
  static const neonBlue = Color(0xFF4DA3FF);
  static const neonCyan = Color(0xFF00E5FF);
  static const gold = Color(0xFFFFD700);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF8B9BB5);
  static const textMuted = Color(0xFF5C6B82);

  static const radiusCard = 28.0;
  static const radiusBadge = 10.0;

  static const gradientHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2847), Color(0xFF061020), Color(0xFF030508)],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A6E), Color(0xFF0D2244)],
  );

  static const gradientCta = LinearGradient(
    colors: [Color(0xFF4DA3FF), VehicleUi.accentBlue, Color(0xFF0D3A7A)],
  );

  static List<BoxShadow> get neonGlow => [
        BoxShadow(
          color: neonBlue.withValues(alpha: 0.35),
          blurRadius: 32,
          spreadRadius: -6,
          offset: const Offset(0, 12),
        ),
      ];

  static const benefits = [
    'Phân tích AI không giới hạn',
    'Dự đoán nhiên liệu thông minh',
    'Tính toán quãng đường còn lại',
    'Tối ưu lộ trình',
    'Ước tính chi phí nhiên liệu',
    'Đề xuất trạm nhiên liệu',
    'Báo cáo nâng cao',
    'PDF Export',
    'Excel Export',
    'Trợ lý AI',
    'Lịch sử chuyến đi',
    'Hỗ trợ ưu tiên',
    'Cloud Backup',
    'Đồng bộ đa thiết bị',
  ];
}
