import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/app_runtime_guard.dart';
import 'package:fuel_tracker_app/core/author_integrity_guard.dart';
import 'package:fuel_tracker_app/core/app_theme.dart';
import 'package:fuel_tracker_app/core/web_lan_runtime.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/launcher_shell.dart';
import 'package:fuel_tracker_app/shared/providers/app_providers.dart';
import 'package:fuel_tracker_app/shared/services/notification_service.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';
import 'package:fuel_tracker_app/shared/widgets/iphone_17_pro_max_frame.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';
import 'package:fuel_tracker_app/shared/widgets/web_lan_debug_overlay.dart';

Future<void> main() async {
  await AppRuntimeGuard.run(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AuthorIntegrityGuard.enforce();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final notificationService = NotificationService();
    await notificationService.init();

    WebLanRuntime.logStartup();

    runApp(FuelTrackerApp(notificationService: notificationService));
  });
}

class FuelTrackerApp extends StatelessWidget {
  final NotificationService notificationService;

  const FuelTrackerApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: AppProviders(
        notificationService: notificationService,
        child: const _ThemedAppRoot(),
      ),
    );
  }
}

class _ThemedAppRoot extends StatelessWidget {
  const _ThemedAppRoot();

  @override
  Widget build(BuildContext context) {
    // Chỉ rebuild MaterialApp khi đổi darkMode — tránh reset navigator khi login.
    return Selector<UserSessionService, bool>(
      selector: (_, session) => session.darkMode,
      builder: (context, darkMode, _) {
        return MaterialApp(
          navigatorKey: ToastService.navigatorKey,
          title: 'Fuel Tracker Pro',
          debugShowCheckedModeBanner: false,
          themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          builder: (context, child) {
            Widget body = IPhone17ProMaxAppShell(
              edgeToEdgeContent: true,
              child: child,
            );
            if (kDebugMode && kIsWeb && WebLanRuntime.hasInfo) {
              body = Stack(
                fit: StackFit.expand,
                children: [
                  body,
                  const WebLanDebugOverlay(),
                ],
              );
            }
            return body;
          },
          home: const LauncherShell(),
        );
      },
    );
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/app_runtime_guard.dart';
import 'package:fuel_tracker_app/core/author_integrity_guard.dart';
import 'package:fuel_tracker_app/core/app_theme.dart';
import 'package:fuel_tracker_app/core/web_lan_runtime.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/launcher_shell.dart';
import 'package:fuel_tracker_app/shared/providers/app_providers.dart';
import 'package:fuel_tracker_app/shared/services/notification_service.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';
import 'package:fuel_tracker_app/shared/widgets/iphone_17_pro_max_frame.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';
import 'package:fuel_tracker_app/shared/widgets/web_lan_debug_overlay.dart';

Future<void> main() async {
  await AppRuntimeGuard.run(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AuthorIntegrityGuard.enforce();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final notificationService = NotificationService();
    await notificationService.init();

    WebLanRuntime.logStartup();

    runApp(FuelTrackerApp(notificationService: notificationService));
  });
}

class FuelTrackerApp extends StatelessWidget {
  final NotificationService notificationService;

  const FuelTrackerApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: AppProviders(
        notificationService: notificationService,
        child: const _ThemedAppRoot(),
      ),
    );
  }
}

class _ThemedAppRoot extends StatelessWidget {
  const _ThemedAppRoot();

  @override
  Widget build(BuildContext context) {
    // Chỉ rebuild MaterialApp khi đổi darkMode — tránh reset navigator khi login.
    return Selector<UserSessionService, bool>(
      selector: (_, session) => session.darkMode,
      builder: (context, darkMode, _) {
        return MaterialApp(
          navigatorKey: ToastService.navigatorKey,
          title: 'Fuel Tracker Pro',
          debugShowCheckedModeBanner: false,
          themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          builder: (context, child) {
            Widget body = IPhone17ProMaxAppShell(
              edgeToEdgeContent: true,
              child: child,
            );
            if (kDebugMode && kIsWeb && WebLanRuntime.hasInfo) {
              body = Stack(
                fit: StackFit.expand,
                children: [
                  body,
                  const WebLanDebugOverlay(),
                ],
              );
            }
            return body;
          },
          home: const LauncherShell(),
        );
      },
    );
  }import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/app_runtime_guard.dart';
import 'package:fuel_tracker_app/core/author_integrity_guard.dart';
import 'package:fuel_tracker_app/core/app_theme.dart';
import 'package:fuel_tracker_app/core/web_lan_runtime.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/launcher_shell.dart';
import 'package:fuel_tracker_app/shared/providers/app_providers.dart';
import 'package:fuel_tracker_app/shared/services/notification_service.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';
import 'package:fuel_tracker_app/shared/widgets/iphone_17_pro_max_frame.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';
import 'package:fuel_tracker_app/shared/widgets/web_lan_debug_overlay.dart';

Future<void> main() async {
  await AppRuntimeGuard.run(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AuthorIntegrityGuard.enforce();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final notificationService = NotificationService();
    await notificationService.init();

    WebLanRuntime.logStartup();

    runApp(FuelTrackerApp(notificationService: notificationService));
  });
}

class FuelTrackerApp extends StatelessWidget {
  final NotificationService notificationService;

  const FuelTrackerApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: AppProviders(
        notificationService: notificationService,
        child: const _ThemedAppRoot(),
      ),
    );
  }
}

class _ThemedAppRoot extends StatelessWidget {
  const _ThemedAppRoot();

  @override
  Widget build(BuildContext context) {
    // Chỉ rebuild MaterialApp khi đổi darkMode — tránh reset navigator khi login.
    return Selector<UserSessionService, bool>(
      selector: (_, session) => session.darkMode,
      builder: (context, darkMode, _) {
        return MaterialApp(
          navigatorKey: ToastService.navigatorKey,
          title: 'Fuel Tracker Pro',
          debugShowCheckedModeBanner: false,
          themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          builder: (context, child) {
            Widget body = IPhone17ProMaxAppShell(
              edgeToEdgeContent: true,
              child: child,
            );
            if (kDebugMode && kIsWeb && WebLanRuntime.hasInfo) {
              body = Stack(
                fit: StackFit.expand,
                children: [
                  body,
                  const WebLanDebugOverlay(),
                ],
              );
            }
            return body;
          },
          home: const LauncherShell(),
        );
      },
    );
  }
}
}
