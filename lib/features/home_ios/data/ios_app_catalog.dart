import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/group3_demo/group3_food_demo_screen.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';

/// Danh mục ứng dụng cho App Library và khôi phục layout.
class IosAppCatalog {
  IosAppCatalog._();

  static const fuelTrackerId = 'fuel_tracker';
  static const group3DemoId = Group3FoodDemoScreen.appId;

  static final Map<String, IosAppModel> _byId = {
    for (final app in allApps) app.id: app,
  };

  static List<IosAppModel> get allApps => [
        _app(
          id: group3DemoId,
          name: 'Food Demo',
          category: 'Học tập',
          gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF9500)],
          icon: Icons.restaurant_menu_rounded,
          isGroup3Demo: true,
        ),
        _app(
          id: fuelTrackerId,
          name: 'Fuel Tracker',
          category: 'Sản xuất',
          gradient: [VehicleUi.accentBlue, const Color(0xFF1E4A8C)],
          icon: Icons.local_gas_station_rounded,
          isFuelTracker: true,
        ),
        _app(id: 'maps', name: 'Maps', category: 'Du lịch', gradient: [const Color(0xFF34C759), const Color(0xFF248A3D)], icon: Icons.map_rounded),
        _app(id: 'weather', name: 'Weather', category: 'Thông tin', gradient: [const Color(0xFF5AC8FA), const Color(0xFF007AFF)], icon: Icons.wb_sunny_rounded),
        _app(id: 'photos', name: 'Photos', category: 'Sáng tạo', gradient: [const Color(0xFFFF9500), const Color(0xFFFFCC00)], icon: Icons.photo_library_rounded),
        _app(id: 'calendar', name: 'Calendar', category: 'Năng suất', gradient: [const Color(0xFFFF3B30), Colors.white], icon: Icons.calendar_today_rounded),
        _app(id: 'notes', name: 'Notes', category: 'Năng suất', gradient: [const Color(0xFFFFCC00), const Color(0xFFFF9500)], icon: Icons.note_alt_rounded),
        _app(id: 'music', name: 'Music', category: 'Giải trí', gradient: [const Color(0xFFFC3C44), const Color(0xFFFA2D55)], icon: Icons.music_note_rounded),
        _app(id: 'settings', name: 'Settings', category: 'Tiện ích', gradient: [const Color(0xFF8E8E93), const Color(0xFF636366)], icon: Icons.settings_rounded),
        _app(id: 'app_store', name: 'App Store', category: 'Tiện ích', gradient: [const Color(0xFF0A84FF), const Color(0xFF5AC8FA)], icon: Icons.apps_rounded),
        _app(id: 'wallet', name: 'Wallet', category: 'Tiện ích', gradient: [const Color(0xFF1C1C1E), const Color(0xFF3A3A3C)], icon: Icons.account_balance_wallet_rounded),
        _app(id: 'health', name: 'Health', category: 'Thông tin', gradient: [Colors.white, const Color(0xFFFF2D55)], icon: Icons.favorite_rounded),
        _app(id: 'files', name: 'Files', category: 'Năng suất', gradient: [const Color(0xFF007AFF), const Color(0xFF5AC8FA)], icon: Icons.folder_rounded),
        _app(id: 'clock', name: 'Clock', category: 'Tiện ích', gradient: [const Color(0xFF1C1C1E), const Color(0xFFFF9500)], icon: Icons.access_time_rounded),
        _app(id: 'camera', name: 'Camera', category: 'Sáng tạo', gradient: [const Color(0xFF636366), const Color(0xFF1C1C1E)], icon: Icons.camera_alt_rounded),
        _app(id: 'mail', name: 'Mail', category: 'Năng suất', gradient: [const Color(0xFF0A84FF), const Color(0xFF64D2FF)], icon: Icons.mail_rounded),
        _app(id: 'phone', name: 'Phone', category: 'Giao tiếp', gradient: [const Color(0xFF34C759), const Color(0xFF248A3D)], icon: Icons.phone_rounded),
        _app(id: 'messages', name: 'Messages', category: 'Giao tiếp', gradient: [const Color(0xFF34C759), const Color(0xFF30D158)], icon: Icons.message_rounded),
        _app(id: 'safari', name: 'Safari', category: 'Thông tin', gradient: [const Color(0xFF0A84FF), Colors.white], icon: Icons.public_rounded),
        _app(id: 'podcasts', name: 'Podcasts', category: 'Giải trí', gradient: [const Color(0xFFAF52DE), const Color(0xFF5856D6)], icon: Icons.podcasts_rounded),
        _app(id: 'tv', name: 'TV', category: 'Giải trí', gradient: [const Color(0xFF1C1C1E), const Color(0xFF636366)], icon: Icons.tv_rounded),
        _app(id: 'books', name: 'Books', category: 'Giải trí', gradient: [const Color(0xFFFF9500), const Color(0xFFFFCC00)], icon: Icons.menu_book_rounded),
        _app(id: 'stocks', name: 'Stocks', category: 'Thông tin', gradient: [const Color(0xFF1C1C1E), const Color(0xFF34C759)], icon: Icons.show_chart_rounded),
        _app(id: 'translate', name: 'Translate', category: 'Thông tin', gradient: [const Color(0xFF007AFF), const Color(0xFF5AC8FA)], icon: Icons.translate_rounded),
        _app(id: 'shortcuts', name: 'Shortcuts', category: 'Tiện ích', gradient: [const Color(0xFF5856D6), const Color(0xFFAF52DE)], icon: Icons.bolt_rounded),
      ];

  static IosAppModel? find(String id) => _byId[id];

  static IosAppModel resolve(String id) =>
      _byId[id] ?? _app(id: id, name: id, category: 'Khác', gradient: [const Color(0xFF636366), const Color(0xFF1C1C1E)], icon: Icons.apps_rounded);

  static Map<String, List<IosAppModel>> groupedByCategory() {
    final map = <String, List<IosAppModel>>{};
    for (final app in allApps) {
      map.putIfAbsent(app.category ?? 'Khác', () => []).add(app);
    }
    return map;
  }

  static IosAppModel _app({
    required String id,
    required String name,
    required String category,
    required List<Color> gradient,
    required IconData icon,
    bool isFuelTracker = false,
    bool isGroup3Demo = false,
  }) {
    return IosAppModel(
      id: id,
      name: name,
      category: category,
      iconGradient: gradient,
      iconData: icon,
      isFuelTracker: isFuelTracker,
      isGroup3Demo: isGroup3Demo,
    );
  }
}
