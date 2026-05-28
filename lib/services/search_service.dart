import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/osm_config.dart';
import '../models/place_model.dart';

class SearchException implements Exception {
  final String message;
  const SearchException(this.message);

  @override
  String toString() => message;
}

/// Tìm kiếm địa điểm Việt Nam qua Nominatim (OpenStreetMap).
class SearchService {
  SearchService();
  static const int _maxAttempts = 2;

  final List<PlaceDetails> _history = [];
  List<PlaceDetails> get recentPlaces => List.unmodifiable(_history);

  Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    LatLng? biasLocation,
  }) async {
    final q = input.trim();
    if (q.isEmpty) return const [];

    final params = <String, String>{
      'q': q,
      'format': 'json',
      'addressdetails': '1',
      'countrycodes': 'vn',
      'limit': '8',
      'accept-language': 'vi',
    };

    if (biasLocation != null) {
      params['viewbox'] =
          '${biasLocation.longitude - 0.35},${biasLocation.latitude + 0.25},'
          '${biasLocation.longitude + 0.35},${biasLocation.latitude - 0.25}';
      params['bounded'] = '0';
    }

    final uri = Uri.parse('${OsmConfig.nominatimBase}/search').replace(
      queryParameters: params,
    );

    http.Response res;
    try {
      res = await _getWithRetry(uri);
    } on TimeoutException {
      throw const SearchException('Hết thời gian phản hồi từ Nominatim');
    } on SocketException {
      throw const SearchException('Không có kết nối mạng để tìm kiếm');
    } on http.ClientException catch (e) {
      throw SearchException('Lỗi kết nối Nominatim: ${e.message}');
    } on FormatException {
      throw const SearchException('Phản hồi tìm kiếm không hợp lệ');
    }

    if (res.statusCode != 200) {
      throw SearchException('Nominatim HTTP ${res.statusCode}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((raw) {
      final m = raw as Map<String, dynamic>;
      final lat = double.tryParse('${m['lat']}') ?? 0;
      final lon = double.tryParse('${m['lon']}') ?? 0;
      final osmType = m['osm_type'] as String? ?? 'node';
      final osmId = m['osm_id']?.toString() ?? m['place_id']?.toString() ?? '';
      final name = m['name'] as String? ??
          m['display_name']?.toString().split(',').first ??
          'Địa điểm';
      final display = m['display_name'] as String? ?? name;
      final type = m['type'] as String? ?? m['class'] as String? ?? '';

      return PlaceSuggestion(
        placeId: '$osmType/$osmId',
        primaryText: name,
        secondaryText: display,
        types: type.isEmpty ? const [] : [type],
        location: LatLng(lat, lon),
      );
    }).toList(growable: false);
  }

  Future<PlaceDetails> fetchDetails({required String placeId}) async {
    final cached = _history.where((p) => p.placeId == placeId).firstOrNull;
    if (cached != null) return cached;

    final parts = placeId.split('/');
    if (parts.length != 2) {
      throw SearchException('placeId không hợp lệ: $placeId');
    }

    final osmPrefix = switch (parts[0]) {
      'node' => 'N',
      'way' => 'W',
      'relation' => 'R',
      _ => throw SearchException('OSM type không hỗ trợ: ${parts[0]}'),
    };

    final uri = Uri.parse('${OsmConfig.nominatimBase}/lookup').replace(
      queryParameters: {
        'osm_ids': '$osmPrefix${parts[1]}',
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'vi',
      },
    );

    http.Response res;
    try {
      res = await _getWithRetry(uri);
    } on TimeoutException {
      throw const SearchException('Hết thời gian phản hồi tra cứu địa điểm');
    } on SocketException {
      throw const SearchException('Không có kết nối mạng để tra cứu địa điểm');
    } on http.ClientException catch (e) {
      throw SearchException('Lỗi tra cứu địa điểm: ${e.message}');
    } on FormatException {
      throw const SearchException('Phản hồi tra cứu địa điểm không hợp lệ');
    }

    if (res.statusCode != 200) {
      throw SearchException('Nominatim lookup HTTP ${res.statusCode}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    if (list.isEmpty) throw const SearchException('Không tìm thấy địa điểm');

    final m = list.first as Map<String, dynamic>;
    return _detailsFromNominatim(m, placeId);
  }

  PlaceDetails detailsFromSuggestion(PlaceSuggestion suggestion) {
    if (suggestion.location == null) {
      throw SearchException('Thiếu tọa độ cho gợi ý');
    }
    return PlaceDetails(
      placeId: suggestion.placeId,
      name: suggestion.primaryText,
      formattedAddress: suggestion.secondaryText,
      location: suggestion.location!,
    );
  }

  void rememberPlace(PlaceDetails place) {
    _history.removeWhere((p) => p.placeId == place.placeId);
    _history.insert(0, place);
    if (_history.length > 12) _history.removeLast();
  }

  void clearHistory() {
    _history.clear();
  }

  PlaceDetails _detailsFromNominatim(Map<String, dynamic> m, String placeId) {
    final lat = double.tryParse('${m['lat']}') ?? 0;
    final lon = double.tryParse('${m['lon']}') ?? 0;
    final name = m['name'] as String? ??
        m['display_name']?.toString().split(',').first ??
        'Địa điểm';

    return PlaceDetails(
      placeId: placeId,
      name: name,
      formattedAddress: m['display_name'] as String? ?? name,
      location: LatLng(lat, lon),
    );
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await http
            .get(uri, headers: OsmConfig.headers)
            .timeout(const Duration(seconds: 12));
      } catch (e) {
        lastError = e;
        if (attempt == _maxAttempts) rethrow;
      }
    }
    throw lastError ?? const SearchException('Lỗi không xác định khi gọi Nominatim');
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
