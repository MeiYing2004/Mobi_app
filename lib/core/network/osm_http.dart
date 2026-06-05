import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'package:fuel_tracker_app/core/config/osm_config.dart';

/// HTTP 429 sau khi đã retry — caller có thể map sang thông báo người dùng.
class HttpRateLimitException implements Exception {
  const HttpRateLimitException([this.message = 'Quá nhiều yêu cầu — thử lại sau']);

  final String message;

  @override
  String toString() => message;
}

/// HTTP client dùng chung cho Nominatim / OSRM — timeout, retry, User-Agent.
class OsmHttpClient {
  OsmHttpClient({
    this.timeout = const Duration(seconds: 12),
    this.maxAttempts = 2,
    this.minGap = Duration.zero,
    this.max429Retries = 3,
    this.baseBackoffMs = 1000,
    this.maxBackoffMs = 30000,
    Map<String, String>? headers,
  }) : _headers = headers ?? OsmConfig.headers;

  /// Nominatim: User-Agent hợp lệ, 1 req/s, backoff 429.
  factory OsmHttpClient.forNominatim() => OsmHttpClient(
        timeout: const Duration(seconds: 12),
        maxAttempts: 2,
        minGap: const Duration(milliseconds: 1100),
        max429Retries: 3,
        headers: OsmConfig.nominatimHeaders,
      );

  factory OsmHttpClient.forOsrm() => OsmHttpClient(
        timeout: const Duration(seconds: 12),
        maxAttempts: 2,
        minGap: Duration.zero,
        max429Retries: 0,
      );

  /// Overpass — một endpoint chính, timeout 14s, tối đa 2 lần thử.
  factory OsmHttpClient.forOverpass() => OsmHttpClient(
        timeout: const Duration(seconds: 14),
        maxAttempts: 2,
        minGap: Duration.zero,
        max429Retries: 0,
      );

  final Duration timeout;
  final int maxAttempts;
  final Duration minGap;
  final int max429Retries;
  final int baseBackoffMs;
  final int maxBackoffMs;
  final Map<String, String> _headers;

  DateTime? _lastRequestAt;

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final merged = {..._headers, if (headers != null) ...headers};
    return _execute(
      () => http.post(uri, headers: merged, body: body).timeout(timeout),
    );
  }

  Future<http.Response> get(Uri uri) async {
    return _execute(() => http.get(uri, headers: _headers).timeout(timeout));
  }

  Future<http.Response> _execute(Future<http.Response> Function() request) async {
    Object? lastError;
    var networkAttempt = 0;

    while (networkAttempt < maxAttempts) {
      networkAttempt++;
      await _respectRateLimit();

      http.Response res;
      try {
        res = await request();
        _lastRequestAt = DateTime.now();
      } on TimeoutException {
        lastError = TimeoutException('Hết thời gian phản hồi');
        if (networkAttempt >= maxAttempts) rethrow;
        continue;
      } on SocketException {
        lastError = const SocketException('Không có kết nối mạng');
        if (networkAttempt >= maxAttempts) rethrow;
        continue;
      } on http.ClientException catch (e) {
        lastError = e;
        if (networkAttempt >= maxAttempts) rethrow;
        continue;
      }

      if (res.statusCode == 429) {
        if (max429Retries <= 0) {
          throw const HttpRateLimitException();
        }
        var last429 = res;
        for (var retry = 1; retry <= max429Retries; retry++) {
          await Future<void>.delayed(
            backoffDelayFor429(
              retry,
              last429,
              baseMs: baseBackoffMs,
              maxMs: maxBackoffMs,
            ),
          );
          await _respectRateLimit();
          try {
            last429 = await request();
            _lastRequestAt = DateTime.now();
          } on TimeoutException {
            lastError = TimeoutException('Hết thời gian phản hồi');
            break;
          } on SocketException {
            lastError = const SocketException('Không có kết nối mạng');
            break;
          } on http.ClientException catch (e) {
            lastError = e;
            break;
          }
          if (last429.statusCode != 429) return last429;
        }
        throw const HttpRateLimitException();
      }

      return res;
    }

    throw lastError ?? Exception('Lỗi HTTP không xác định');
  }

  /// Thời gian chờ sau HTTP 429 (ưu tiên header Retry-After).
  static Duration backoffDelayFor429(
    int attempt,
    http.Response response, {
    int baseMs = 1000,
    int maxMs = 30000,
  }) {
    final retryAfter = response.headers['retry-after']?.trim();
    if (retryAfter != null && retryAfter.isNotEmpty) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds.clamp(1, maxMs ~/ 1000));
      }
      final date = DateTime.tryParse(retryAfter);
      if (date != null) {
        final wait = date.difference(DateTime.now());
        if (wait > Duration.zero) {
          return wait > Duration(milliseconds: maxMs)
              ? Duration(milliseconds: maxMs)
              : wait;
        }
      }
    }

    final expMs = baseMs * math.pow(2, attempt - 1).toInt();
    return Duration(milliseconds: expMs.clamp(baseMs, maxMs));
  }

  Future<void> _respectRateLimit() async {
    if (minGap <= Duration.zero) return;
    final last = _lastRequestAt;
    if (last == null) return;
    final elapsed = DateTime.now().difference(last);
    if (elapsed < minGap) {
      await Future<void>.delayed(minGap - elapsed);
    }
  }
}

/// Client Nominatim dùng chung — rate limit + User-Agent theo chính sách OSM.
class NominatimHttp {
  NominatimHttp._();

  static final OsmHttpClient shared = OsmHttpClient.forNominatim();
}
