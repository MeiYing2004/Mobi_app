import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/lan_dev_config.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/weather_snapshot.dart';

/// Dự báo thời tiết qua Open-Meteo (không cần API key).
class WeatherService {
  LatLng? _cachePoint;
  WeatherSnapshot? _cache;
  DateTime? _cacheTime;

  Future<WeatherSnapshot?> fetchCurrent({
    required LatLng location,
    String locationLabel = 'Vị trí hiện tại',
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cache != null &&
        _cachePoint != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < const Duration(minutes: 15)) {
      final d = const Distance().as(
        LengthUnit.Meter,
        _cachePoint!,
        location,
      );
      if (d < 2500) return _cache;
    }

    final query = {
      'latitude': '${location.latitude}',
      'longitude': '${location.longitude}',
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'hourly': 'temperature_2m,precipitation_probability,weather_code',
      'daily': 'temperature_2m_max,temperature_2m_min,weather_code',
      'timezone': 'auto',
      'forecast_days': '2',
    };
    final uri = LanDevConfig.useDevProxy
        ? Uri.parse('${LanDevConfig.proxyPath('openmeteo')}/v1/forecast')
            .replace(queryParameters: query)
        : Uri.https('api.open-meteo.com', '/v1/forecast', query);

    try {
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0;
      final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
      final code = (current['weather_code'] as num?)?.toInt() ?? 0;
      final windMs = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;
      final windKmh = windMs * 3.6;

      final daily = data['daily'] as Map<String, dynamic>?;
      int? highC;
      int? lowC;
      if (daily != null) {
        final maxList = daily['temperature_2m_max'] as List<dynamic>?;
        final minList = daily['temperature_2m_min'] as List<dynamic>?;
        if (maxList != null && maxList.isNotEmpty) {
          highC = (maxList.first as num).round();
        }
        if (minList != null && minList.isNotEmpty) {
          lowC = (minList.first as num).round();
        }
      }

      final alerts = _buildAlerts(
        data: data,
        temperatureC: temp,
        windKmh: windKmh,
      );

      final snapshot = WeatherSnapshot(
        locationLabel: locationLabel,
        temperatureC: temp,
        highC: highC,
        lowC: lowC,
        conditionLabel: _wmoLabel(code),
        weatherCode: code,
        windKmh: windKmh,
        humidityPercent: humidity,
        alerts: alerts,
        fetchedAt: DateTime.now(),
      );

      _cache = snapshot;
      _cachePoint = location;
      _cacheTime = DateTime.now();
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  List<WeatherAlert> _buildAlerts({
    required Map<String, dynamic> data,
    required double temperatureC,
    required double windKmh,
  }) {
    final alerts = <WeatherAlert>[];
    final hourly = data['hourly'] as Map<String, dynamic>?;
    if (hourly != null) {
      final precip = hourly['precipitation_probability'] as List<dynamic>?;
      final codes = hourly['weather_code'] as List<dynamic>?;
      if (precip != null && precip.length >= 3) {
        final next3 = precip
            .take(3)
            .map((e) => (e as num?)?.toInt() ?? 0)
            .toList();
        final maxRain = next3.reduce((a, b) => a > b ? a : b);
        if (maxRain >= 55) {
          alerts.add(
            WeatherAlert(
              title: 'Mưa sắp tới',
              message:
                  'Xác suất mưa ~$maxRain% trong 3 giờ tới — có thể làm tăng mức tiêu hao.',
              severity: WeatherAlertSeverity.warning,
            ),
          );
        } else if (maxRain >= 35) {
          alerts.add(
            WeatherAlert(
              title: 'Khả năng mưa',
              message: 'Xác suất mưa ~$maxRain% — nên dự phòng thời gian di chuyển.',
              severity: WeatherAlertSeverity.info,
            ),
          );
        }
      }
      if (codes != null && codes.isNotEmpty) {
        final code = (codes.first as num?)?.toInt() ?? 0;
        if (code >= 95) {
          alerts.add(
            const WeatherAlert(
              title: 'Giông bão',
              message: 'Thời tiết xấu — hạn chế di chuyển nếu không cần thiết.',
              severity: WeatherAlertSeverity.critical,
            ),
          );
        }
      }
    }

    if (temperatureC >= 35) {
      alerts.add(
        WeatherAlert(
          title: 'Nắng nóng',
          message:
              'Nhiệt độ ${temperatureC.round()}°C — điều hòa/lái mạnh có thể làm tốn xăng hơn.',
          severity: WeatherAlertSeverity.warning,
        ),
      );
    }

    if (windKmh >= 45) {
      alerts.add(
        WeatherAlert(
          title: 'Gió mạnh',
          message:
              'Gió ~${windKmh.round()} km/h — tiêu hao nhiên liệu có thể tăng trên cao tốc.',
          severity: WeatherAlertSeverity.warning,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        const WeatherAlert(
          title: 'Thời tiết ổn',
          message: 'Không có cảnh báo đặc biệt ảnh hưởng tới nhiên liệu.',
          severity: WeatherAlertSeverity.info,
        ),
      );
    }

    return alerts;
  }

  static String _wmoLabel(int code) {
    if (code == 0) return 'Trời quang';
    if (code <= 3) return 'Ít mây';
    if (code <= 48) return 'Sương mù';
    if (code <= 57) return 'Mưa phùn';
    if (code <= 67) return 'Mưa';
    if (code <= 77) return 'Tuyết';
    if (code <= 82) return 'Mưa rào';
    if (code <= 86) return 'Mưa tuyết';
    if (code <= 99) return 'Giông';
    return 'Không xác định';
  }
}
