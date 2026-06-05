# Fuel Tracker Pro

Ứng dụng Flutter theo dõi GPS realtime, bản đồ **OpenStreetMap** (flutter_map), quản lý nhiên liệu và chỉ đường tới trạm xăng — **không cần API key**.

Nguồn tác giả: **Lữ Minh Hoàng**

## Stack

| Thành phần | Công nghệ |
|---|---|
| Bản đồ | flutter_map + Carto Dark Matter (OSM) |
| GPS | geolocator |
| Geocoding (tìm kiếm + reverse) | Nominatim (countrycodes=vn, accept-language=vi) |
| Cây xăng | Overpass API (amenity=fuel) |
| Tuyến đường | OSRM |
| Animation | flutter_map_animations, flutter_animate |

## Kiến trúc tổng quan

```
main.dart
├── core/              → cấu hình, HTTP, theme, motion, guard
├── shared/            → providers, services dùng chung, widget tái sử dụng
└── features/
    ├── shell/         → điều phối UI chính (map + nav + fuel trên một màn hình)
    ├── home_ios/      → launcher iOS giả (màn hình home, Dynamic Island, …)
    ├── map/           → flutter_map, tile, style, MapPanel
    ├── geocoding/     → Nominatim search / reverse / lookup
    ├── navigation/    → OSRM routing, progress, off-route, HUD, session
    ├── location/      → GPS realtime, filter, tracking policy
    └── fuel/          → xăng, trạm, tiêu hao, intelligence UI
```

Luồng dữ liệu chính:

```
GPS (location) → HomeShell
    → tìm địa điểm (geocoding) → tính tuyến (navigation/OSRM)
    → vẽ map (map) + HUD (navigation)
    → trạm xăng / tiêu hao (fuel)
```

---

## Cấu trúc code — từng nhánh làm gì

### `lib/main.dart` — Điểm vào app

| Việc làm | Chi tiết |
|---|---|
| Khởi tạo | `WidgetsFlutterBinding`, theme hệ thống, `NotificationService` |
| Bảo vệ | `AppRuntimeGuard`, `AuthorIntegrityGuard` |
| Web LAN | `WebLanRuntime.logStartup()` |
| Cây widget | `ProviderScope` → `AppProviders` → `LauncherShell` (hoặc khung iPhone trên desktop) |

**Ai gọi ai:** `main` không chứa logic bản đồ — chỉ lắp provider và shell launcher.

---

### `lib/core/` — Lõi dùng chung toàn app

Không phụ thuộc feature cụ thể; cung cấp hạ tầng và token UI.

#### `core/config/`

| File | Chức năng |
|---|---|
| `constants.dart` | Hằng số app: dung tích bình, mức tiêu hao mặc định, ngưỡng cảnh báo, timeout UI, … |
| `osm_config.dart` | URL Nominatim / Overpass / OSRM, User-Agent, header, chế độ CORS Web |
| `lan_dev_config.dart` | Cấu hình dev Web LAN (hostname, cổng từ `config/lan_web.json`) |

#### `core/network/`

| File | Chức năng |
|---|---|
| `osm_http.dart` | `OsmHttpClient`: HTTP có timeout, retry, rate limit Nominatim, xử lý 429 |

#### Các file lõi khác (`core/*.dart`)

| File | Chức năng |
|---|---|
| `app_theme.dart` | Theme Material tối, màu brand |
| `app_runtime_guard.dart` | Bọc `runApp`, bắt lỗi khởi động |
| `author_integrity_guard.dart` | Kiểm tra chữ ký tác giả khi start |
| `ios_design_tokens.dart` | Màu/spacing kiểu iOS cho widget chung |
| `vehicle_ui_tokens.dart` | Token UI dashboard / HUD xe |
| `interaction_controller.dart` | Điều phối gesture / focus UI trên shell |
| `motion_director.dart` | Animation spring / cinematic chung |
| `micro_motion_spec.dart` | Thông số chuyển động micro-interaction |
| `hmi_intents.dart` | Intent HMI (mở rộng điều khiển) |
| `ttl_cache.dart` | Cache TTL generic (dùng bởi geocoding, Overpass, …) |
| `refuel_debug_tools.dart` | Công cụ debug luồng đổ xăng (dev) |
| `web_lan_runtime.dart` | Log / helper chạy Flutter Web trên LAN |

---

### `lib/shared/` — Thành phần dùng lại, không thuộc một feature domain

#### `shared/providers/`

| File | Chức năng |
|---|---|
| `app_providers.dart` | `MultiProvider`: đăng ký `LocationService`, `FuelService`, `IosSystemBridge`, `UserSessionService` |

#### `shared/services/`

| File | Chức năng |
|---|---|
| `notification_service.dart` | Local notification (cảnh báo xăng thấp, …) |
| `user_session_service.dart` | Phiên người dùng / prefs cơ bản |

#### `shared/screens/`

| File | Chức năng |
|---|---|
| `home_screen.dart` | **Wrapper mỏng** — chỉ `return HomeShell(...)`; giữ API cũ cho `home_ios` |
| `profile_settings_sheet.dart` | Sheet cài đặt / hồ sơ (mở từ shell) |

#### `shared/widgets/`

| File | Chức năng |
|---|---|
| `iphone_17_pro_max_frame.dart` | Khung máy iPhone trên desktop |
| `ios_style_widgets.dart` | Nút, chip, surface kiểu iOS |
| `vehicle_dashboard_panel.dart` | Panel dashboard nhiên liệu / quãng đường |
| `cinematic_sheet.dart` | Bottom sheet có animation cinematic |
| `web_lan_debug_overlay.dart` | Overlay debug khi chạy Web LAN |

---

### `lib/features/shell/` — Lớp điều phối UI (Container App)

**Vai trò:** Ghép map + tìm kiếm + chỉ đường + fuel + bottom nav trên **một màn hình**; quản lý state UI (follow GPS, session restore, animation map). **Không** chứa API OSRM/Nominatim trực tiếp — gọi qua feature khác.

```
features/shell/
├── screens/home_shell.dart      ← orchestration chính (~2500 dòng)
└── widgets/shell_bottom_nav.dart ← thanh dock điều hướng tab
```

#### `screens/home_shell.dart`

| Nhóm việc | Mô tả |
|---|---|
| Compose UI | `MapPanel`, `MapSearchBar`, `NavigationHud`, `VehicleDashboardPanel`, `ShellBottomNav`, `FuelIntelligenceScreen`, … |
| Services | `LocationService`, `FuelService`, `MapNavigationRepository`, `GasStationService`, `FuelStationService`, `RouteFuelService` |
| Flow | Search → `resolvePlace` → `planRoute` → vẽ polyline → bật navigation → theo GPS → off-route reroute |
| State UI | `_followUser`, `_navigationFollow`, `_activeRoute`, `_stations`, `_refuelPhase`, `AnimatedMapController` |
| Session | Lưu/khôi phục navigation qua `NavigationSessionStore` |
| Chế độ launcher | `inLauncherMode`: ẩn chrome iOS giả khi mở từ `AppLaunchOverlay` |

#### `widgets/shell_bottom_nav.dart`

Thanh tab nổi (Map / Fuel / …) — spring indicator, không chứa logic domain.

**Quan hệ:** `HomeScreen` → delegate → `HomeShell`. Code đọc nên vào **`home_shell.dart`**, không vào `shared/screens/home_screen.dart`.

---

### `lib/features/home_ios/` — Launcher & giao diện iOS giả

Mô phỏng iPhone: home screen, Dynamic Island, Control Center, mở app Fuel Tracker.

| Thư mục | Chức năng |
|---|---|
| `core/` | Haptics, spring, squircle, typography, visual tokens |
| `data/` | Catalog app, layout grid widget, `ios_system_bridge` (snapshot nav cho Island) |
| `presentation/launcher_shell.dart` | Root Riverpod: overlay, gesture, home indicator |
| `presentation/pages/ios_home_screen.dart` | Lưới icon, wallpaper, dock |
| `presentation/widgets/*` | Dynamic Island, notification center, control center, spotlight, app launch overlay |
| `presentation/providers/*` | Layout home, parallax, launcher state, system overlay |

**Luồng mở app map:** `AppLaunchOverlay` → `HomeScreen(inLauncherMode: true)` → `HomeShell`.

---

### `lib/features/map/` — Bản đồ (flutter_map)

| File | Chức năng |
|---|---|
| `core/map_style.dart` | Style tile OSM tối / visual map |
| `presentation/widgets/map_panel.dart` | Widget bản đồ: layer tile, cluster marker cây xăng, polyline tuyến, marker user, rotate/follow |

**Không** gọi OSRM hay Nominatim — nhận `LatLng`, polylines, stations từ **shell** qua props.

---

### `lib/features/geocoding/` — Địa chỉ & tìm kiếm (Nominatim)

| File | Chức năng |
|---|---|
| `data/services/nominatim_geocoding_service.dart` | `/search`, `/reverse`, `/lookup`; cache; rate limit |
| `data/models/place_model.dart` | `PlaceSuggestion`, `PlaceDetails` |
| `data/models/address_components.dart` | Đường / phường / quận / tỉnh |
| `data/exceptions/map_navigation_exceptions.dart` | Lỗi mạng, không kết quả, rate limit |
| `core/vietnamese_text_utils.dart` | Bỏ dấu, biến thể truy vấn có/không dấu |
| `core/place_location_utils.dart` | Chuẩn hóa tọa độ / bias search |
| `presentation/widgets/map_search_bar.dart` | Ô tìm kiếm + debounce |
| `presentation/widgets/place_suggestions_panel.dart` | Danh sách gợi ý địa điểm |

**Facade gọi geocoding:** `MapNavigationRepository` (trong `navigation`) — shell gọi repository, không gọi Nominatim trực tiếp.

---

### `lib/features/navigation/` — Chỉ đường (OSRM)

| File | Chức năng |
|---|---|
| `data/services/osrm_routing_service.dart` | Gọi OSRM `/route/v1/driving`, trả `RoutePlan` |
| `data/services/osrm_route_parser.dart` | Parse JSON OSRM, chọn tuyến, decode polyline |
| `data/models/route_plan.dart` | Khoảng cách, thời gian, điểm polyline thô |
| `data/models/navigation_route.dart` | Tuyến active: đích, polyline, ETA cho HUD |
| `data/repositories/map_navigation_repository.dart` | Facade: search + resolve + `planRoute` |
| `data/session/navigation_session_store.dart` | Persist/khôi phục phiên chỉ đường (SharedPreferences) |
| `core/polyline_utils.dart` | Densify polyline, khoảng cách điểm–tuyến, điểm theo km |
| `core/route_progress_utils.dart` | Tiến độ dọc tuyến (km còn lại, snap) |
| `core/route_label_utils.dart` | Nhãn hướng / instruction hiển thị |
| `core/route_off_route.dart` | Phát hiện lệch tuyến → reroute / chỉ cập nhật progress |
| `core/route_snap_warning.dart` | Cảnh báo snap GPS lệch polyline |
| `presentation/widgets/navigation_hud.dart` | HUD cinematic: km, phút, phase đổ xăng |

---

### `lib/features/location/` — GPS & theo dõi vị trí

| File | Chức năng |
|---|---|
| `data/services/location_service.dart` | `geolocator`: stream vị trí, quyền, bearing, tốc độ, khoảng cách tích lũy |
| `core/gps_position_filter.dart` | Lọc nhiễu GPS (kalman / ngưỡng) |
| `core/gps_tracking_policy.dart` | Chính sách follow khi navigation: tần suất, ngưỡng off-route |

**Ai dùng:** `HomeShell` listen `LocationService`; `route_off_route` dùng `gps_tracking_policy`.

---

### `lib/features/fuel/` — Nhiên liệu, trạm xăng, intelligence

#### `data/services/`

| File | Chức năng |
|---|---|
| `fuel_service.dart` | Mức xăng bình, trừ theo km GPS, cảnh báo thấp |
| `gas_station_service.dart` | Overpass `amenity=fuel`, cache 2 phút |
| `fuel_station_service.dart` | Chọn trạm gần tuyến / dọc polyline |
| `route_fuel_service.dart` | Phân tích tiêu hao theo tuyến OSRM |
| `elevation_service.dart` | Độ cao dọc tuyến (ảnh hưởng consumption model) |
| `weather_service.dart` | Snapshot thời tiết (card intelligence) |

#### `data/models/`

| File | Chức năng |
|---|---|
| `gas_station.dart` | Trạm xăng: tọa độ, brand, khoảng cách |
| `route_fuel_analysis.dart` | Kết quả phân tích xăng trên tuyến |
| `trip_fuel_status.dart` | Trạng thái chuyến: đủ xăng tới đích? |
| `refuel_flow_phase.dart` | Phase UI đổ xăng trên HUD |
| `fuel_warning_event.dart` | Sự kiện cảnh báo xăng thấp |
| `weather_snapshot.dart` | Dữ liệu thời tiết hiển thị |

#### `intelligence/`

| Thư mục | Chức năng |
|---|---|
| `consumption/` | Model tiêu hao L/100km theo hành vi |
| `driving_behavior/` | Phân tích gia tốc / phanh từ telemetry |
| `prediction/` | Dự đoán range, thời điểm cần đổ |
| `simulation/` | Mô phỏng tiêu hao trên tuyến |
| `telemetry/` | Mẫu telemetry GPS |
| `warnings/` | Engine cảnh báo (sắp hết xăng, trạm gần) |

#### `presentation/`

| File | Chức năng |
|---|---|
| `screens/fuel_intelligence_screen.dart` | Màn hình tab Fuel Intelligence |
| `viewmodels/fuel_intelligence_view_model.dart` | Load prediction, warnings, weather |
| `widgets/fuel_intelligence_shell.dart` | Chrome UI màn fuel |
| `widgets/fuel_consumption_graph.dart` | Biểu đồ tiêu hao |
| `widgets/fuel_weather_card.dart` | Card thời tiết |

---

## Kiến trúc tìm kiếm & chỉ đường (chi tiết)

```
MapNavigationRepository (navigation/data/repositories)
├── NominatimGeocodingService (geocoding)
│   ├── /search   — forward geocoding (có/không dấu tiếng Việt)
│   ├── /reverse  — reverse geocoding (tọa độ → địa chỉ)
│   └── /lookup   — bổ sung tọa độ OSM id
└── OsrmRoutingService (navigation)
    └── /route/v1/driving — polyline + khoảng cách + thời gian

OsmHttpClient (core/network) — timeout, retry, User-Agent, rate limit
VietnameseTextUtils (geocoding/core)
AddressComponents (geocoding/data/models)
```

Widget flow:

```
MapSearchBar + PlaceSuggestionsPanel (geocoding)
    → HomeShell._navigateToPlace (shell)
    → OSRM polyline trên MapPanel (map) + NavigationHud (navigation)
```

---

## Luồng chức năng chính (end-to-end)

1. `LocationService` đọc GPS realtime.
2. `MapNavigationRepository` tìm điểm đến (Nominatim) và tính tuyến (OSRM).
3. `RouteFuelService` + `FuelService` tính tiêu hao, range, cảnh báo.
4. `GasStationService` / `FuelStationService` lấy và lọc cây xăng.
5. `HomeShell` zoom map, vẽ polyline, bật `NavigationHud`, follow camera.
6. Off-route → `route_off_route` → reroute OSRM; session lưu bởi `NavigationSessionStore`.

---

## Yêu cầu để chạy

- Flutter SDK: `>=3.3.0 <4.0.0`
- Kết nối Internet (Nominatim / Overpass / OSRM public)
- Quyền vị trí (Android / Windows / iOS)

## Chạy nhanh

```bash
flutter clean
flutter pub get
flutter run -d windows
# hoặc:
flutter run -d android
```

## Truy cập từ điện thoại cùng Wi-Fi (Flutter Web)

- Hướng dẫn (Tiếng Việt): [docs/LAN_ACCESS_VI.md](docs/LAN_ACCESS_VI.md)
- Chi tiết kỹ thuật (中文): [docs/LAN_ACCESS.md](docs/LAN_ACCESS.md)

```powershell
cd D:\Mobiapp
.\scripts\fix_lan_firewall.ps1 -SetWiFiPrivate   # một lần (Admin/UAC)
.\scripts\run_web_lan.ps1                         # chạy Web LAN — mở URL in ra trên điện thoại
```

Trên điện thoại mở **đúng URL in trong terminal** (vd. `http://192.168.1.42:8081` nếu 8080 đã bận). Cổng ưu tiên: `config/lan_web.json`.

## Tính năng chính

- Bản đồ tối OSM, marker cluster cây xăng
- Tuyến đỏ OSRM + ETA / km / thời gian
- Tìm kiếm địa chỉ tiếng Việt (có/không dấu) — đường, phường, quận, tỉnh
- Reverse geocoding qua Nominatim
- Timeout + retry mạng tự động
- GPS pulse, camera follow + xoay theo hướng di chuyển

## Lưu ý API công cộng

- **Nominatim**: ~1 request/giây — app debounce + rate limit
- **Overpass**: cache 2 phút quanh vị trí user
- **OSRM** demo: chỉ phát triển; production nên self-host OSRM

## Import trong code

Toàn bộ `lib/` dùng:

```dart
import 'package:fuel_tracker_app/...';
```

Ví dụ:

```dart
import 'package:fuel_tracker_app/features/shell/screens/home_shell.dart';
import 'package:fuel_tracker_app/features/navigation/data/repositories/map_navigation_repository.dart';
```

---

## Mức kiến trúc hiện tại

**Clean Feature-Based + Shell Layer (Production Ready)**

| Lớp | Ý nghĩa |
|---|---|
| `features/*` | Domain: map, geocoding, navigation, location, fuel |
| `features/shell` | Orchestration UI — ghép feature trên một màn hình |
| `features/home_ios` | Launcher iOS (tách khỏi map app) |
| `shared` | Providers, notification, widget dùng chung |
| `core` | Config, HTTP, theme, motion |

Đọc code map/nav: vào **`features/shell/screens/home_shell.dart`**. Đọc API OSRM/Nominatim: vào **`navigation`** + **`geocoding`**.
