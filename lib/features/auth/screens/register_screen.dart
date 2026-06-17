import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/auth/navigation/auth_navigation.dart';
import 'package:fuel_tracker_app/features/auth/theme/auth_tokens.dart';
import 'package:fuel_tracker_app/features/auth/widgets/auth_button.dart';
import 'package:fuel_tracker_app/features/auth/widgets/auth_scaffold.dart';
import 'package:fuel_tracker_app/features/auth/widgets/auth_text_field.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _agreed = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_agreed) {
      setState(() => _error = 'Vui lòng đồng ý điều khoản sử dụng');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await context.read<UserSessionService>().register(
            fullName: _nameCtrl.text,
            emailInput: _emailCtrl.text,
            phoneInput: _phoneCtrl.text,
            password: _passwordCtrl.text,
            confirmPassword: _confirmCtrl.text,
          );

      if (!mounted) return;
      setState(() => _loading = false);

      if (ok) {
        if (!context.mounted) return;
        Navigator.of(context).pop(true);
        return;
      }
      final session = context.read<UserSessionService>();
      setState(() => _error = session.lastAuthError ?? 'Không thể đăng ký. Kiểm tra lại thông tin.');
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Đăng ký thất bại. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Đăng ký',
      subtitle: 'Tạo tài khoản Fuel Tracker Pro',
      child: AuthGlassCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                label: 'Họ tên',
                controller: _nameCtrl,
                hint: 'Nguyễn Văn A',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nhập họ tên' : null,
              ).animate().fadeIn(delay: 60.ms),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Email không hợp lệ' : null,
              ).animate().fadeIn(delay: 90.ms),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Số điện thoại',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                hint: '09xx xxx xxx',
              ).animate().fadeIn(delay: 120.ms),
              const SizedBox(height: 14),
              AuthPasswordField(
                label: 'Mật khẩu',
                controller: _passwordCtrl,
                validator: (v) =>
                    v == null || v.length < 6 ? 'Tối thiểu 6 ký tự' : null,
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 14),
              AuthPasswordField(
                label: 'Nhập lại mật khẩu',
                controller: _confirmCtrl,
                validator: (v) => v != _passwordCtrl.text
                    ? 'Mật khẩu không khớp'
                    : null,
              ).animate().fadeIn(delay: 180.ms),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      activeColor: AuthTokens.neonBlue,
                      side: const BorderSide(color: AuthTokens.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => AuthNavigation.openTerms(context),
                      child: const Text.rich(
                        TextSpan(
                          text: 'Tôi đồng ý với ',
                          style: TextStyle(color: AuthTokens.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Điều khoản sử dụng',
                              style: TextStyle(
                                color: AuthTokens.neonBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AuthTokens.error, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'Tạo tài khoản',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(color: AuthTokens.textMuted, fontSize: 14),
                  ),
                  AuthTextLink(
                    label: 'Đăng nhập',
                    highlight: true,
                    onTap: () => AuthNavigation.openLogin(context, replace: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
