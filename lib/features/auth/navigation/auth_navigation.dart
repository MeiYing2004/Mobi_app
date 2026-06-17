import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/core/theme/app_motion.dart';
import 'package:fuel_tracker_app/features/auth/screens/forgot_password_screen.dart';
import 'package:fuel_tracker_app/features/auth/screens/login_screen.dart';
import 'package:fuel_tracker_app/features/auth/screens/register_screen.dart';
import 'package:fuel_tracker_app/features/auth/screens/support_screen.dart';
import 'package:fuel_tracker_app/features/auth/screens/terms_screen.dart';
import 'package:fuel_tracker_app/features/auth/screens/usage_history_screen.dart';
import 'package:fuel_tracker_app/features/auth/theme/auth_tokens.dart';
import 'package:fuel_tracker_app/features/premium/screens/premium_screen.dart';
import 'package:fuel_tracker_app/shared/screens/profile_settings_sheet.dart';

/// Route helpers — shared axis + fade slide transitions.
abstract final class AuthNavigation {
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(AppMotion.fadeSlide(page));
  }

  static Future<bool?> openLogin(BuildContext context, {bool replace = false}) {
    final route = AppMotion.sharedAxis<bool>(const LoginScreen());
    if (replace) {
      return Navigator.of(context).pushReplacement(route);
    }
    return Navigator.of(context).push(route);
  }

  static Future<bool?> openRegister(BuildContext context) {
    return Navigator.of(context).push<bool>(
      AppMotion.sharedAxis(const RegisterScreen()),
    );
  }

  static Future<void> openForgotPassword(BuildContext context) {
    return push<void>(context, const ForgotPasswordScreen());
  }

  static Future<void> openPremium(BuildContext context) {
    return Navigator.of(context).push<void>(
      AppMotion.fadeSlide(const PremiumScreen()),
    );
  }

  static Future<void> openUsageHistory(BuildContext context) {
    return push<void>(context, const UsageHistoryScreen());
  }

  static Future<void> openSupport(BuildContext context) {
    return push<void>(context, const SupportScreen());
  }

  static Future<void> openTerms(BuildContext context) {
    return push<void>(context, const TermsScreen());
  }

  static Future<void> openProfile(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ProfileSettingsSheet(),
    );
  }
}

double authHeaderTopGap(BuildContext context) {
  final safeTop = MediaQuery.paddingOf(context).top;
  return safeTop > 0 ? 12.0 : 16.0;
}

class AuthDetailHeader extends StatelessWidget {
  const AuthDetailHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, authHeaderTopGap(context), 12, 8),
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AuthTokens.textPrimary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AuthTokens.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Màn placeholder đơn giản — dùng cho support/terms nếu cần mở rộng.
class AuthInfoScaffold extends StatelessWidget {
  const AuthInfoScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final List<String> body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTokens.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthDetailHeader(title: title),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: body.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => Text(
                  body[i],
                  style: const TextStyle(
                    color: AuthTokens.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: (40 * i).ms).slideY(begin: 0.04),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
