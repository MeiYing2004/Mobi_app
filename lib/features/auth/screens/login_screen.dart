import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/auth/navigation/auth_navigation.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/launcher_shell.dart';
import 'package:fuel_tracker_app/features/auth/theme/login_design_tokens.dart';
import 'package:fuel_tracker_app/features/auth/widgets/login/login_mesh_background.dart';
import 'package:fuel_tracker_app/features/auth/widgets/login/login_premium_widgets.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Duration _authTimeout = Duration(seconds: 10);

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = true;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = context.read<UserSessionService>();
    _rememberMe = session.rememberMe;
    if (session.rememberMe && session.email.isNotEmpty) {
      _emailCtrl.text = session.email;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    String? emailError;
    String? passwordError;

    if (!email.contains('@') || email.length < 5) {
      emailError = 'Email không hợp lệ';
    }
    if (password.length < 6) {
      passwordError = 'Tối thiểu 6 ký tự';
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _error = null;
    });

    return emailError == null && passwordError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    debugPrint('LOGIN_BUTTON_PRESSED');
    if (!_validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      debugPrint('AUTH_START');
      final ok = await context
          .read<UserSessionService>()
          .login(
            emailInput: _emailCtrl.text,
            password: _passwordCtrl.text,
            remember: _rememberMe,
          )
          .timeout(_authTimeout);

      if (!mounted) return;

      if (ok) {
        debugPrint('AUTH_SUCCESS');
        await _navigateHome();
        return;
      }
      final session = context.read<UserSessionService>();
      setState(
        () => _error = session.lastAuthError ?? 'Email hoặc mật khẩu không đúng',
      );
      await _showErrorDialog(_error!);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _error = 'Kết nối quá thời gian chờ');
      await _showErrorDialog(_error!);
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        _error = 'Đăng nhập thất bại. Vui lòng thử lại.';
      });
      await _showErrorDialog(_error!);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _social(String provider) async {
    debugPrint('LOGIN_BUTTON_PRESSED');
    setState(() => _loading = true);
    try {
      debugPrint('AUTH_START');
      final ok = await context
          .read<UserSessionService>()
          .socialLogin(provider: provider)
          .timeout(_authTimeout);
      if (!mounted) return;
      if (ok) {
        debugPrint('AUTH_SUCCESS');
        await _navigateHome();
        return;
      }
      final session = context.read<UserSessionService>();
      setState(() {
        _error = session.lastAuthError ?? 'Đăng nhập $provider thất bại';
      });
      await _showErrorDialog(_error!);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _error = 'Kết nối quá thời gian chờ');
      await _showErrorDialog(_error!);
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        _error = 'Đăng nhập thất bại. Vui lòng thử lại.';
      });
      await _showErrorDialog(_error!);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _navigateHome() async {
    if (!mounted) return;
    debugPrint('NAVIGATE_HOME_START');
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LauncherShell()),
      (_) => false,
    );
    debugPrint('NAVIGATE_HOME_SUCCESS');
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng nhập thất bại'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.canPop(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxContent = screenWidth > 600 ? 440.0 : screenWidth;
    final compactHeader = screenWidth < 360 || MediaQuery.sizeOf(context).height < 700;
    final safeTop = MediaQuery.paddingOf(context).top;
    final headerTop = safeTop > 0 ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: LoginDesignTokens.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginMeshBackground(),
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContent),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          LoginDesignTokens.u3,
                            headerTop,
                          LoginDesignTokens.u3,
                          LoginDesignTokens.u3 + bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LoginScreenHeader(
                              onBack: _goBack,
                              canGoBack: canGoBack,
                              compact: compactHeader,
                            ),
                            LoginGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LoginInputField(
                              label: 'Email',
                              controller: _emailCtrl,
                              hint: 'you@email.com',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                            ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.05),
                            if (_emailError != null) ...[
                              const SizedBox(height: LoginDesignTokens.u1 / 2),
                              Text(_emailError!, style: LoginDesignTokens.caption(color: LoginDesignTokens.error)),
                            ],
                            const SizedBox(height: LoginDesignTokens.u2),
                            Focus(
                              focusNode: _passwordFocus,
                              child: LoginPasswordField(
                                label: 'Mật khẩu',
                                controller: _passwordCtrl,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                              ),
                            ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.05),
                            if (_passwordError != null) ...[
                              const SizedBox(height: LoginDesignTokens.u1 / 2),
                              Text(
                                _passwordError!,
                                style: LoginDesignTokens.caption(color: LoginDesignTokens.error),
                              ),
                            ],
                            const SizedBox(height: LoginDesignTokens.u2),
                            LoginOptionsRow(
                              rememberMe: _rememberMe,
                              onRememberChanged: (v) => setState(() => _rememberMe = v),
                              onForgotPassword: () => AuthNavigation.openForgotPassword(context),
                            ).animate().fadeIn(delay: 260.ms),
                            if (_error != null) ...[
                              const SizedBox(height: LoginDesignTokens.u2),
                              Container(
                                padding: const EdgeInsets.all(LoginDesignTokens.u1 + 4),
                                decoration: BoxDecoration(
                                  color: LoginDesignTokens.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(LoginDesignTokens.radiusField),
                                  border: Border.all(
                                    color: LoginDesignTokens.error.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: LoginDesignTokens.error,
                                    ),
                                    const SizedBox(width: LoginDesignTokens.u1),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: LoginDesignTokens.caption(color: LoginDesignTokens.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: LoginDesignTokens.u3),
                            LoginAnimatedButton(
                              label: 'Đăng nhập',
                              loading: _loading,
                              onPressed: _submit,
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.04),
                            const SizedBox(height: LoginDesignTokens.u3),
                            const LoginSocialDivider(),
                            const SizedBox(height: LoginDesignTokens.u2),
                            LoginCircularSocialButtons(
                              onGoogle: () => _social('Google'),
                              onFacebook: () => _social('Facebook'),
                              onApple: () => _social('Apple'),
                            ).animate().fadeIn(delay: 340.ms),
                          ],
                        ),
                      ).animate().fadeIn(delay: 160.ms).scale(begin: const Offset(0.96, 0.96)),
                      const SizedBox(height: LoginDesignTokens.u3),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Chưa có tài khoản? ', style: LoginDesignTokens.body()),
                          LoginTextLink(
                            label: 'Đăng ký',
                            accent: true,
                            onTap: () => AuthNavigation.openRegister(context),
                          ),
                        ],
                      ).animate().fadeIn(delay: 380.ms),
                          ],
                        ),
                      ),
                    ),
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
