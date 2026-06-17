import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/shell/screens/home_shell.dart';

/// Compatibility wrapper — UI orchestration lives in [HomeShell].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.inLauncherMode = false});

  /// Đang chạy bên trong LauncherShell — không render chrome iOS giả.
  final bool inLauncherMode;

  @override
  Widget build(BuildContext context) {
    debugPrint('HOME_SCREEN_BUILD');
    return HomeShell(inLauncherMode: inLauncherMode);
  }
}
