import 'package:flutter/material.dart' hide DrawerHeader;

import 'package:fuel_tracker_app/core/theme/app_spacing.dart';
import 'package:fuel_tracker_app/features/group3_demo/theme/soft_modern_tokens.dart';
import 'package:fuel_tracker_app/features/group3_demo/widgets/drawer/drawer_header.dart';
import 'package:fuel_tracker_app/features/group3_demo/widgets/drawer/drawer_item.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_shell_insets.dart';

/// Model cho một mục menu drawer.
class DrawerMenuEntry {
  const DrawerMenuEntry({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

/// Navigation drawer — full màn hình, nền trắng.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.menuItems,
    required this.selectedId,
    required this.onItemTap,
    this.onCloseToHome,
    this.name = 'Nguyễn Văn A',
    this.email = 'nguyenvana@email.com',
    this.avatarUrl,
  });

  final List<DrawerMenuEntry> menuItems;
  final String? selectedId;
  final ValueChanged<DrawerMenuEntry> onItemTap;
  final VoidCallback? onCloseToHome;
  final String name;
  final String email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final shellInsets = IosShellInsets.maybeOf(context);
    final topInset = shellInsets?.top ?? MediaQuery.paddingOf(context).top;
    final bottomInset = shellInsets?.bottom ?? MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: SoftModernTokens.surface,
      child: Padding(
        padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              name: name,
              email: email,
              avatarUrl: avatarUrl,
              onCloseToHome: onCloseToHome,
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: SoftModernTokens.divider,
            ),
            Expanded(
              child: ListView.separated(
                physics: SoftModernTokens.scrollPhysics,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.small,
                  vertical: AppSpacing.small,
                ),
                itemCount: menuItems.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: SoftModernTokens.divider,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return DrawerItem(
                    icon: item.icon,
                    title: item.title,
                    selected: item.id == selectedId,
                    onTap: () => onItemTap(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// @deprecated Dùng [AppDrawer] thay thế.
typedef AccountDrawer = AppDrawer;
