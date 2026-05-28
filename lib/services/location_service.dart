import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Theo dõi GPS realtime — quãng đường, tốc độ, bearing.
class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  Position? _lastPosition;
  double _totalDistanceMeters = 0;
  double _bearing = 0;
  StreamSubscription<Position>? _positionSub;

  String? _permissionError;

  /// Gọi khi di chuyển thêm [meters] (để trừ nhiên liệu).
  void Function(double meters)? onDistanceTraveled;

  Position? get currentPosition => _currentPosition;
  String? get permissionError => _permissionError;
  double get totalDistanceKm => _totalDistanceMeters / 1000;

  /// Hướng di chuyển (0–360°, 0 = Bắc).
  double get bearing => _bearing;

  /// Tốc độ km/h từ GPS.
  double? get speedKmh {
    final speed = _currentPosition?.speed;
    if (speed == null || speed < 0) return null;
    return speed * 3.6;
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _onPositionUpdate(initial);
    } catch (e) {
      debugPrint('getCurrentPosition: $e');
    }

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      _onPositionUpdate,
      onError: (Object e) => debugPrint('Position stream error: $e'),
    );
  }

  void _onPositionUpdate(Position position) {
    _currentPosition = position;

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
