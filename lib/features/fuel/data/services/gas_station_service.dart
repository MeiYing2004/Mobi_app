import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/osm_config.dart';
import 'package:fuel_tracker_app/core/network/osm_http.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';

/// Tìm cây xăng — Overpass (chính), Nominatim fallback **một lần** nếu Overpass rỗng/lỗi.
class GasStationService {
  static const double referencePriceVndPerLiter = 24500;

  static const Duration _cacheTtl = Duration(minutes: 8);

  final OsmHttpClient _overpassHttp = OsmHttpClient.forOverpass();

  LatLng? _cacheOrigin;
  List<GasStation> _cache = const [];
  DateTime? _cacheTime;

  String? _boundsCacheKey;
  List<GasStation> _boundsCache = const [];
  DateTime? _boundsCacheTime;

  Future<List<GasStation>> findNearestStations({
    required LatLng origin,
    double radiusKm = 5,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _readNearestCache(origin, limit);
      if (cached != null) return cached;
    }

    final radiusM = (radiusKm * 1000).round();
    final query = '''
[out:json][timeout:15];
(
  node["amenity"="fuel"](around:$radiusM,${origin.latitude},${origin.longitude});
  way["amenity"="fuel"](around:$radiusM,${origin.latitude},${origin.longitude});
);
out center tags;
''';

    var stations = await _queryOverpassPrimary(
      query,
      origin: origin,
      maxRadiusKm: radiusKm,
    );

    if (stations.isEmpty) {
      final pad = (radiusKm / 111.0).clamp(0.015, 0.12);
      stations = await _queryNominatimBoundsOnce(
        south: origin.latitude - pad,
        west: origin.longitude - pad,
        north: origin.latitude + pad,
        east: origin.longitude + pad,
        originForDistance: origin,
        limit: limit.clamp(20, 80),
      );
    }

    if (stations.isEmpty) {
      debugPrint(
        '[GasStation] Không tải được trạm quanh (${origin.latitude}, ${origin.longitude})',
      );
      return const [];
    }

    _cacheOrigin = origin;
    _cacheTime = DateTime.now();
    _cache = stations;

    return _sortedByDistance(stations, origin).take(limit).toList();
  }

  /// Một truy vấn Overpass theo bbox — dùng cho tuyến dài.
  Future<List<GasStation>> findStationsInBounds({
    required double south,
    required double west,
    required double north,
    required double east,
    required LatLng originForDistance,
    int limit = 200,
  }) async {
    final key =
        '${south.toStringAsFixed(4)}|${west.toStringAsFixed(4)}|'
        '${north.toStringAsFixed(4)}|${east.toStringAsFixed(4)}';
    if (_boundsCacheKey == key &&
        _boundsCacheTime != null &&
        DateTime.now().difference(_boundsCacheTime!) < _cacheTtl &&
        _boundsCache.isNotEmpty) {
      return _sortedByDistance(_boundsCache, originForDistance)
          .take(limit)
          .toList();
    }

    final query = '''
[out:json][timeout:15];
(
  node["amenity"="fuel"]($south,$west,$north,$east);
  way["amenity"="fuel"]($south,$west,$north,$east);
);
out center tags;
''';

    var stations = await _queryOverpassPrimary(
      query,
      origin: originForDistance,
    );

    if (stations.isEmpty) {
      stations = await _queryNominatimBoundsOnce(
        south: south,
        west: west,
        north: north,
        east: east,
        originForDistance: originForDistance,
        limit: limit.clamp(30, 120),
      );
    }

    _boundsCacheKey = key;
    _boundsCacheTime = DateTime.now();
    _boundsCache = stations;

    return _sortedByDistance(stations, originForDistance).take(limit).toList();
  }

  List<GasStation>? _readNearestCache(LatLng origin, int limit) {
    if (_cacheOrigin == null || _cacheTime == null || _cache.isEmpty) {
      return null;
    }
    if (DateTime.now().difference(_cacheTime!) >= _cacheTtl) return null;
    final moved = Geolocator.distanceBetween(
      _cacheOrigin!.latitude,
      _cacheOrigin!.longitude,
      origin.latitude,
      origin.longitude,
    );
    if (moved >= 800) return null;
    return _sortedByDistance(_cache, origin).take(limit).toList();
  }

  /// Chỉ gọi endpoint Overpass **đầu tiên** (primary) — không loop nhiều mirror.
  Future<List<GasStation>> _queryOverpassPrimary(
    String query, {
    required LatLng origin,
    double? maxRadiusKm,
  }) async {
    final endpoints = OsmConfig.overpassEndpoints;
    if (endpoints.isEmpty) return const [];
    final endpoint = endpoints.first;

    try {
      final response = await _overpassHttp.post(
        Uri.parse(endpoint),
        headers: {
          ...OsmConfig.headers,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'data=${Uri.encodeComponent(query)}',
      );

      if (response.statusCode != 200) {
        debugPrint('[GasStation] Overpass HTTP ${response.statusCode}');
        return const [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? const [];
      final stations = _parseOverpassElements(
        elements,
        origin: origin,
        maxRadiusKm: maxRadiusKm,
      );
      if (stations.isNotEmpty) {
        debugPrint('[GasStation] Overpass primary — ${stations.length} trạm');
      }
      return stations;
    } catch (e) {
      debugPrint('[GasStation] Overpass fail: $e');
      return const [];
    }
  }

  Future<List<GasStation>> _queryNominatimBoundsOnce({
    required double south,
    required double west,
    required double north,
    required double east,
    required LatLng originForDistance,
    required int limit,
  }) async {
    final uri = Uri.parse('${OsmConfig.nominatimBase}/search').replace(
      queryParameters: {
        'amenity': 'fuel',
        'format': 'json',
        'countrycodes': 'vn',
        'limit': '$limit',
        'viewbox': '$west,$north,$east,$south',
        'bounded': '1',
        'accept-language': 'vi',
      },
    );

    try {
      final response = await NominatimHttp.shared.get(uri);

      if (response.statusCode != 200) return const [];

      final list = jsonDecode(response.body) as List<dynamic>;
      final stations = _parseNominatimResults(list, origin: originForDistance);
      if (stations.isNotEmpty) {
        debugPrint('[GasStation] Nominatim fallback — ${stations.length} trạm');
      }
      return stations;
    } catch (e) {
      debugPrint('[GasStation] Nominatim fail: $e');
      return const [];
    }
  }

  List<GasStation> _parseNominatimResults(
    List<dynamic> list, {
    required LatLng origin,
  }) {
    final stations = <GasStation>[];
    for (final raw in list) {
      final el = raw as Map<String, dynamic>;
      final lat = double.tryParse(el['lat']?.toString() ?? '');
      final lon = double.tryParse(el['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      final loc = LatLng(lat, lon);
      final km = Geolocator.distanceBetween(
            origin.latitude,
            origin.longitude,
            lat,
            lon,
          ) /
          1000;

      final osmType = (el['osm_type'] ?? 'node').toString();
      final osmId = int.tryParse(el['osm_id']?.toString() ?? '') ?? 0;
      final name = (el['name'] ?? el['display_name'] ?? 'Cây xăng').toString();
      final address = (el['display_name'] ?? 'Việt Nam').toString();

      stations.add(
        GasStation(
          id: '${osmType}_$osmId',
          osmType: osmType,
          osmId: osmId,
          name: name.split(',').first.trim(),
          address: address,
          location: loc,
          distanceKm: km,
          brand: 'Fuel',
        ),
      );
    }
    return stations;
  }

  List<GasStation> _parseOverpassElements(
    List<dynamic> elements, {
    required LatLng origin,
    double? maxRadiusKm,
  }) {
    final stations = <GasStation>[];
    for (final raw in elements) {
      final el = raw as Map<String, dynamic>;
      final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final lat = _readLat(el);
      final lon = _readLon(el);
      if (lat == null || lon == null) continue;

      final loc = LatLng(lat, lon);
      final meters = Geolocator.distanceBetween(
        origin.latitude,
        origin.longitude,
        lat,
        lon,
      );
      final km = meters / 1000;
      if (maxRadiusKm != null && km > maxRadiusKm) continue;

      final name = (tags['name'] ??
              tags['brand'] ??
              tags['operator'] ??
              'Cây xăng')
          .toString();
      final brand = (tags['brand'] ?? tags['operator'] ?? 'Fuel').toString();
      final operatorName = tags['operator']?.toString();
      final address = _formatAddress(tags) ?? 'Việt Nam';
      final openingHours = tags['opening_hours']?.toString();
      final phone = (tags['phone'] ?? tags['contact:phone'])?.toString();
      final website =
          (tags['website'] ?? tags['contact:website'])?.toString();
      final fuelTypes = _readFuelTypes(tags);
      final services = _readServices(tags);
      final osmType = (el['type'] ?? '').toString();
      final osmId = (el['id'] as num?)?.toInt() ?? 0;

      stations.add(
        GasStation(
          id: '${el['type']}_${el['id']}',
          osmType: osmType,
          osmId: osmId,
          name: name,
          address: address,
          location: loc,
          distanceKm: km,
          brand: brand,
          operatorName: operatorName,
          openingHours: openingHours,
          phone: phone,
          website: website,
          fuelTypes: fuelTypes,
          services: services,
          tags: tags.map((k, v) => MapEntry(k, v.toString())),
        ),
      );
    }
    return stations;
  }

  List<GasStation> _sortedByDistance(List<GasStation> list, LatLng origin) {
    final copy = [...list];
    copy.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return copy;
  }

  double? _readLat(Map<String, dynamic> el) {
    if (el['lat'] != null) return (el['lat'] as num).toDouble();
    final center = el['center'] as Map?;
    if (center != null) return (center['lat'] as num).toDouble();
    return null;
  }

  double? _readLon(Map<String, dynamic> el) {
    if (el['lon'] != null) return (el['lon'] as num).toDouble();
    final center = el['center'] as Map?;
    if (center != null) return (center['lon'] as num).toDouble();
    return null;
  }

  String? _formatAddress(Map<String, dynamic> tags) {
    final parts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:city'] ?? tags['addr:district'],
      tags['addr:province'] ?? tags['addr:state'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  List<String> _readFuelTypes(Map<String, dynamic> tags) {
    final labels = <String>[];
    const mapping = <String, String>{
      'fuel:octane_92': 'Xăng 92',
      'fuel:octane_95': 'Xăng 95',
      'fuel:e10': 'E10',
      'fuel:e5': 'E5',
      'fuel:diesel': 'Dầu diesel',
      'fuel:gas': 'Gas',
      'fuel:lpg': 'LPG',
      'fuel:cng': 'CNG',
      'fuel:adblue': 'AdBlue',
      'fuel:electricity': 'Sạc điện',
    };

    for (final entry in mapping.entries) {
      final v = tags[entry.key]?.toString().toLowerCase();
      if (v == 'yes' || v == 'true' || v == '1') labels.add(entry.value);
    }

    final raw = tags['fuel']?.toString();
    if (raw != null && raw.trim().isNotEmpty) {
      final parts = raw.split(RegExp(r'[;,]')).map((s) => s.trim()).toList();
      for (final p in parts) {
        if (p.isEmpty) continue;
        if (!labels.contains(p)) labels.add(p);
      }
    }
    return labels;
  }

  List<String> _readServices(Map<String, dynamic> tags) {
    final services = <String>[];
    const mapping = <String, String>{
      'shop': 'Cửa hàng',
      'car_wash': 'Rửa xe',
      'compressed_air': 'Bơm hơi',
      'vacuum_cleaner': 'Máy hút bụi',
      'toilets': 'Nhà vệ sinh',
      'payment:cash': 'Thanh toán tiền mặt',
      'payment:credit_cards': 'Thẻ tín dụng',
      'payment:debit_cards': 'Thẻ ghi nợ',
      'wheelchair': 'Hỗ trợ xe lăn',
      'atm': 'ATM',
    };

    for (final entry in mapping.entries) {
      final v = tags[entry.key]?.toString().toLowerCase();
      if (v == null) continue;

      if (entry.key == 'shop' || entry.key == 'atm') {
        if (v.trim().isNotEmpty && v != 'no' && v != 'false' && v != '0') {
          services.add(entry.value);
        }
        continue;
      }

      if (v == 'yes' || v == 'true' || v == '1') services.add(entry.value);
    }
    return services;
  }
}
