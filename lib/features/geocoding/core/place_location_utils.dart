import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/geocoding/data/models/place_model.dart';

/// Kiểm tra tọa độ dùng cho chỉ đường — tránh null/NaN và (0,0) giả.
class PlaceLocationValidator {
  PlaceLocationValidator._();

  static bool isNavigable(LatLng location) {
    final lat = location.latitude;
    final lon = location.longitude;
    if (lat.isNaN ||
        lon.isNaN ||
        lat.isInfinite ||
        lon.isInfinite) {
      return false;
    }
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      return false;
    }
    // Chỉ loại null island — không từ chối khi một trục ≈ 0.
    if (lat.abs() < 1e-6 && lon.abs() < 1e-6) {
      return false;
    }
    return true;
  }

  static PlaceDetails? navigable(PlaceDetails details) {
    if (!isNavigable(details.location)) return null;
    return details;
  }

  static String? rejectReason(LatLng location) {
    final lat = location.latitude;
    final lon = location.longitude;
    if (lat.isNaN || lon.isNaN) return 'NaN';
    if (lat.isInfinite || lon.isInfinite) return 'infinite';
    if (lat < -90 || lat > 90) return 'lat out of range ($lat)';
    if (lon < -180 || lon > 180) return 'lon out of range ($lon)';
    if (lat.abs() < 1e-6 && lon.abs() < 1e-6) {
      return 'null island ($lat,$lon)';
    }
    return null;
  }
}
