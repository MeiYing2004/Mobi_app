import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/features/auth/theme/login_design_tokens.dart';

/// Fuel Tracker brand mark — square logo only (for header alignment).
class LoginLogoMark extends StatelessWidget {
  const LoginLogoMark({super.key, this.compact = false});

  final bool compact;

  static double sizeFor(bool compact) =>
      compact ? LoginDesignTokens.u6 : LoginDesignTokens.u7 + 16;

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(compact);

    return Hero(
      tag: LoginDesignTokens.heroTag,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6BA3D6), Color(0xFF2E5F94), Color(0xFF1A3D6E)],
            ),
            boxShadow: LoginDesignTokens.glow(LoginDesignTokens.accent, intensity: 0.9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5],
                  ),
                ),
              ),
              Icon(
                Icons.local_gas_station_rounded,
                color: Colors.white,
                size: size * 0.44,
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.03, 1.03),
              duration: 2800.ms,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}

/// Large hero logo — Fuel Tracker brand mark with optional brand text.
class LoginLogoHero extends StatelessWidget {
  const LoginLogoHero({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoginLogoMark(compact: compact),
        if (!compact) ...[
          const SizedBox(height: LoginDesignTokens.u2),
          Text('Fuel Tracker', style: LoginDesignTokens.title()),
          const SizedBox(height: LoginDesignTokens.u1 / 2),
          Text(
            'Pro',
            style: LoginDesignTokens.caption(color: LoginDesignTokens.accent),
          ),
        ],
      ],
    );
  }
}

/// Glassmorphism card with gradient border highlight.
class LoginGlassCard extends StatelessWidget {
  const LoginGlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LoginDesignTokens.radiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.04),
            LoginDesignTokens.accent.withValues(alpha: 0.12),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          ...LoginDesignTokens.glow(LoginDesignTokens.accent, intensity: 0.35),
        ],
      ),
      padding: const EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LoginDesignTokens.radiusCard - 1),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LoginDesignTokens.glassFill,
              borderRadius: BorderRadius.circular(LoginDesignTokens.radiusCard - 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(LoginDesignTokens.u3),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom input — no Material TextFormField styling.
class LoginInputField extends StatefulWidget {
  const LoginInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  State<LoginInputField> createState() => _LoginInputFieldState();
}

class _LoginInputFieldState extends State<LoginInputField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: LoginDesignTokens.label()),
        const SizedBox(height: LoginDesignTokens.u1),
        AnimatedContainer(
          duration: LoginDesignTokens.durationFast,
          curve: LoginDesignTokens.curve,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LoginDesignTokens.radiusField),
            color: LoginDesignTokens.fieldFill,
            border: Border.all(
              color: _focused
                  ? LoginDesignTokens.accent.withValues(alpha: 0.75)
                  : LoginDesignTokens.glassBorder,
              width: _focused ? 1.5 : 1,
            ),
            boxShadow: _focused
                ? LoginDesignTokens.glow(LoginDesignTokens.accent, intensity: 0.45)
                : null,
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: LoginDesignTokens.u2),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: _focused ? LoginDesignTokens.accent : LoginDesignTokens.textMuted,
                  ),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  style: LoginDesignTokens.input(),
                  cursorColor: LoginDesignTokens.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: LoginDesignTokens.input(color: LoginDesignTokens.textMuted),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.icon != null ? LoginDesignTokens.u1 : LoginDesignTokens.u2,
                      vertical: LoginDesignTokens.u2,
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
      ],
    );
  }
}

class LoginPasswordField extends StatefulWidget {
  const LoginPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<LoginPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return LoginInputField(
      label: widget.label,
      controller: widget.controller,
      hint: '••••••••',
      icon: Icons.lock_outline_rounded,
      obscureText: !_visible,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      suffix: GestureDetector(
        onTap: () => setState(() => _visible = !_visible),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LoginDesignTokens.u2),
          child: Icon(
            _visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: LoginDesignTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Custom toggle — replaces Material Checkbox.
class LoginRememberToggle extends StatelessWidget {
  const LoginRememberToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: LoginDesignTokens.durationFast,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: value ? LoginDesignTokens.accent : Colors.transparent,
              border: Border.all(
                color: value ? LoginDesignTokens.accent : LoginDesignTokens.glassBorder,
                width: 1.5,
              ),
              boxShadow: value
                  ? LoginDesignTokens.glow(LoginDesignTokens.accent, intensity: 0.35)
                  : null,
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: LoginDesignTokens.u1),
          Flexible(
            child: Text(
              label,
              style: LoginDesignTokens.body(weight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginTextLink extends StatelessWidget {
  const LoginTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: LoginDesignTokens.body(
          color: accent ? LoginDesignTokens.accent : LoginDesignTokens.textSecondary,
          weight: accent ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

/// Animated CTA with shimmer sweep and press scale.
class LoginAnimatedButton extends StatefulWidget {
  const LoginAnimatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<LoginAnimatedButton> createState() => _LoginAnimatedButtonState();
}

class _LoginAnimatedButtonState extends State<LoginAnimatedButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
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
        scale: _pressed ? 0.97 : 1,
        duration: LoginDesignTokens.durationFast,
        curve: LoginDesignTokens.curve,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.5,
          duration: LoginDesignTokens.durationFast,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(LoginDesignTokens.radiusButton),
            child: SizedBox(
              width: double.infinity,
              height: LoginDesignTokens.u6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(decoration: BoxDecoration(gradient: LoginDesignTokens.gradientCta)),
                  if (enabled)
                    AnimatedBuilder(
                      animation: _shimmer,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ShimmerPainter(progress: _shimmer.value),
                        );
                      },
                    ),
                  Center(
                    child: widget.loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.label, style: LoginDesignTokens.button(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final sweep = size.width * 0.35;
    final x = -sweep + (size.width + sweep * 2) * progress;
    final rect = Rect.fromLTWH(x, 0, sweep, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class LoginSocialDivider extends StatelessWidget {
  const LoginSocialDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: LoginDesignTokens.glassBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LoginDesignTokens.u2),
          child: Text('hoặc tiếp tục với', style: LoginDesignTokens.caption()),
        ),
        Expanded(child: Container(height: 1, color: LoginDesignTokens.glassBorder)),
      ],
    );
  }
}

/// Circular social login buttons.
class LoginCircularSocialButtons extends StatelessWidget {
  const LoginCircularSocialButtons({
    super.key,
    required this.onGoogle,
    required this.onFacebook,
    required this.onApple,
  });

  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final VoidCallback onApple;

  bool get _showApple {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialCircleButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google',
          onTap: onGoogle,
        ),
        const SizedBox(width: LoginDesignTokens.u2),
        _SocialCircleButton(
          icon: Icons.facebook_rounded,
          label: 'Facebook',
          onTap: onFacebook,
        ),
        if (_showApple) ...[
          const SizedBox(width: LoginDesignTokens.u2),
          _SocialCircleButton(
            icon: Icons.apple_rounded,
            label: 'Apple',
            onTap: onApple,
          ),
        ],
      ],
    );
  }
}

class _SocialCircleButton extends StatefulWidget {
  const _SocialCircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SocialCircleButton> createState() => _SocialCircleButtonState();
}

class _SocialCircleButtonState extends State<_SocialCircleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: LoginDesignTokens.durationFast,
          child: Container(
            width: LoginDesignTokens.u6,
            height: LoginDesignTokens.u6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LoginDesignTokens.fieldFill,
              border: Border.all(color: LoginDesignTokens.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(widget.icon, color: LoginDesignTokens.textPrimary, size: 26),
          ),
        ),
      ),
    );
  }
}

class LoginGlassBackButton extends StatefulWidget {
  const LoginGlassBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<LoginGlassBackButton> createState() => _LoginGlassBackButtonState();
}

class _LoginGlassBackButtonState extends State<LoginGlassBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const size = LoginDesignTokens.backButtonSize;
    const radius = LoginDesignTokens.backRadius;

    return Semantics(
      button: true,
      label: 'Quay lại',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: LoginDesignTokens.durationFast,
          curve: LoginDesignTokens.curve,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: LoginDesignTokens.backGlassBlur,
                sigmaY: LoginDesignTokens.backGlassBlur,
              ),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: LoginDesignTokens.backGlassFill,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: LoginDesignTokens.backGlassBorder,
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: const Offset(1.5, 0),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: LoginDesignTokens.backIconSize,
                    color: LoginDesignTokens.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header cân đối — back, logo, title trên cùng lưới 8pt.
class LoginScreenHeader extends StatelessWidget {
  const LoginScreenHeader({
    super.key,
    required this.onBack,
    required this.canGoBack,
    this.compact = false,
  });

  final VoidCallback onBack;
  final bool canGoBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = LoginLogoMark.sizeFor(compact);
    final logoGap = compact ? LoginDesignTokens.u2 : LoginDesignTokens.u3;
    final titleGap = compact ? LoginDesignTokens.u2 : LoginDesignTokens.u3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: LoginDesignTokens.backButtonSize,
          child: Row(
            children: [
              SizedBox(
                width: LoginDesignTokens.backButtonSize,
                child: canGoBack
                    ? LoginGlassBackButton(onTap: onBack)
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Đăng nhập',
                    style: LoginDesignTokens.title(
                      color: LoginDesignTokens.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.06),
                ),
              ),
              const SizedBox(width: LoginDesignTokens.backButtonSize),
            ],
          ),
        ),
        SizedBox(height: logoGap),
        SizedBox(
          height: logoSize,
          child: Center(
            child: LoginLogoMark(compact: compact)
                .animate()
                .fadeIn(delay: 60.ms, duration: 420.ms)
                .scale(begin: const Offset(0.88, 0.88), curve: Curves.easeOutBack),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: LoginDesignTokens.u2),
          Text('Fuel Tracker', style: LoginDesignTokens.title(), textAlign: TextAlign.center),
          const SizedBox(height: LoginDesignTokens.u1 / 2),
          Text(
            'Pro',
            style: LoginDesignTokens.caption(color: LoginDesignTokens.accent),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: titleGap),
        const SizedBox(height: LoginDesignTokens.u1),
        Text(
          'Chào mừng trở lại Fuel Tracker Pro',
          style: LoginDesignTokens.body(),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 140.ms),
      ],
    );
  }
}

/// Responsive remember / forgot row — no overflow on narrow screens.
class LoginOptionsRow extends StatelessWidget {
  const LoginOptionsRow({
    super.key,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotPassword,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 300;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoginRememberToggle(
                value: rememberMe,
                onChanged: onRememberChanged,
                label: 'Ghi nhớ đăng nhập',
              ),
              const SizedBox(height: LoginDesignTokens.u1),
              Align(
                alignment: Alignment.centerRight,
                child: LoginTextLink(
                  label: 'Quên mật khẩu?',
                  accent: true,
                  onTap: onForgotPassword,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: LoginRememberToggle(
                value: rememberMe,
                onChanged: onRememberChanged,
                label: 'Ghi nhớ đăng nhập',
              ),
            ),
            const SizedBox(width: LoginDesignTokens.u1),
            LoginTextLink(
              label: 'Quên mật khẩu?',
              accent: true,
              onTap: onForgotPassword,
            ),
          ],
        );
      },
    );
  }
}
