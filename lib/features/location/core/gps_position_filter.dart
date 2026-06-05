import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/features/location/core/gps_tracking_policy.dart';

/// Lọc nhiễu GPS khi đứng yên / accuracy kém — giữ vị trí navigation ổn định.
class GpsPositionFilter {
  Position? _lastAccepted;

  Position? get lastAccepted => _lastAccepted;

  void reset() => _lastAccepted = null;

  /// Trả về fix mới nếu chấp nhận; nếu không, giữ [lastAccepted].
  Position? ingest(Position raw) {
    if (!_isAccuracyAcceptable(raw)) {
      return _lastAccepted;
    }

    final prev = _lastAccepted;
    if (prev != null && !_hasMeaningfulMotion(prev, raw)) {
      return _lastAccepted;
    }

    _lastAccepted = raw;
    return raw;
  }

  LatLng? get latLng {
    final p = _lastAccepted;
    if (p == null) return null;
    return LatLng(p.latitude, p.longitude);
  }

  static bool _isAccuracyAcceptable(Position p) {
    final acc = p.accuracy;
    if (!acc.isFinite || acc < 0) return true;
    return acc <= GpsTrackingPolicy.maxAccuracyM;
  }

  static bool _hasMeaningfulMotion(Position prev, Position next) {
    final speed = next.speed;
    if (speed.isFinite && speed >= GpsTrackingPolicy.minSpeedMps) {
      return true;
    }
    final moved = Geolocator.distanceBetween(
      prev.latitude,
      prev.longitude,
      next.latitude,
      next.longitude,
    );
    return moved >= GpsTrackingPolicy.minMoveWhenSlowM;
  }
}
