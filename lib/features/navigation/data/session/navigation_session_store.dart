import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_tracker_app/features/location/core/gps_tracking_policy.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/refuel_flow_phase.dart';

/// Lưu/khôi phục navigation sau background, tắt màn hình, hoặc crash.
class NavigationSessionStore {
  NavigationSessionStore._();

  static const _key = 'navigation_session_v1';

  static Future<void> save(NavigationSessionSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(snapshot.toJson()));
      debugPrint(
        '[NavSession] saved dest=${snapshot.destination.name} '
        'points=${snapshot.polyline.length}',
      );
    } catch (e) {
      debugPrint('[NavSession] save fail: $e');
    }
  }

  static Future<NavigationSessionSnapshot?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final snap = NavigationSessionSnapshot.fromJson(map);
      final age = DateTime.now().difference(snap.savedAt);
      if (age > GpsTrackingPolicy.sessionMaxAge) {
        await clear();
        debugPrint('[NavSession] expired (${age.inHours}h)');
        return null;
      }
      debugPrint(
        '[NavSession] loaded dest=${snap.destination.name} age=${age.inMinutes}m',
      );
      return snap;
    } catch (e) {
      debugPrint('[NavSession] load fail: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    debugPrint('[NavSession] cleared');
  }
}

class NavigationSessionSnapshot {
  const NavigationSessionSnapshot({
    required this.savedAt,
    required this.destination,
    required this.polyline,
    required this.distanceKm,
    required this.durationSeconds,
    this.destinationSnapMeters,
    this.refuelPhase,
    this.savedTripDestination,
    this.isNavigating = true,
  });

  final DateTime savedAt;
  final GasStation destination;
  final List<LatLng> polyline;
  final double distanceKm;
  final int durationSeconds;
  final double? destinationSnapMeters;
  final RefuelFlowPhase? refuelPhase;
  final GasStation? savedTripDestination;
  final bool isNavigating;

  Map<String, dynamic> toJson() => {
        'savedAt': savedAt.toIso8601String(),
        'destination': _stationToJson(destination),
        'polyline': polyline
            .map((p) => [p.latitude, p.longitude])
            .toList(growable: false),
        'distanceKm': distanceKm,
        'durationSeconds': durationSeconds,
        if (destinationSnapMeters != null)
          'destinationSnapMeters': destinationSnapMeters,
        if (refuelPhase != null) 'refuelPhase': refuelPhase!.name,
        if (savedTripDestination != null)
          'savedTripDestination': _stationToJson(savedTripDestination!),
        'isNavigating': isNavigating,
      };

  static NavigationSessionSnapshot fromJson(Map<String, dynamic> json) {
    final polyRaw = json['polyline'] as List<dynamic>? ?? const [];
    final polyline = <LatLng>[];
    for (final item in polyRaw) {
      if (item is! List || item.length < 2) continue;
      polyline.add(
        LatLng(
          (item[0] as num).toDouble(),
          (item[1] as num).toDouble(),
        ),
      );
    }

    RefuelFlowPhase? phase;
    final phaseName = json['refuelPhase'] as String?;
    if (phaseName != null) {
      for (final v in RefuelFlowPhase.values) {
        if (v.name == phaseName) {
          phase = v;
          break;
        }
      }
    }

    return NavigationSessionSnapshot(
      savedAt: DateTime.parse(json['savedAt'] as String),
      destination: _stationFromJson(
        json['destination'] as Map<String, dynamic>,
      ),
      polyline: polyline,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      destinationSnapMeters:
          (json['destinationSnapMeters'] as num?)?.toDouble(),
      refuelPhase: phase,
      savedTripDestination: json['savedTripDestination'] != null
          ? _stationFromJson(
              json['savedTripDestination'] as Map<String, dynamic>,
            )
          : null,
      isNavigating: json['isNavigating'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> _stationToJson(GasStation s) => {
        'id': s.id,
        'osmType': s.osmType,
        'osmId': s.osmId,
        'name': s.name,
        'address': s.address,
        'lat': s.location.latitude,
        'lon': s.location.longitude,
        'distanceKm': s.distanceKm,
        'brand': s.brand,
      };

  static GasStation _stationFromJson(Map<String, dynamic> m) => GasStation(
        id: m['id'] as String,
        osmType: m['osmType'] as String? ?? 'node',
        osmId: (m['osmId'] as num?)?.toInt() ?? 0,
        name: m['name'] as String? ?? 'Điểm đến',
        address: m['address'] as String? ?? '',
        location: LatLng(
          (m['lat'] as num).toDouble(),
          (m['lon'] as num).toDouble(),
        ),
        distanceKm: (m['distanceKm'] as num?)?.toDouble() ?? 0,
        brand: m['brand'] as String? ?? 'Fuel',
      );
}
