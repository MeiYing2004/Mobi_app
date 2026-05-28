import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/fuel_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

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
      ],
      child: child,
    );
  }
}
