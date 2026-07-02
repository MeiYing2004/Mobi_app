import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/features/auth/theme/auth_tokens.dart';

/// Khung màn auth — gradient nền + glow + glass card.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final titleGap = safeTop > 0 ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: AuthTokens.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: AuthTokens.gradientBackground)),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AuthTokens.primaryGlow.withValues(alpha: 0.5),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) SizedBox(height: titleGap),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showBack)
                        Animate(
                          effects: const [
                            FadeEffect(duration: AuthTokens.durationFast),
                            SlideEffect(
                              begin: Offset(-0.1, 0),
                              end: Offset.zero,
                              duration: AuthTokens.durationFast,
                              curve: AuthTokens.curve,
                            ),
                          ],
                          child: _GlassIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: onBack ?? () => Navigator.maybePop(context),
                          ),
                        ),
                      if (showBack) const SizedBox(width: 12),
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AuthTokens.textPrimary,
                              letterSpacing: -0.6,
                              height: 1.15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 60.ms, duration: 260.ms),
                if (title != null && subtitle != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AuthTokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuthTokens.radiusCard),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AuthTokens.glassFill,
            borderRadius: BorderRadius.circular(AuthTokens.radiusCard),
            border: Border.all(color: AuthTokens.glassBorder),
            boxShadow: AuthTokens.cardShadow,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatefulWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: AuthTokens.durationFast,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AuthTokens.glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuthTokens.glassBorder),
          ),
          child: Icon(widget.icon, color: AuthTokens.textPrimary, size: 20),
        ),
      ),
    );
  }
}
