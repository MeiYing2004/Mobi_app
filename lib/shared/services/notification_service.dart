import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Bọc [flutter_local_notifications] — channel fuel_channel / Fuel warnings.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'fuel_channel';
  static const String channelName = 'Fuel warnings';
  static const String channelDescription = 'Cảnh báo sắp hết xăng';

  /// Khởi tạo plugin và tạo notification channel (Android).
  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
      ),
    );
  }

  /// Hiển thị cảnh báo nhiên liệu thấp.
  Future<void> showFuelWarning({
    required String title,
    required String body,
    int notificationId = 1,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(notificationId, title, body, details);
  }
}
