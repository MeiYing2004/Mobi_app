import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_runtime_guard.dart';
import 'core/author_integrity_guard.dart';
import 'core/app_theme.dart';
import 'providers/app_providers.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'widgets/iphone_17_pro_max_frame.dart';

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

    runApp(FuelTrackerApp(notificationService: notificationService));
  });
}

class FuelTrackerApp extends StatelessWidget {
  final NotificationService notificationService;

  const FuelTrackerApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      notificationService: notificationService,
      child: MaterialApp(
        title: 'Fuel Tracker Pro',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        builder: (context, child) => IPhone17ProMaxAppShell(child: child),
        home: const HomeScreen(),
      ),
    );
  }
}
