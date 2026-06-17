import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_visual_tokens.dart';

/// Nền gradient tĩnh — cache repaint, không texture.
class WallpaperBackground extends StatelessWidget {
  const WallpaperBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.2, -1.0),
              end: Alignment(0.3, 1.0),
              colors: [
                IosVisualTokens.wallpaperTop,
                IosVisualTokens.wallpaperMid,
                IosVisualTokens.wallpaperDeep,
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.85, -0.45),
              radius: 1.05,
              colors: [
                IosVisualTokens.wallpaperHighlight.withValues(alpha: 0.38),
                IosVisualTokens.wallpaperHighlight.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.03),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.28),
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

/// Panel kính mờ iOS 18 — systemMaterialLight style.
class IosGlassPanel extends StatelessWidget {
  const IosGlassPanel({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.opacity = 0.18,
    this.blurSigma = 42,
    this.shadows,
    this.saturate = true,
    this.bright = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double opacity;
  final double blurSigma;
  final List<BoxShadow>? shadows;
  final bool saturate;
  final bool bright;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(29);
    final topAlpha = bright ? opacity + 0.22 : opacity + 0.14;

    Widget panel = RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.hardEdge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Colors.white.withValues(alpha: opacity),
            border: Border.all(
              color: Colors.white.withValues(alpha: IosVisualTokens.glassBorderOpacity * 0.35),
              width: 0.33,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: topAlpha),
                Colors.white.withValues(alpha: opacity + 0.02),
                Colors.white.withValues(alpha: opacity - 0.04),
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: padding != null ? Padding(padding: padding!, child: child) : child,
        ),
      ),
    ),
    );

    if (saturate) {
      panel = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          _saturationMatrix(IosVisualTokens.glassSaturationBoost),
        ),
        child: panel,
      );
    }

    return panel;
  }

  static List<double> _saturationMatrix(double s) {
    const r = 0.2126;
    const g = 0.7152;
    const b = 0.0722;
    final a = (1 - s) * r;
    final d = (1 - s) * g;
    final e = (1 - s) * b;
    return [
      a + s, d, e, 0, 0,
      a, d + s, e, 0, 0,
      a, d, e + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}

/// Phản chiếu nhẹ trên cạnh trên glass.
class IosGlassHighlight extends StatelessWidget {
  const IosGlassHighlight({
    super.key,
    required this.child,
    this.borderRadius,
    this.subtle = false,
    this.clipContent = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final bool subtle;
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(999);
    return Stack(
      clipBehavior: clipContent ? Clip.hardEdge : Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: radius,
              clipBehavior: Clip.hardEdge,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: subtle ? 0.14 : 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.22],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
