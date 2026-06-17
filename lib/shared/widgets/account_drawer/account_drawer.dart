import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';
import 'package:fuel_tracker_app/core/theme/luxury_widgets.dart';
import 'package:fuel_tracker_app/features/auth/navigation/auth_navigation.dart';
import 'package:fuel_tracker_app/features/premium/premium_manager.dart';
import 'package:fuel_tracker_app/features/premium/widgets/premium_bottom_sheet.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_shell_insets.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';
import 'package:fuel_tracker_app/shared/widgets/account_drawer/account_drawer_header.dart';
import 'package:fuel_tracker_app/shared/widgets/account_drawer/account_drawer_menu_tile.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';

export 'account_drawer_header.dart' show AccountDrawerMenuItem;

/// Navigation drawer — animated glass, blur 40px, gradient border.
class AccountDrawer extends StatelessWidget {
  const AccountDrawer({
    super.key,
    required this.onItemSelected,
    this.onHome,
    this.selectedId,
    this.additionalItems,
  });

  final ValueChanged<String> onItemSelected;
  final VoidCallback? onHome;
  final String? selectedId;
  final List<AccountDrawerMenuItem>? additionalItems;

  static List<AccountDrawerMenuItem> menuForSession(
    UserSessionService session, {
    List<AccountDrawerMenuItem>? additionalItems,
  }) {
    final items = <AccountDrawerMenuItem>[
      const AccountDrawerMenuItem(
        id: 'home',
        title: 'Trang chủ',
        icon: Icons.home_rounded,
      ),
      const AccountDrawerMenuItem(
        id: 'profile',
        title: 'Hồ sơ cá nhân',
        icon: Icons.person_rounded,
        requiresAuth: true,
      ),
      if (!session.isLoggedIn) ...[
        const AccountDrawerMenuItem(
          id: 'login',
          title: 'Đăng nhập',
          icon: Icons.login_rounded,
          requiresGuest: true,
        ),
      ],
      const AccountDrawerMenuItem(
        id: 'premium',
        title: 'Premium',
        icon: Icons.workspace_premium_rounded,
      ),
      const AccountDrawerMenuItem(
        id: 'history',
        title: 'Trip History',
        icon: Icons.history_rounded,
        requiresAuth: true,
      ),
      const AccountDrawerMenuItem(
        id: 'support',
        title: 'Hỗ trợ',
        icon: Icons.support_agent_rounded,
      ),
      const AccountDrawerMenuItem(
        id: 'terms',
        title: 'Điều khoản',
        icon: Icons.description_outlined,
      ),
      if (session.isLoggedIn)
        const AccountDrawerMenuItem(
          id: 'logout',
          title: 'Đăng xuất',
          icon: Icons.logout_rounded,
          requiresAuth: true,
          destructive: true,
        ),
    ];
    if (additionalItems != null && additionalItems.isNotEmpty) {
      items.addAll(additionalItems);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserSessionService>();
    final items = menuForSession(session, additionalItems: additionalItems);
    final shellInsets = IosShellInsets.maybeOf(context);
    final topInset = shellInsets?.top ?? MediaQuery.paddingOf(context).top;
    final bottomInset = shellInsets?.bottom ?? MediaQuery.paddingOf(context).bottom;
    final screenW = MediaQuery.sizeOf(context).width;
    final drawerW = LuxuryTokens.drawerWidth(screenW);

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: drawerW,
        child: GradientGlassPanel(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
          blur: LuxuryTokens.blurHeavy,
          child: Padding(
            padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AccountDrawerHeader(),
                const Divider(
                  color: LuxuryTokens.glassBorder,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AccountDrawerMenuTile(
                        icon: item.icon,
                        title: item.title,
                        destructive: item.destructive,
                        selected: item.id == selectedId,
                        onTap: () => onItemSelected(item.id),
                        animationIndex: index,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).slideX(
          begin: -0.08,
          curve: LuxuryTokens.curve,
          duration: 380.ms,
        );
  }
}

/// Xử lý navigation từ drawer — dùng chung HomeShell & Group3.
abstract final class AccountDrawerActions {
  static Future<void> handle(
    BuildContext context, {
    required String itemId,
    VoidCallback? onHome,
    VoidCallback? closeDrawer,
  }) async {
    closeDrawer?.call();

    switch (itemId) {
      case 'home':
        onHome?.call();
      case 'profile':
        await AuthNavigation.openProfile(context);
      case 'login':
      case 'register':
      case 'forgot_password':
        // Temporary unified auth entry: route all three items to Login.
        await AuthNavigation.openLogin(context);
      case 'premium':
        await AuthNavigation.openPremium(context);
      case 'history':
        final session = context.read<UserSessionService>();
        if (!PremiumManager.canAccess(session, PremiumFeature.tripHistory)) {
          await PremiumBottomSheet.show(context);
        } else {
          await AuthNavigation.openUsageHistory(context);
        }
      case 'support':
        await AuthNavigation.openSupport(context);
      case 'terms':
        await AuthNavigation.openTerms(context);
      case 'logout':
        await context.read<UserSessionService>().logout();
        if (context.mounted) {
          AppToastService.success(
            title: 'Thành công',
            message: 'Đăng xuất thành công',
          );
          await AuthNavigation.openLogin(context, replace: true);
        }
    }
  }
}
