import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/core/config/osm_config.dart';
import 'package:fuel_tracker_app/core/network/osm_http.dart';
import 'package:fuel_tracker_app/features/geocoding/core/place_location_utils.dart';
import 'package:fuel_tracker_app/core/ttl_cache.dart';
import 'package:fuel_tracker_app/features/geocoding/core/vietnamese_text_utils.dart';
import 'package:fuel_tracker_app/features/geocoding/data/models/place_model.dart';
import 'package:fuel_tracker_app/features/geocoding/data/exceptions/map_navigation_exceptions.dart';
import 'package:fuel_tracker_app/features/geocoding/data/models/address_components.dart';

/// Forward + reverse geocoding qua Nominatim (OpenStreetMap).
class NominatimGeocodingService {
  NominatimGeocodingService({OsmHttpClient? httpClient})
      : _http = httpClient ?? NominatimHttp.shared,
        _searchCache = TtlCache<List<PlaceSuggestion>>(
          ttl: AppConstants.geocodingCacheTtl,
          maxEntries: AppConstants.geocodingCacheMaxEntries,
        ),
        _detailsCache = TtlCache<PlaceDetails>(
          ttl: AppConstants.geocodingCacheTtl,
          maxEntries: AppConstants.geocodingCacheMaxEntries,
        );

  final OsmHttpClient _http;
  final TtlCache<List<PlaceSuggestion>> _searchCache;
  final TtlCache<PlaceDetails> _detailsCache;
  int _generation = 0;

  Future<List<PlaceSuggestion>> search({
    required String query,
    LatLng? bias,
  }) async {
    final variants = VietnameseTextUtils.searchVariants(query);
    if (variants.isEmpty) return const [];

    final generation = ++_generation;
    final merged = <String, PlaceSuggestion>{};

    for (final variant in variants) {
      final hits = await _searchOnce(query: variant, bias: bias);
      if (generation != _generation) return const [];
      for (final hit in hits) {
        merged.putIfAbsent(hit.placeId, () => hit);
      }
      if (merged.length >= AppConstants.searchSuggestionLimit) break;
    }

    var out = merged.values.toList();
    if (bias != null && out.length > 1) {
      out.sort((a, b) {
        final da = a.location == null
            ? double.infinity
            : const Distance().as(LengthUnit.Meter, bias, a.location!);
        final db = b.location == null
            ? double.infinity
            : const Distance().as(LengthUnit.Meter, bias, b.location!);
        return da.compareTo(db);
      });
    }

    if (out.length > AppConstants.searchSuggestionLimit) {
      out = out.sublist(0, AppConstants.searchSuggestionLimit);
    }
    return out;
  }

  Future<PlaceDetails> reverse({required LatLng location}) async {
    if (!PlaceLocationValidator.isNavigable(location)) {
      throw GeocodingException(
        'Tọa độ không hợp lệ: ${PlaceLocationValidator.rejectReason(location)}',
      );
    }

    final cacheKey = _reverseCacheKey(location);
    final cached = _detailsCache.get(cacheKey);
    if (cached != null) return cached;

    final uri = Uri.parse('${OsmConfig.nominatimBase}/reverse').replace(
      queryParameters: {
        'lat': '${location.latitude}',
        'lon': '${location.longitude}',
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'vi',
        'zoom': '18',
      },
    );

    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw GeocodingException('Nominatim reverse HTTP ${res.statusCode}');
    }

    final m = jsonDecode(res.body) as Map<String, dynamic>;
    if (m.containsKey('error')) {
      throw GeocodingException(
        m['error']?.toString() ?? 'Không tìm thấy địa chỉ tại vị trí này',
      );
    }

    final parsed = _parsePlaceDetails(m);
    if (parsed == null) {
      throw const GeocodingException('Reverse geocoding thiếu tọa độ hợp lệ');
    }
    _detailsCache.put(cacheKey, parsed);
    return parsed;
  }

  Future<PlaceDetails> resolveForNavigation(PlaceSuggestion suggestion) async {
    final inline = suggestion.location;
    if (inline != null && PlaceLocationValidator.isNavigable(inline)) {
      return PlaceDetails(
        placeId: suggestion.placeId,
        name: suggestion.primaryText,
        formattedAddress: suggestion.secondaryText,
        location: inline,
        address: suggestion.address,
      );
    }

    if (_supportsLookup(suggestion.placeId)) {
      final lookupKey = 'lookup:${suggestion.placeId}';
      final cached = _detailsCache.get(lookupKey);
      if (cached != null) return cached;
      final details = await _lookupByOsmId(suggestion.placeId, suggestion);
      _detailsCache.put(lookupKey, details);
      return details;
    }

    throw GeocodingException(
      'Gợi ý "${suggestion.primaryText}" thiếu tọa độ',
    );
  }

  Future<PlaceDetails> resolveFromQuery({
    required String query,
    LatLng? bias,
  }) async {
    final list = await search(query: query, bias: bias);
    if (list.isEmpty) {
      throw const GeocodingException('Không tìm thấy địa điểm tại Việt Nam');
    }
    return resolveForNavigation(list.first);
  }

  Future<List<PlaceSuggestion>> _searchOnce({
    required String query,
    LatLng? bias,
  }) async {
    final cacheKey = _searchCacheKey(query, bias);
    final cached = _searchCache.get(cacheKey);
    if (cached != null) return cached;

    final params = <String, String>{
      'q': query,
      'format': 'json',
      'countrycodes': 'vn',
      'limit': '${AppConstants.searchSuggestionLimit}',
      'accept-language': 'vi',
      'addressdetails': '1',
      'dedupe': '1',
    };

    if (bias != null) {
      params['viewbox'] =
          '${bias.longitude - 0.35},${bias.latitude + 0.25},'
          '${bias.longitude + 0.35},${bias.latitude - 0.25}';
      params['bounded'] = '0';
    }

    final uri = Uri.parse('${OsmConfig.nominatimBase}/search').replace(
      queryParameters: params,
    );

    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw GeocodingException('Nominatim HTTP ${res.statusCode}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    final results = parseSearchResults(list, bias: bias);
    _searchCache.put(cacheKey, results);
    return results;
  }

  static String _searchCacheKey(String query, LatLng? bias) {
    final q = query.trim().toLowerCase();
    if (bias == null) return 'search:$q';
    final lat = bias.latitude.toStringAsFixed(3);
    final lon = bias.longitude.toStringAsFixed(3);
    return 'search:$q@$lat,$lon';
  }

  static String _reverseCacheKey(LatLng location) {
    final lat = location.latitude.toStringAsFixed(5);
    final lon = location.longitude.toStringAsFixed(5);
    return 'reverse:$lat,$lon';
  }

  static List<PlaceSuggestion> parseSearchResults(
    List<dynamic> raw, {
    LatLng? bias,
  }) {
    final out = <PlaceSuggestion>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final parsed = _parseSuggestion(item);
      if (parsed != null) out.add(parsed);
    }

    if (bias != null && out.length > 1) {
      out.sort((a, b) {
        final da = a.location == null
            ? double.infinity
            : const Distance().as(LengthUnit.Meter, bias, a.location!);
        final db = b.location == null
            ? double.infinity
            : const Distance().as(LengthUnit.Meter, bias, b.location!);
        return da.compareTo(db);
      });
    }
    return out;
  }

  static PlaceSuggestion? _parseSuggestion(Map<String, dynamic> m) {
    final lat = double.tryParse('${m['lat']}');
    final lon = double.tryParse('${m['lon']}');
    if (lat == null || lon == null) return null;

    final location = LatLng(lat, lon);
    if (!PlaceLocationValidator.isNavigable(location)) return null;

    final addressMap = (m['address'] as Map?)?.cast<String, dynamic>();
    final address = AddressComponents.fromNominatim(addressMap);

    final osmType = m['osm_type'] as String?;
    final osmId = m['osm_id']?.toString();
    final String placeId;
    if (osmType != null && osmId != null && osmId.isNotEmpty) {
      placeId = '$osmType/$osmId';
    } else {
      final pid = m['place_id']?.toString();
      if (pid == null || pid.isEmpty) return null;
      placeId = 'nominatim/$pid';
    }

    final name = m['name'] as String? ??
        m['display_name']?.toString().split(',').first.trim() ??
        'Địa điểm';
    final display = m['display_name'] as String? ?? name;
    final type = m['type'] as String? ?? m['class'] as String? ?? '';

    return PlaceSuggestion(
      placeId: placeId,
      primaryText: name,
      secondaryText: subtitleFor(name, display, address: address),
      types: type.isEmpty ? const [] : [type],
      location: location,
      address: address.isEmpty ? null : address,
    );
  }

  static PlaceDetails? _parsePlaceDetails(Map<String, dynamic> m) {
    final lat = double.tryParse('${m['lat']}');
    final lon = double.tryParse('${m['lon']}');
    if (lat == null || lon == null) return null;

    final location = LatLng(lat, lon);
    if (!PlaceLocationValidator.isNavigable(location)) return null;

    final addressMap = (m['address'] as Map?)?.cast<String, dynamic>();
    final address = AddressComponents.fromNominatim(addressMap);

    final osmType = m['osm_type'] as String?;
    final osmId = m['osm_id']?.toString();
    final placeId = osmType != null && osmId != null && osmId.isNotEmpty
        ? '$osmType/$osmId'
        : 'nominatim/${m['place_id']}';

    final name = m['name'] as String? ??
        m['display_name']?.toString().split(',').first.trim() ??
        'Địa điểm';
    final display = m['display_name'] as String? ?? name;

    return PlaceDetails(
      placeId: placeId,
      name: name,
      formattedAddress: subtitleFor(name, display, address: address),
      location: location,
      address: address.isEmpty ? null : address,
    );
  }

  static String subtitleFor(
    String name,
    String display, {
    AddressComponents? address,
  }) {
    if (address != null && !address.isEmpty) {
      final short = address.shortLabel;
      if (short.isNotEmpty) return short;
    }

    final trimmed = display.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.toLowerCase().startsWith(name.toLowerCase())) {
      final rest =
          trimmed.substring(name.length).replaceFirst(RegExp(r'^,\s*'), '');
      return rest.isEmpty ? trimmed : rest;
    }
    return trimmed;
  }

  bool _supportsLookup(String placeId) {
    final parts = placeId.split('/');
    if (parts.length != 2) return false;
    return parts[0] == 'node' || parts[0] == 'way' || parts[0] == 'relation';
  }

  Future<PlaceDetails> _lookupByOsmId(
    String placeId,
    PlaceSuggestion fallback,
  ) async {
    final parts = placeId.split('/');
    final prefix = switch (parts[0]) {
      'node' => 'N',
      'way' => 'W',
      'relation' => 'R',
      _ => throw GeocodingException('OSM type không hỗ trợ: ${parts[0]}'),
    };

    final uri = Uri.parse('${OsmConfig.nominatimBase}/lookup').replace(
      queryParameters: {
        'osm_ids': '$prefix${parts[1]}',
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'vi',
      },
    );

    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw GeocodingException('Lookup HTTP ${res.statusCode}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    if (list.isEmpty) {
      throw const GeocodingException('Không tìm thấy địa điểm');
    }

    final parsed = _parsePlaceDetails(list.first as Map<String, dynamic>);
    if (parsed == null) {
      throw const GeocodingException('Lookup thiếu tọa độ');
    }
    return parsed;
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _http.get(uri);
    } on HttpRateLimitException catch (e) {
      throw GeocodingException(e.message);
    } on TimeoutException {
      throw const GeocodingException('Hết thời gian phản hồi Nominatim');
    } on SocketException {
      throw const GeocodingException('Không có kết nối mạng');
    } on http.ClientException catch (e) {
      throw GeocodingException('Lỗi kết nối: ${e.message}');
    } on FormatException {
      throw const GeocodingException('Phản hồi Nominatim không hợp lệ');
    }
  }
}
