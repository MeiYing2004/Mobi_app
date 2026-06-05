import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/features/location/core/gps_position_filter.dart';

/// Theo dõi GPS realtime — quãng đường, tốc độ, bearing, chế độ navigation.
class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  Position? _lastPosition;
  double _totalDistanceMeters = 0;
  double _bearing = 0;
  StreamSubscription<Position>? _positionSub;

  String? _permissionError;
  bool _navigationMode = false;
  final GpsPositionFilter _navFilter = GpsPositionFilter();

  /// Gọi khi di chuyển thêm [meters] (để trừ nhiên liệu).
  void Function(double meters)? onDistanceTraveled;

  Position? get currentPosition => _currentPosition;
  String? get permissionError => _permissionError;
  bool get hasValidPosition => _currentPosition != null;
  bool get isNavigationMode => _navigationMode;

  /// Vị trí đã lọc cho progress / ETA / off-route (đứng yên không nhảy).
  LatLng? get navigationLatLng => _navFilter.latLng;

  /// Lấy điểm xuất phát cho routing: GPS hiện tại → last known → null.
  Future<LatLng?> resolveOriginForRouting({
    Duration waitTimeout = const Duration(seconds: 6),
  }) async {
    final current = _currentPosition;
    if (current != null) {
      debugPrint(
        '[Location] Dùng GPS hiện tại: '
        '${current.latitude}, ${current.longitude}',
      );
      return LatLng(current.latitude, current.longitude);
    }

    debugPrint('[Location] Chưa có GPS, đợi tối đa ${waitTimeout.inSeconds}s…');
    final waited = await waitForFirstPosition(timeout: waitTimeout);
    if (waited != null) {
      debugPrint(
        '[Location] GPS sau khi đợi: '
        '${waited.latitude}, ${waited.longitude}',
      );
      return LatLng(waited.latitude, waited.longitude);
    }

    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _onPositionUpdate(last);
        debugPrint(
          '[Location] Dùng vị trí lần cuối: '
          '${last.latitude}, ${last.longitude}',
        );
        return LatLng(last.latitude, last.longitude);
      }
    } catch (e) {
      debugPrint('[Location] getLastKnownPosition lỗi: $e');
    }

    debugPrint('[Location] Không lấy được vị trí hợp lệ');
    return null;
  }

  Future<Position?> waitForFirstPosition({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (_currentPosition != null) return _currentPosition;

    final completer = Completer<Position?>();
    void onUpdate() {
      final p = _currentPosition;
      if (p != null && !completer.isCompleted) {
        completer.complete(p);
      }
    }

    addListener(onUpdate);
    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => _currentPosition,
      );
    } finally {
      removeListener(onUpdate);
    }
  }

  LatLng get defaultRoutingOrigin => AppConstants.defaultVietnamLocation;
  double get totalDistanceKm => _totalDistanceMeters / 1000;
  double get bearing => _bearing;

  double? get speedKmh {
    final speed = _currentPosition?.speed;
    if (speed == null || speed < 0) return null;
    return speed * 3.6;
  }

  /// Bật/tắt chế độ navigation — đổi [LocationSettings] (accuracy + filter).
  Future<void> setNavigationMode(bool enabled) async {
    if (_navigationMode == enabled) return;
    _navigationMode = enabled;
    _navFilter.reset();
    if (enabled && _currentPosition != null) {
      _navFilter.ingest(_currentPosition!);
    }
    debugPrint(
      '[Location] navigationMode=$enabled '
      'settings=${enabled ? 'high' : 'balanced'}',
    );
    if (_positionSub != null) {
      await _restartStream();
    }
    notifyListeners();
  }

  Future<void> startListening() async {
    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      notifyListeners();
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _permissionError = 'Vui lòng bật GPS trên thiết bị.';
      notifyListeners();
      return;
    }

    try {
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      _onPositionUpdate(initial);
    } catch (e) {
      debugPrint('getCurrentPosition: $e');
    }

    await _restartStream();
  }

  LocationSettings get _locationSettings => _navigationMode
      ? const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        )
      : const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 12,
        );

  Future<void> _restartStream() async {
    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (Object e) => debugPrint('Position stream error: $e'),
    );
  }

  void _onPositionUpdate(Position position) {
    _currentPosition = position;

    if (_navigationMode) {
      _navFilter.ingest(position);
    } else {
      _navFilter.reset();
      _navFilter.ingest(position);
    }

    if (_lastPosition != null) {
      final meters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (meters >= 1 && meters < 500) {
        _totalDistanceMeters += meters;
        onDistanceTraveled?.call(meters);
        _bearing = _resolveBearing(
          from: _lastPosition!,
          to: position,
          gpsHeading: position.heading,
        );
      }
    } else if (position.heading >= 0) {
      _bearing = position.heading;
    }

    _lastPosition = position;
    notifyListeners();
  }

  double _resolveBearing({
    required Position from,
    required Position to,
    required double gpsHeading,
  }) {
    if (gpsHeading >= 0 && (to.speed) > 1.5) {
      return gpsHeading % 360;
    }

    final y = math.sin(_toRad(to.longitude - from.longitude)) *
        math.cos(_toRad(to.latitude));
    final x = math.cos(_toRad(from.latitude)) * math.sin(_toRad(to.latitude)) -
        math.sin(_toRad(from.latitude)) *
            math.cos(_toRad(to.latitude)) *
            math.cos(_toRad(to.longitude - from.longitude));
    final deg = math.atan2(y, x) * 180 / math.pi;
    return (deg + 360) % 360;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  Future<bool> _ensurePermission() async {
    _permissionError = null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _permissionError = 'Quyền vị trí bị từ chối.';
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _permissionError =
          'Quyền vị trí bị từ chối vĩnh viễn. Mở Cài đặt để cấp lại.';
      return false;
    }

    return true;
  }

  void resetDistance() {
    _totalDistanceMeters = 0;
    _lastPosition = _currentPosition;
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
