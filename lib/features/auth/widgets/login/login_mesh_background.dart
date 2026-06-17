import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/auth/theme/login_design_tokens.dart';

/// Animated mesh gradient with floating glow orbs.
class LoginMeshBackground extends StatefulWidget {
  const LoginMeshBackground({super.key});

  @override
  State<LoginMeshBackground> createState() => _LoginMeshBackgroundState();
}

class _LoginMeshBackgroundState extends State<LoginMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final t = _drift.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: LoginDesignTokens.background),
            CustomPaint(
              painter: _MeshGradientPainter(progress: t),
              size: Size.infinite,
            ),
            _GlowOrb(
              top: -60 + math.sin(t * math.pi * 2) * 20,
              left: -40,
              size: 220,
              color: LoginDesignTokens.meshBlue,
              blur: 80,
            ),
            _GlowOrb(
              top: 120 + math.cos(t * math.pi * 2) * 30,
              right: -80,
              size: 260,
              color: LoginDesignTokens.meshPurple,
              blur: 90,
            ),
            _GlowOrb(
              bottom: 80 + math.sin(t * math.pi * 2 + 1) * 24,
              left: 40,
              size: 200,
              color: LoginDesignTokens.meshCyan,
              blur: 70,
            ),
            _GlowOrb(
              bottom: -40,
              right: 20,
              size: 180,
              color: LoginDesignTokens.accent.withValues(alpha: 0.55),
              blur: 60,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: const SizedBox.expand(),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.blur,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: blur,
                spreadRadius: blur * 0.15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shift = progress * math.pi * 2;
    final paints = [
      _radial(
        Offset(size.width * (0.2 + math.sin(shift) * 0.05), size.height * 0.15),
        size.width * 0.55,
        const [Color(0xFF1A3A6E), Color(0x00030508)],
      ),
      _radial(
        Offset(size.width * (0.85 + math.cos(shift) * 0.04), size.height * 0.28),
        size.width * 0.5,
        const [Color(0xFF2E1F5C), Color(0x00030508)],
      ),
      _radial(
        Offset(size.width * 0.5, size.height * (0.72 + math.sin(shift + 1) * 0.03)),
        size.width * 0.65,
        const [Color(0xFF0C3D4A), Color(0x00030508)],
      ),
      _radial(
        Offset(size.width * 0.12, size.height * 0.82),
        size.width * 0.4,
        const [Color(0xFF1E4A9A), Color(0x00030508)],
      ),
    ];

    for (final p in paints) {
      canvas.drawRect(Offset.zero & size, p);
    }
  }

  Paint _radial(Offset center, double radius, List<Color> colors) {
    return Paint()
      ..shader = RadialGradient(
        colors: colors,
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
