import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/motion_director.dart';
import '../core/vehicle_ui_tokens.dart';

/// Cinematic floating sheet surface (VisionOS / Apple Maps inspired).
///
/// - Soft translucency (no cheap glassmorphism)
/// - Atmospheric edge lighting
/// - Physically believable depth separation
class CinematicSheet extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    ValueNotifier<double> extent,
  ) builder;

  /// Initial / min / max sizes are expressed as a fraction of screen height.
  final double initialExtent;
  final double minExtent;
  final double maxExtent;

  /// Called whenever the sheet extent changes (0..1 in [minExtent..maxExtent]).
  final ValueChanged<double>? onExtent;
  final MotionDirector? motionDirector;

  const CinematicSheet({
    super.key,
    required this.builder,
    this.initialExtent = 0.38,
    this.minExtent = 0.28,
    this.maxExtent = 0.76,
    this.onExtent,
    this.motionDirector,
  });

  @override
  Widget build(BuildContext context) {
    final extent = ValueNotifier<double>(initialExtent);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        extent.value = n.extent;
        onExtent?.call(n.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: initialExtent,
        minChildSize: minExtent,
        maxChildSize: maxExtent,
        snap: true,
        snapSizes: <double>[
          initialExtent,
          (initialExtent + maxExtent) * 0.5,
          maxExtent,
        ],
        builder: (context, controller) {
          return _CinematicSurface(
            extent: extent,
            motionDirector: motionDirector,
            child: builder(context, controller, extent),
          );
        },
      ),
    );
  }
}

class _CinematicSurface extends StatelessWidget {
  final ValueNotifier<double> extent;
  final MotionDirector? motionDirector;
  final Widget child;

  const _CinematicSurface({
    required this.extent,
    required this.child,
    this.motionDirector,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final r = BorderRadius.circular(VehicleUi.radiusLg);

    return AnimatedBuilder(
      animation: Listenable.merge([
        extent,
        if (motionDirector != null) motionDirector!,
      ]),
      builder: (context, _) {
        // Normalize 0..1 within typical sheet range.
        final local = ((extent.value - 0.26) / 0.5).clamp(0.0, 1.0);
        final directed = motionDirector?.sheetRise ?? 0.0;
        final t = (0.65 * directed + 0.35 * local).clamp(0.0, 1.0);
        final blur = lerpDouble(14, 22, t)!;
        final fillA = lerpDouble(0.86, 0.92, t)!;
        final edgeA = lerpDouble(0.08, 0.14, t)!;

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: r,
                  color: VehicleUi.cardFor(b).withValues(alpha: fillA),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 28,
                      spreadRadius: -14,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: VehicleUi.accentBlueGlow.withValues(alpha: 0.30),
                      blurRadius: 56,
                      spreadRadius: -34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Environmental reflections (subtle).
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: r,
                          gradient: LinearGradient(
                            begin: const Alignment(-1, -1),
                            end: const Alignment(0.7, 0.8),
                            colors: [
                              Colors.white.withValues(alpha: 0.09),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Edge light (ambient blue, restrained).
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: r,
                          border: Border.all(
                            color: VehicleUi.accentBlue.withValues(alpha: edgeA),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    // Content.
                    child,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CinematicGrabber extends StatelessWidget {
  const CinematicGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

