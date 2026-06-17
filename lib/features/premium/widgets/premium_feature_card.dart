import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fuel_tracker_app/features/premium/theme/premium_tokens.dart';
import 'package:fuel_tracker_app/features/premium/widgets/premium_bottom_sheet.dart';

/// Premium Lock Card — glassmorphism, Tesla / Apple / Linear style.
class PremiumFeatureCard extends StatelessWidget {
  const PremiumFeatureCard({
    super.key,
    required this.title,
    this.subtitle = 'CAO CẤP',
    this.description =
        'Mở khóa phân tích nhiên liệu bằng AI, thống kê chuyến đi và báo cáo hiệu quả.',
    this.features = _defaultFeatures,
    this.icon = Icons.lock_rounded,
    this.onUpgrade,
  });

  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final IconData icon;
  final VoidCallback? onUpgrade;

  static const _defaultFeatures = [
    'Phân tích nhiên liệu',
    'Dự đoán AI',
    'Hiệu quả lộ trình',
    'Ước tính chi phí nhiên liệu',
  ];

  static const _borderColor = Color(0x4050A0FF);
  static const _gradientColors = [Color(0xFF1A3A6E), Color(0xFF0D2244), Color(0xFF081830)];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(PremiumTokens.radiusCard),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _gradientColors,
            ),
            borderRadius: BorderRadius.circular(PremiumTokens.radiusCard),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: PremiumTokens.neonBlue.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PremiumTokens.neonBlue.withValues(alpha: 0.15),
                        border: Border.all(
                          color: PremiumTokens.neonBlue.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(icon, color: PremiumTokens.neonBlue, size: 20),
                    ),
                    const Spacer(),
                    _PremiumBadge(label: subtitle),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PremiumTokens.textPrimary,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: PremiumTokens.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                ...features.map(_FeatureRow.new),
                const SizedBox(height: 20),
                _UpgradeButton(
                  onPressed: onUpgrade ?? () => PremiumBottomSheet.show(context),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumTokens.neonBlue.withValues(alpha: 0.25),
            PremiumTokens.neonCyan.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(PremiumTokens.radiusBadge),
        border: Border.all(color: PremiumTokens.neonCyan.withValues(alpha: 0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: PremiumTokens.neonCyan,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_rounded,
            size: 16,
            color: PremiumTokens.neonCyan.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: PremiumTokens.textPrimary.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeButton extends StatefulWidget {
  const _UpgradeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_UpgradeButton> createState() => _UpgradeButtonState();
}

class _UpgradeButtonState extends State<_UpgradeButton> {
  bool _pressed = false;
  bool _hovered = false;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DA3FF), Color(0xFF2563EB)],
  );

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : (_hovered ? 1.01 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4DA3FF).withValues(alpha: _hovered ? 0.5 : 0.38),
                  blurRadius: _hovered ? 28 : 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'Nâng cấp Premium',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
