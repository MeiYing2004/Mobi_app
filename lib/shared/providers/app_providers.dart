import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/auth/services/user_service.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_system_bridge.dart';
import 'package:fuel_tracker_app/features/location/data/services/location_service.dart';
import 'package:fuel_tracker_app/features/premium/services/premium_service.dart';
import 'package:fuel_tracker_app/shared/services/notification_service.dart';
import 'package:fuel_tracker_app/shared/services/user_session_service.dart';

/// Đăng ký toàn bộ [ChangeNotifier] cho app.
class AppProviders extends StatelessWidget {
  final NotificationService notificationService;
  final Widget child;
  final bool startLocationOnCreate;

  const AppProviders({
    super.key,
    required this.notificationService,
    required this.child,
    this.startLocationOnCreate = true,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final service = LocationService();
            if (startLocationOnCreate) {
              service.startListening();
            }
            return service;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => FuelService(notificationService: notificationService),
        ),
        ChangeNotifierProvider(create: (_) => IosSystemBridge()),
        ChangeNotifierProvider(
          create: (_) {
            final users = UserService();
            users.init().catchError((Object e, StackTrace stack) {
              debugPrint('[AppProviders] UserService.init failed: $e');
              debugPrint(stack.toString());
            });
            return users;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final users = context.read<UserService>();
            final fuel = context.read<FuelService>();
            final session = UserSessionService(
              userService: users,
              fuelService: fuel,
            );
            session.bind(users, fuelService: fuel);
            session.init().catchError((Object e, StackTrace stack) {
              debugPrint('[AppProviders] UserSessionService.init failed: $e');
              debugPrint(stack.toString());
            });
            return session;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => PremiumService(
            userService: context.read<UserService>(),
          ),
        ),
      ],
      child: child,
    );
  }
}
