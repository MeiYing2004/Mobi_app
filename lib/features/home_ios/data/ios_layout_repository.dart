import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_tracker_app/features/home_ios/data/ios_app_catalog.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_home_data.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_widget_size.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';

/// Lưu / tải bố cục Home Screen qua SharedPreferences.
class IosLayoutRepository {
  static const _pagesKey = 'ios_home_pages_v3';
  static const _dockKey = 'ios_home_dock_v3';

  Future<HomeLayoutState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final pagesJson = prefs.getString(_pagesKey);
    final dockJson = prefs.getString(_dockKey);
    if (pagesJson == null && dockJson == null) return null;

    try {
      final pages = pagesJson != null
          ? _decodePages(jsonDecode(pagesJson) as List<dynamic>)
          : IosHomeData.defaultPages();
      final dock = dockJson != null
          ? _decodeItems(jsonDecode(dockJson) as List<dynamic>)
          : IosHomeData.defaultDock();
      return HomeLayoutState(pages: pages, dock: dock);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(HomeLayoutState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pagesKey,
      jsonEncode(state.pages.map(_encodePage).toList()),
    );
    await prefs.setString(
      _dockKey,
      jsonEncode(state.dock.map(_encodeItem).toList()),
    );
  }

  List<Map<String, dynamic>> _encodePage(List<IosAppModel> page) =>
      page.map(_encodeItem).toList();

  Map<String, dynamic> _encodeItem(IosAppModel item) => {
        'id': item.id,
        'type': item.type.name,
        if (item.widgetSize != null) 'widgetSize': item.widgetSize!.name,
        if (item.widgetKind != null) 'widgetKind': item.widgetKind!.name,
      };

  List<List<IosAppModel>> _decodePages(List<dynamic> raw) => raw
      .map((page) => _decodeItems(page as List<dynamic>))
      .toList();

  List<IosAppModel> _decodeItems(List<dynamic> raw) =>
      raw.map((e) => _decodeItem(e as Map<String, dynamic>)).toList();

  IosAppModel _decodeItem(Map<String, dynamic> json) {
    final type =
        IosHomeItemType.values.byName(json['type'] as String? ?? 'app');
    if (type == IosHomeItemType.widget) {
      final sizeName = json['widgetSize'] as String? ?? 'medium';
      final size = IosWidgetSize.values.byName(sizeName);
      final kindName = json['widgetKind'] as String?;
      final kind = kindName != null
          ? IosWidgetKind.values.byName(kindName)
          : IosWidgetKind.fuel;
      return switch (kind) {
        IosWidgetKind.weather => IosHomeData.weatherWidget(size: size),
        IosWidgetKind.calendar => IosHomeData.calendarWidget(size: size),
        IosWidgetKind.fuel => IosHomeData.fuelWidget(size: size),
      };
    }
    return IosAppCatalog.resolve(json['id'] as String);
  }
}
