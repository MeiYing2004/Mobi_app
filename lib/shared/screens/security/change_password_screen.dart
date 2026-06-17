import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/auth/services/user_service.dart';
import 'package:fuel_tracker_app/features/auth/navigation/auth_navigation.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';
import 'package:fuel_tracker_app/shared/widgets/ios_style_widgets.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty) {
      ToastService.warning(message: 'Vui lòng nhập mật khẩu hiện tại');
      return;
    }
    if (next.trim().length < 6) {
      ToastService.warning(message: 'Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }
    if (next != confirm) {
      ToastService.warning(message: 'Xác nhận mật khẩu không khớp');
      return;
    }

    setState(() => _saving = true);
    try {
      final users = context.read<UserService>();
      final result = await users.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (!mounted) return;

      if (!result.success) {
        ToastService.error(message: result.message ?? users.lastError ?? 'Đổi mật khẩu thất bại');
        return;
      }

      ToastService.success(message: 'Đã đổi mật khẩu');
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionService>();
    if (!session.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFF050816),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text(
            'Đổi mật khẩu',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: IosGlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, color: Color(0xFF0A84FF), size: 34),
                  const SizedBox(height: 12),
                  const Text(
                    'Vui lòng đăng nhập',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bạn cần đăng nhập để đổi mật khẩu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await AuthNavigation.openLogin(context);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0A84FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          IosGlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bảo mật tài khoản',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mật khẩu được lưu cục bộ (data.json) cho bản demo.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                _PasswordField(
                  label: 'Mật khẩu hiện tại',
                  controller: _currentCtrl,
                  obscure: !_showCurrent,
                  onToggle: () => setState(() => _showCurrent = !_showCurrent),
                ),
                const SizedBox(height: 10),
                _PasswordField(
                  label: 'Mật khẩu mới',
                  controller: _newCtrl,
                  obscure: !_showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                ),
                const SizedBox(height: 10),
                _PasswordField(
                  label: 'Xác nhận mật khẩu mới',
                  controller: _confirmCtrl,
                  obscure: !_showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Cập nhật mật khẩu',
                          style: TextStyle(fontWeight: FontWeight.w800),
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 1.4),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}

