import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';

/// Bọc nội dung màn hình — SafeArea + padding top nhẹ (fix notch).
class SafeScreenBody extends StatelessWidget {
  const SafeScreenBody({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: true,
      child: Padding(
        padding: padding ??
            const EdgeInsets.only(
              top: SoftModernTokens.safeAreaExtraTop,
            ),
        child: child,
      ),
    );
  }
}

/// Nút primary thống nhất design system.
class SoftPrimaryButton extends StatefulWidget {
  const SoftPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool expanded;

  @override
  State<SoftPrimaryButton> createState() => _SoftPrimaryButtonState();
}

class _SoftPrimaryButtonState extends State<SoftPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final button = AnimatedScale(
      scale: _pressed ? SoftModernTokens.pressScale : 1.0,
      duration: SoftModernTokens.animationFast,
      curve: SoftModernTokens.curveOut,
      child: Material(
        color: SoftModernTokens.primary,
        borderRadius: BorderRadius.circular(SoftModernTokens.radiusItem),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: 14,
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
