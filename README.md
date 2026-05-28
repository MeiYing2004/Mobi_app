# Fuel Tracker Pro

Ứng dụng Flutter theo dõi GPS realtime, bản đồ **OpenStreetMap** (flutter_map), quản lý nhiên liệu và chỉ đường tới trạm xăng — **không cần API key**.

Nguồn tác giả: **Lữ Minh Hoàng**

## Stack

| Thành phần | Công nghệ |
|---|---|
| Bản đồ | flutter_map + Carto Dark Matter (OSM) |
| GPS | geolocator |
| Tìm kiếm | Nominatim (countrycodes=vn) |
| Cây xăng | Overpass API (amenity=fuel) |
| Tuyến đường | OSRM + GraphHopper (cho module Fuel Intelligence) |
| Animation | flutter_map_animations, flutter_animate |

## Cấu trúc code (đã sắp xếp theo chức năng)

### 1) App shell + màn hình chính
- `lib/main.dart`: entry point, khởi tạo theme + providers + notification.
- `lib/screens/home_screen.dart`: màn hình chính (map, tìm kiếm, điều hướng, cây xăng, HUD, bottom nav).
- `lib/widgets/iphone_17_pro_max_frame.dart`: khung hiển thị iOS-style trên desktop.

### 2) Dữ liệu lõi và cấu hình
- `lib/core/*`: hằng số, theme, token UI, motion spec, interaction controller, map style, osm config.
- `lib/models/*`: model địa điểm, trạm xăng, route, phân tích route fuel, warning event.
- `lib/providers/app_providers.dart`: DI/provider graph cho services toàn app.

### 3) Nghiệp vụ dịch vụ (service layer)
- `lib/services/location_service.dart`: GPS realtime, permissions, bearing, quãng đường.
- `lib/services/search_service.dart`: tìm kiếm địa điểm qua Nominatim.
- `lib/services/gas_station_service.dart`: lấy cây xăng gần user (Overpass) + cache/fallback.
- `lib/services/fuel_station_service.dart`: logic nâng cao chọn trạm dọc tuyến và chấm điểm trạm.
- `lib/services/directions_service.dart`: route OSRM cho điều hướng chính.
- `lib/services/graphhopper_directions_service.dart`: route engine cho module phân tích nâng cao.
- `lib/services/fuel_service.dart`, `lib/services/route_fuel_service.dart`: tiêu hao nhiên liệu, cảnh báo, phân tích theo tuyến.
- `lib/services/elevation_service.dart`: dữ liệu độ cao phục vụ phân tích.
- `lib/services/notification_service.dart`: local notification.

### 4) Module AI/Fuel Intelligence
- `lib/features/fuel_intelligence/screens/fuel_intelligence_screen.dart`: màn hình phân tích.
- `lib/features/fuel_intelligence/viewmodels/fuel_intelligence_view_model.dart`: điều phối prediction/simulation/warnings.
- `lib/features/fuel_intelligence/widgets/*`: mini-map + chart tiêu hao.
- `lib/intelligence/*`: engine phân tích hành vi lái, dự đoán tiêu hao, mô phỏng nhiên liệu, cảnh báo.

### 5) UI components dùng lại
- `lib/widgets/map_panel.dart`, `lib/widgets/navigation_hud.dart`: map + điều hướng realtime.
- `lib/widgets/vehicle_dashboard_panel.dart`, `lib/widgets/vehicle_bottom_nav.dart`: dashboard xe + nav bar.
- `lib/widgets/search_bar_widget.dart`, `lib/widgets/quick_action_chips.dart`: tìm kiếm và tác vụ nhanh.
- `lib/widgets/cinematic_sheet.dart`, `lib/widgets/animated_curved_tab_bar.dart`, `lib/widgets/ios_style_widgets.dart`: thành phần giao diện/animation.

## Luồng chức năng chính
1. `location_service` đọc GPS realtime.
2. `search_service` tìm điểm đến, `directions_service` lấy tuyến.
3. `route_fuel_service` + `fuel_service` tính tiêu hao, range, cảnh báo.
4. `gas_station_service` / `fuel_station_service` đề xuất trạm xăng phù hợp.
5. `home_screen` + `navigation_hud` hiển thị toàn bộ trạng thái theo thời gian thực.

## Dọn dẹp dư thừa
- Đã xóa `lib/screens/fuel_dashboard_screen.dart` vì không còn được gọi ở bất kỳ luồng nào.
- README đã cập nhật lại tương ứng để không còn mục mô tả dư.

## Nâng cấp release-ready đã triển khai
- Bọc runtime với `AppRuntimeGuard` để bắt lỗi chưa xử lý (FlutterError, Zone, PlatformDispatcher).
- Bổ sung fallback `ErrorWidget.builder` giúp app không vỡ màn hình trắng khi lỗi render.
- Tăng độ bền mạng ở `SearchService` và `DirectionsService`:
  - retry tự động 1 lần khi request lỗi tạm thời,
  - thông báo lỗi rõ ràng cho timeout/mất mạng/phản hồi lỗi.
- Dọn dead code và thành phần private không dùng để giảm nhiễu bảo trì.
- Rà lại test + analyze sau thay đổi để đảm bảo app vẫn ổn định.

## Yêu cầu để chạy được project

### 1) Bắt buộc
- Flutter SDK: `>=3.3.0 <4.0.0` (theo `pubspec.yaml`)
- Dart SDK đi kèm Flutter
- Kết nối Internet (vì app dùng Nominatim / Overpass / OSRM public)
- Cấp quyền vị trí cho app (Android / Windows / iOS)

### 2) Nếu chạy trên Windows
- Windows 10/11
- Visual Studio 2022 (workload **Desktop development with C++**)
- MSVC + Windows SDK đầy đủ (đi kèm workload trên)
- `nuget.exe` có thể truy cập (Flutter sẽ tự tải nếu chưa có)

### 3) Nếu chạy trên Android
- Android Studio + Android SDK
- Thiết bị/emulator Android đã bật location

## Cấu hình API (tùy chọn)

File: `lib/core/osm_config.dart`

- `graphHopperBase` và `graphHopperApiKey`: để bật tuyến GraphHopper (nếu để rỗng app sẽ fallback OSRM)
- `openElevationLookupUrl`: để bật dữ liệu độ cao (nếu rỗng thì bỏ qua)

Mặc định hiện tại project chạy với API public, không cần key:
- Nominatim
- Overpass
- OSRM public demo

## Chạy nhanh

```bash
flutter clean
flutter pub get
flutter doctor -v
flutter run -d windows
# hoặc:
flutter run -d android
```

## Nếu gặp lỗi build Windows

- Mở Visual Studio Installer và kiểm tra lại workload C++
- Chạy lại:

```bash
flutter config --enable-windows-desktop
flutter doctor -v
flutter clean
flutter pub get
flutter run -d windows
```

## Tính năng chính
    
- Bản đồ tối OSM, marker cluster cây xăng
- Tuyến đỏ OSRM + ETA / km / thời gian
- GPS pulse, camera follow + xoay theo hướng di chuyển
- Xăng giảm theo quãng đường GPS thực tế
- UI iPhone 17 Pro Max frame (desktop)

## Lưu ý API công cộng

- **Nominatim**: tối đa ~1 request/giây — app debounce search
- **Overpass**: cache 2 phút quanh vị trí user
- **OSRM** demo server: chỉ dùng phát triển; production nên self-host OSRM
