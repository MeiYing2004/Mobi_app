import 'package:fuel_tracker_app/features/home_ios/data/ios_app_catalog.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_widget_size.dart';

/// Dữ liệu mặc định cho Home Screen iOS 18.
class IosHomeData {
  IosHomeData._();

  static const fuelTrackerId = IosAppCatalog.fuelTrackerId;
  static const fuelWidgetId = 'fuel_widget';
  static const weatherWidgetId = 'weather_widget';
  static const calendarWidgetId = 'calendar_widget';

  static IosAppModel weatherWidget({IosWidgetSize size = IosWidgetSize.small}) =>
      IosAppModel(
        id: '${weatherWidgetId}_${size.name}',
        name: 'Thời tiết',
        type: IosHomeItemType.widget,
        widgetSize: size,
        widgetKind: IosWidgetKind.weather,
      );

  static IosAppModel calendarWidget({IosWidgetSize size = IosWidgetSize.small}) =>
      IosAppModel(
        id: '${calendarWidgetId}_${size.name}',
        name: 'Lịch',
        type: IosHomeItemType.widget,
        widgetSize: size,
        widgetKind: IosWidgetKind.calendar,
      );

  static IosAppModel fuelWidget({IosWidgetSize size = IosWidgetSize.medium}) =>
      IosAppModel(
        id: '${fuelWidgetId}_${size.name}',
        name: 'Fuel Tracker',
        type: IosHomeItemType.widget,
        widgetSize: size,
        widgetKind: IosWidgetKind.fuel,
      );

  /// Trang 1 — widget trên cùng + lưới 4 cột (Springboard iOS).
  static List<List<IosAppModel>> defaultPages() => [
        [
          weatherWidget(size: IosWidgetSize.small),
          calendarWidget(size: IosWidgetSize.small),
          IosAppCatalog.resolve(IosAppCatalog.group3DemoId),
          IosAppCatalog.resolve(fuelTrackerId),
          IosAppCatalog.resolve('maps'),
          IosAppCatalog.resolve('photos'),
          IosAppCatalog.resolve('camera'),
          IosAppCatalog.resolve('weather'),
          IosAppCatalog.resolve('calendar'),
          IosAppCatalog.resolve('notes'),
          IosAppCatalog.resolve('music'),
          IosAppCatalog.resolve('settings'),
          IosAppCatalog.resolve('wallet'),
          IosAppCatalog.resolve('mail'),
        ],
        [
          IosAppCatalog.resolve('app_store'),
          IosAppCatalog.resolve('health'),
          IosAppCatalog.resolve('files'),
          IosAppCatalog.resolve('clock'),
          IosAppCatalog.resolve('podcasts'),
          IosAppCatalog.resolve('tv'),
          IosAppCatalog.resolve('books'),
          IosAppCatalog.resolve('stocks'),
          IosAppCatalog.resolve('translate'),
          IosAppCatalog.resolve('shortcuts'),
        ],
      ];

  static List<IosAppModel> defaultDock() => [
        IosAppCatalog.resolve(fuelTrackerId),
        IosAppCatalog.resolve('phone'),
        IosAppCatalog.resolve('messages'),
        IosAppCatalog.resolve('safari'),
      ];

  static List<IosAppModel> libraryOnlyApps() {
    final onHome = {
      for (final page in defaultPages())
        for (final item in page)
          if (item.type == IosHomeItemType.app) item.id,
      for (final item in defaultDock()) item.id,
    };
    return IosAppCatalog.allApps
        .where((app) => !onHome.contains(app.id))
        .toList();
  }
}
