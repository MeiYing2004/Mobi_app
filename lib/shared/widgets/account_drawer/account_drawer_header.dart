import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';
import 'package:fuel_tracker_app/core/theme/luxury_widgets.dart';
import 'package:fuel_tracker_app/features/premium/widgets/premium_badge.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';
import 'package:fuel_tracker_app/shared/widgets/avatar/user_avatar_widget.dart';
/// Model mục menu drawer tài khoản.
class AccountDrawerMenuItem {
  const AccountDrawerMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.requiresAuth = false,
    this.requiresGuest = false,
    this.destructive = false,
  });

  final String id;
  final String title;
  final IconData icon;
  final bool requiresAuth;
  final bool requiresGuest;
  final bool destructive;
}

/// Header drawer — avatar phát sáng, shimmer badge Premium.
class AccountDrawerHeader extends StatelessWidget {
  const AccountDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(session),
          const SizedBox(height: 18),
          Text(
            session.isLoggedIn ? session.name : 'Khách',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: LuxuryTokens.textPrimary,
              letterSpacing: -0.4,
            ),
          ).animate().fadeIn(delay: 80.ms).slideX(begin: -0.04),
          const SizedBox(height: 6),
          Text(
            session.isLoggedIn ? session.email : 'Đăng nhập để đồng bộ dữ liệu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: LuxuryTokens.textSecondary,
              height: 1.35,
            ),
          ).animate().fadeIn(delay: 120.ms),
          const SizedBox(height: 14),
          PremiumBadge(isPremium: session.isPremiumActive),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserSessionService session) {
    return GlowingAvatar(
      size: 72,
      glowColor: session.isPremiumActive ? LuxuryTokens.gold : LuxuryTokens.neonBlue,
      child: const UserAvatarWidget(size: 72, fontSize: 34),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.85, 0.85),
          curve: Curves.elasticOut,
          duration: 600.ms,
        );
  }
}
