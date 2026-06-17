import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/auth/theme/auth_tokens.dart';
import 'package:fuel_tracker_app/features/auth/widgets/auth_button.dart';
import 'package:fuel_tracker_app/features/auth/widgets/auth_scaffold.dart';
import 'package:fuel_tracker_app/features/auth/widgets/auth_text_field.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_tokens.dart';

enum _ForgotStep { email, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  _ForgotStep _step = _ForgotStep.email;
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _info;
  String? _pendingEmail;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Email không hợp lệ');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = context.read<UserSessionService>();
      final ok = await session.sendPasswordResetOtp(email);
      if (!mounted) return;
      setState(() => _loading = false);

      if (!ok) {
        setState(() => _error = session.lastAuthError ?? 'Không gửi được OTP — kiểm tra email');
        return;
      }

      setState(() {
        _pendingEmail = email;
        _step = _ForgotStep.otp;
        _info = 'OTP demo: ${UserSessionService.mockOtp}';
      });
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không gửi được OTP. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = context.read<UserSessionService>();
      final ok = await session.confirmPasswordResetOtp(_otpCtrl.text);
      if (!mounted) return;
      setState(() => _loading = false);

      if (!ok) {
        setState(() => _error = session.lastAuthError ?? 'OTP không đúng');
        return;
      }

      setState(() {
        _step = _ForgotStep.newPassword;
        _error = null;
        _info = null;
      });
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không xác nhận được OTP. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Mật khẩu tối thiểu 6 ký tự');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Mật khẩu không khớp');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = context.read<UserSessionService>();
      final ok = await session.resetPasswordAfterOtp(
        newPassword: _passwordCtrl.text,
        confirmPassword: _confirmCtrl.text,
        email: _pendingEmail,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (!ok) {
        setState(() => _error = session.lastAuthError ?? 'Không thể đặt lại mật khẩu');
        return;
      }

      if (!context.mounted) return;
      Navigator.of(context).pop();
      AppToastService.show(
        context,
        type: ToastType.success,
        title: 'Thành công',
        message: 'Đặt lại mật khẩu thành công',
      );
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không thể đặt lại mật khẩu. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Quên mật khẩu',
      subtitle: switch (_step) {
        _ForgotStep.email => 'Nhập email để nhận mã OTP',
        _ForgotStep.otp => 'Xác nhận mã OTP',
        _ForgotStep.newPassword => 'Đặt mật khẩu mới',
      },
      child: AnimatedSwitcher(
        duration: AuthTokens.duration,
        switchInCurve: AuthTokens.curve,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        child: AuthGlassCard(
          key: ValueKey(_step),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...switch (_step) {
                _ForgotStep.email => [
                    AuthTextField(
                      label: 'Email',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ).animate().fadeIn(),
                  ],
                _ForgotStep.otp => [
                    AuthTextField(
                      label: 'Mã OTP',
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      hint: '6 chữ số',
                    ).animate().fadeIn(),
                  ],
                _ForgotStep.newPassword => [
                    AuthPasswordField(
                      label: 'Mật khẩu mới',
                      controller: _passwordCtrl,
                    ).animate().fadeIn(),
                    const SizedBox(height: 14),
                    AuthPasswordField(
                      label: 'Xác nhận mật khẩu',
                      controller: _confirmCtrl,
                    ).animate().fadeIn(delay: 60.ms),
                  ],
              },
              if (_info != null) ...[
                const SizedBox(height: 12),
                Text(
                  _info!,
                  style: const TextStyle(color: AuthTokens.neonBlue, fontSize: 13),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AuthTokens.error, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: switch (_step) {
                  _ForgotStep.email => 'Gửi OTP',
                  _ForgotStep.otp => 'Xác nhận OTP',
                  _ForgotStep.newPassword => 'Đặt lại mật khẩu mới',
                },
                loading: _loading,
                onPressed: switch (_step) {
                  _ForgotStep.email => _sendOtp,
                  _ForgotStep.otp => _verifyOtp,
                  _ForgotStep.newPassword => _resetPassword,
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
