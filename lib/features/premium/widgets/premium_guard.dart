import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/premium/premium_manager.dart';
import 'package:fuel_tracker_app/features/premium/widgets/premium_bottom_sheet.dart';
import 'package:fuel_tracker_app/features/premium/widgets/premium_feature_card.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';

/// Phân quyền Premium — hiển thị preview bị khóa thay vì ẩn hoàn toàn.
class PremiumGuard extends StatelessWidget {
  const PremiumGuard({
    super.key,
    required this.feature,
    required this.child,
    this.lockedPreview,
    this.title,
    this.description,
    this.showLockOverlay = true,
  });

  final PremiumFeature feature;
  final Widget child;
  final Widget? lockedPreview;
  final String? title;
  final String? description;
  final bool showLockOverlay;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionService>();
    final allowed = PremiumManager.canAccess(session, feature);

    if (allowed) return child;

    final preview = lockedPreview ??
        PremiumFeatureCard(
          title: title ?? PremiumManager.featureTitle(feature),
          description: description ??
              'Unlock AI-powered fuel insights, trip analytics and efficiency reports.',
          onUpgrade: () => PremiumBottomSheet.show(context),
        );

    if (!showLockOverlay) return preview;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(opacity: 0.35, child: IgnorePointer(child: child)),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => PremiumBottomSheet.show(context),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: preview,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
