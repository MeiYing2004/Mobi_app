import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';
import 'package:fuel_tracker_app/features/auth/navigation/auth_navigation.dart';
import 'package:fuel_tracker_app/features/premium/theme/premium_tokens.dart';

/// Bottom sheet glassmorphism khi chạm tính năng bị khóa.
class PremiumBottomSheet extends StatelessWidget {
  const PremiumBottomSheet({super.key});

  static const _unlockItems = [
    'Phân tích nhiên liệu',
    'Dự đoán AI',
    'Tối ưu nhiên liệu',
    'Hiệu quả lộ trình',
    'Ước tính chi phí nhiên liệu',
    'Trợ lý AI',
    'Báo cáo PDF',
  ];

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const PremiumBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: LuxuryTokens.blurHeavy,
          sigmaY: LuxuryTokens.blurHeavy,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                LuxuryTokens.backgroundElevated.withValues(alpha: 0.95),
                LuxuryTokens.background.withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(color: LuxuryTokens.glassBorderBright),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(Icons.lock_rounded, color: PremiumTokens.neonCyan, size: 36)
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
              const SizedBox(height: 14),
              const Text(
                '🔒 Yêu cầu Premium',
                style: TextStyle(
                  color: LuxuryTokens.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mở khóa:',
                style: TextStyle(
                  color: LuxuryTokens.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _unlockItems.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: PremiumTokens.neonCyan, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _unlockItems[i],
                        style: const TextStyle(
                          color: LuxuryTokens.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: (40 * i).ms).slideX(begin: 0.05),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AuthNavigation.openPremium(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: PremiumTokens.neonBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Nâng cấp ngay',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Để sau',
                  style: TextStyle(color: LuxuryTokens.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.12, curve: LuxuryTokens.curve);
  }
}
