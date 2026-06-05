import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fuel_tracker_app/core/ios_design_tokens.dart';

/// Glass card kiểu iOS — blur + viền sáng mỏng.
class IosGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final bool glowWarning;

  const IosGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = IosDesign.radiusLG,
    this.blur = 18,
    this.borderColor,
    this.glowWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: 400.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: Container(
        decoration: glowWarning
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: const [
                  BoxShadow(
                    color: IosDesign.warningRedGlow,
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              width: double.infinity,
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: (borderColor ?? IosDesign.neonCyan)
                      .withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thanh Dynamic Island — search + blur.
class DynamicIslandSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final String hint;

  const DynamicIslandSearchBar({
    super.key,
    this.onTap,
    this.hint = 'Tìm cây xăng, địa điểm...',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: IosDesign.titanGray.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: IosDesign.appleShadow(blur: 16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: IosDesign.neonCyan.withValues(alpha: 0.9),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.3, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Stat chip trong floating card.
class IosStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const IosStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? IosDesign.neonCyan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.85)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Nút xe premium — mở Fuel Dashboard.
class PremiumCarFab extends StatelessWidget {
  final VoidCallback onPressed;
  final bool lowFuel;

  const PremiumCarFab({
    super.key,
    required this.onPressed,
    this.lowFuel = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: lowFuel
              ? const LinearGradient(
                  colors: [IosDesign.warningRed, Color(0xFFFF6B6B)],
                )
              : IosDesign.neonAccentGradient,
          boxShadow: [
            BoxShadow(
              color: (lowFuel ? IosDesign.warningRed : IosDesign.neonCyan)
                  .withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_car_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 1800.ms, curve: Curves.easeInOut);
  }
}

/// Vòng tròn nhiên liệu — Apple Wallet / Tesla style.
class CircularFuelGauge extends StatelessWidget {
  final double percent;
  final bool lowFuel;
  final double size;

  const CircularFuelGauge({
    super.key,
    required this.percent,
    this.lowFuel = false,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final p = (percent / 100).clamp(0.0, 1.0);
    final color = lowFuel ? IosDesign.warningRed : IosDesign.neonCyan;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: p,
              strokeWidth: 12,
              backgroundColor: IosDesign.titanGrayLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: 800.ms,
                curve: Curves.easeOutBack,
              ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -1.5,
                ),
              ),
              Text(
                'Nhiên liệu',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Popup cảnh báo kiểu iOS.
Future<void> showIosWarningDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    ),
  );
}
