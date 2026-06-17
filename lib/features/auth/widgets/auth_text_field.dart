import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/auth/theme/auth_tokens.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.onToggleObscure,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AuthTokens.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: AnimatedContainer(
            duration: AuthTokens.durationFast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AuthTokens.radiusField),
              border: Border.all(
                color: _focused ? AuthTokens.neonBlue : AuthTokens.glassBorder,
                width: _focused ? 1.5 : 1,
              ),
              boxShadow: _focused ? AuthTokens.glowShadow : null,
              color: const Color(0x1A142235),
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              textInputAction: widget.textInputAction,
              onFieldSubmitted: widget.onSubmitted,
              style: const TextStyle(
                color: AuthTokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AuthTokens.neonBlue,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(color: AuthTokens.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: widget.suffix,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      label: widget.label,
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      suffix: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AuthTokens.textSecondary,
          size: 20,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
