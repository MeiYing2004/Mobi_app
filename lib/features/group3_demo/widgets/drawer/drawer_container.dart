import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';

/// Shell drawer — glass effect + shadow mềm, bo góc phải 20dp.
class DrawerContainer extends StatelessWidget {
  const DrawerContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(SoftModernTokens.radiusDrawer),
        ),
        boxShadow: SoftModernTokens.drawerShadow,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(SoftModernTokens.radiusDrawer),
        ),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: SoftModernTokens.surfaceGlass,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(SoftModernTokens.radiusDrawer),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
