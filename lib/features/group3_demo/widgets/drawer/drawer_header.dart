import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';

/// Header drawer — gradient nhẹ, avatar 64dp, typography thống nhất.
class DrawerHeader extends StatelessWidget {
  const DrawerHeader({
    super.key,
    this.name = 'Nguyễn Văn A',
    this.email = 'nguyenvana@email.com',
    this.avatarUrl,
    this.onCloseToHome,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onCloseToHome;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SoftModernTokens.headerGradientStart,
            SoftModernTokens.headerGradientEnd,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.small,
          AppSpacing.medium,
          AppSpacing.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onCloseToHome != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                child: TextButton.icon(
                  onPressed: onCloseToHome,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: SoftModernTokens.textPrimary,
                  ),
                  label: const Text(
                    'Về trang chính',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: SoftModernTokens.textPrimary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            _buildAvatar(),
            const SizedBox(height: AppSpacing.medium),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: SoftModernTokens.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: SoftModernTokens.textMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    const radius = SoftModernTokens.avatarSize / 2;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SoftModernTokens.surface,
        boxShadow: SoftModernTokens.avatarShadow,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: SoftModernTokens.surface,
        backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
            ? NetworkImage(avatarUrl!)
            : null,
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? const Icon(
                Icons.person_rounded,
                size: 32,
                color: SoftModernTokens.iconDefault,
              )
            : null,
      ),
    );
  }
}
