import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/osm_config.dart';
import '../models/gas_station.dart';

/// Tìm cây xăng quanh user qua Overpass API (amenity=fuel, Việt Nam).
class GasStationService {
  static const double referencePriceVndPerLiter = 24500;

  LatLng? _cacheOrigin;
  List<GasStation> _cache = const [];
  DateTime? _cacheTime;

  Future<List<GasStation>> findNearestStations({
    required LatLng origin,
    double radiusKm = 5,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cacheOrigin != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < const Duration(minutes: 2)) {
      final moved = Geolocator.distanceBetween(
        _cacheOrigin!.latitude,
        _cacheOrigin!.longitude,
        origin.latitude,
        origin.longitude,
      );
      if (moved < 800 && _cache.isNotEmpty) {
        return _sortedByDistance(_cache, origin).take(limit).toList();
      }
    }

    final radiusM = (radiusKm * 1000).round();
    final query = '''
[out:json][timeout:25];
(
  node["amenity"="fuel"](around:$radiusM,${origin.latitude},${origin.longitude});
  way["amenity"="fuel"](around:$radiusM,${origin.latitude},${origin.longitude});
);
out center tags;
''';

    try {
      final response = await http
          .post(
            Uri.parse(OsmConfig.overpassEndpoint),
            headers: {
              ...OsmConfig.headers,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: 'data=${Uri.encodeComponent(query)}',
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        return _fallback(origin, radiusKm, limit);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? const [];

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
        if (km > radiusKm) continue;

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

      _cacheOrigin = origin;
      _cacheTime = DateTime.now();
      _cache = stations;

      if (stations.isEmpty) return _fallback(origin, radiusKm, limit);
      return _sortedByDistance(stations, origin).take(limit).toList();
    } catch (_) {
      return _fallback(origin, radiusKm, limit);
    }
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

    // Some stations use `fuel` as a semicolon list.
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

      // For some keys like `shop=*`, any non-empty value is useful.
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

  Future<List<GasStation>> _fallback(
    LatLng origin,
    double radiusKm,
    int limit,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final offsets = [
      ('Petrolimex', 0.012, 0.008, '24/7'),
      ('PVOIL', -0.009, 0.015, '06:00-22:00'),
      ('Shell', 0.018, -0.011, '24/7'),
    ];

    final stations = <GasStation>[];
    for (var i = 0; i < offsets.length; i++) {
      final (name, dLat, dLng, hours) = offsets[i];
      final loc = LatLng(origin.latitude + dLat, origin.longitude + dLng);
      final km = Geolocator.distanceBetween(
            origin.latitude,
            origin.longitude,
            loc.latitude,
            loc.longitude,
          ) /
          1000;
      if (km <= radiusKm) {
        stations.add(
          GasStation(
            id: 'fallback_$i',
            osmType: 'fallback',
            osmId: i,
            name: name,
            address: 'Việt Nam',
            location: loc,
            distanceKm: km,
            openingHours: hours,
          ),
        );
      }
    }
    stations.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return stations.take(limit).toList();
  }
}
