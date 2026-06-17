import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';

/// Glass panel — blur 40px + gradient border.
class GradientGlassPanel extends StatelessWidget {
  const GradientGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.horizontal(right: Radius.circular(28)),
    this.blur = LuxuryTokens.blurHeavy,
    this.padding,
    this.margin,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LuxuryTokens.gradientBorder,
        boxShadow: LuxuryTokens.elevation(2, glow: LuxuryTokens.neonBlue),
      ),
      padding: const EdgeInsets.all(1.2),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LuxuryTokens.surfaceGlassHeavy,
              borderRadius: borderRadius,
            ),
            child: padding != null ? Padding(padding: padding!, child: child) : child,
          ),
        ),
      ),
    );
  }
}

/// Avatar với vòng phát sáng neon.
class GlowingAvatar extends StatefulWidget {
  const GlowingAvatar({
    super.key,
    required this.child,
    this.size = 72,
    this.glowColor = LuxuryTokens.neonBlue,
  });

  final Widget child;
  final double size;
  final Color glowColor;

  @override
  State<GlowingAvatar> createState() => _GlowingAvatarState();
}

class _GlowingAvatarState extends State<GlowingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          width: widget.size + 16,
          height: widget.size + 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.25 + t * 0.25),
                blurRadius: 20 + t * 16,
                spreadRadius: 2 + t * 4,
              ),
            ],
          ),
          child: Center(child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LuxuryTokens.gradientAvatarGlow,
          border: Border.all(
            color: widget.glowColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    );
  }
}

/// Premium badge với shimmer.
class ShimmerPremiumBadge extends StatelessWidget {
  const ShimmerPremiumBadge({
    super.key,
    required this.label,
    this.isPremium = true,
  });

  final String label;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    if (!isPremium) {
      return _StaticBadge(
        label: label,
        color: Colors.white.withValues(alpha: 0.08),
        borderColor: LuxuryTokens.glassBorder,
        textColor: LuxuryTokens.textMuted,
        icon: Icons.person_outline_rounded,
      );
    }

    return _StaticBadge(
      label: label,
      color: LuxuryTokens.neonBlue.withValues(alpha: 0.15),
      borderColor: LuxuryTokens.neonBlue.withValues(alpha: 0.45),
      textColor: LuxuryTokens.neonBlue,
      icon: Icons.workspace_premium_rounded,
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 2200.ms,
          color: LuxuryTokens.neonCyan.withValues(alpha: 0.45),
        )
        .animate()
        .fadeIn(duration: 400.ms);
  }
}

class _StaticBadge extends StatelessWidget {
  const _StaticBadge({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: LuxuryTokens.elevation(1, glow: LuxuryTokens.neonBlue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card nổi kiểu Apple Vision Pro — perspective + hover tilt.
class VisionProFloatingCard extends StatefulWidget {
  const VisionProFloatingCard({
    super.key,
    required this.child,
    this.borderRadius = LuxuryTokens.radiusLg,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 14),
    this.elevation = 3,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final int elevation;

  @override
  State<VisionProFloatingCard> createState() => _VisionProFloatingCardState();
}

class _VisionProFloatingCardState extends State<VisionProFloatingCard> {
  Offset _tilt = Offset.zero;

  void _onHover(PointerEvent e, Size size) {
    final nx = (e.localPosition.dx / size.width - 0.5) * 2;
    final ny = (e.localPosition.dy / size.height - 0.5) * 2;
    setState(() => _tilt = Offset(nx.clamp(-1.0, 1.0), ny.clamp(-1.0, 1.0)));
  }

  void _onExit() => setState(() => _tilt = Offset.zero);

  @override
  Widget build(BuildContext context) {
    final rotateX = _tilt.dy * 0.04;
    final rotateY = -_tilt.dx * 0.04;

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (e) => _onHover(e, Size(constraints.maxWidth, 200)),
          onExit: (_) => _onExit(),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(rotateX)
              ..rotateY(rotateY)
              ..translateByDouble(0.0, _tilt.dy * -2, 0, 1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                        LuxuryTokens.backgroundElevated.withValues(alpha: 0.85),
                      ],
                    ),
                    border: Border.all(color: LuxuryTokens.glassBorderBright),
                    boxShadow: LuxuryTokens.elevation(
                      widget.elevation,
                      glow: LuxuryTokens.neonBlue,
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, curve: LuxuryTokens.curve)
            .slideY(begin: 0.08, curve: LuxuryTokens.curve);
      },
    );
  }
}

/// Parallax nhẹ trên bản đồ — chỉ visual, không đụng logic map.
class MapParallaxShell extends StatefulWidget {
  const MapParallaxShell({super.key, required this.child});

  final Widget child;

  @override
  State<MapParallaxShell> createState() => _MapParallaxShellState();
}

class _MapParallaxShellState extends State<MapParallaxShell>
    with SingleTickerProviderStateMixin {
  Offset _pointer = Offset.zero;
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (e) => setState(() => _pointer = e.localPosition),
      onPointerMove: (e) => setState(() => _pointer = e.localPosition),
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, child) {
          final size = MediaQuery.sizeOf(context);
          final nx = size.width > 0 ? (_pointer.dx / size.width - 0.5) : 0.0;
          final ny = size.height > 0 ? (_pointer.dy / size.height - 0.5) : 0.0;
          final drift = math.sin(_drift.value * math.pi * 2) * 3;
          return Transform.translate(
            offset: Offset(nx * 6 + drift * 0.3, ny * 4 + drift * 0.2),
            child: Transform.scale(
              scale: 1.02,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Nút gradient động — Upgrade CTA.
class AnimatedGradientButton extends StatefulWidget {
  const AnimatedGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shift;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _shift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: LuxuryTokens.durationFast,
        curve: LuxuryTokens.curve,
        child: AnimatedBuilder(
          animation: _shift,
          builder: (context, _) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: enabled ? LuxuryTokens.neonGlow : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1 + _shift.value * 2, -0.5),
                          end: Alignment(1 + _shift.value * 2, 0.5),
                          colors: const [
                            LuxuryTokens.neonCyan,
                            LuxuryTokens.neonBlue,
                            Color(0xFF1E5BB8),
                            LuxuryTokens.neonPurple,
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: widget.loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(widget.icon, color: Colors.white, size: 22),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  widget.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Crown icon với animation xoay nhẹ + glow pulse.
class AnimatedCrownHero extends StatelessWidget {
  const AnimatedCrownHero({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LuxuryTokens.gradientCta,
        boxShadow: LuxuryTokens.neonGlow,
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: Colors.white,
        size: 44,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          curve: Curves.elasticOut,
          duration: 800.ms,
        )
        .then(delay: 200.ms)
        .shimmer(
          duration: 2400.ms,
          color: LuxuryTokens.gold.withValues(alpha: 0.35),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1800.ms,
          curve: Curves.easeInOut,
        );
  }
}
