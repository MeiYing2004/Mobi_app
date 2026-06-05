import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/ios_design_tokens.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/weather_snapshot.dart';

/// Thẻ thời tiết + cảnh báo trong màn Phân tích nhiên liệu.
class FuelWeatherCard extends StatelessWidget {
  const FuelWeatherCard({
    super.key,
    required this.weather,
    required this.loading,
    required this.onRefresh,
  });

  final WeatherSnapshot? weather;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Thông báo thời tiết',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
            IconButton(
              onPressed: loading ? null : onRefresh,
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VehicleUi.accentBlue,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              color: Colors.white70,
              tooltip: 'Cập nhật',
            ),
          ],
        ),
        if (weather == null && !loading)
          Text(
            'Chưa lấy được dữ liệu thời tiết. Bật GPS và thử lại.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          )
        else if (weather != null) ...[
          _CurrentWeatherRow(snapshot: weather!),
          const SizedBox(height: 12),
          Text(
            'Cảnh báo',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          for (final alert in weather!.alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WeatherAlertTile(alert: alert),
            ),
        ],
      ],
    );
  }
}

class _CurrentWeatherRow extends StatelessWidget {
  final WeatherSnapshot snapshot;

  const _CurrentWeatherRow({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final highLow = snapshot.highC != null && snapshot.lowC != null
        ? 'C:${snapshot.highC}°  T:${snapshot.lowC}°'
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _WeatherGlyph(code: snapshot.weatherCode, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${snapshot.temperatureC.round()}° • ${snapshot.conditionLabel}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.4,
                  ),
                ),
                if (highLow != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    highLow,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Gió ${snapshot.windKmh.round()} km/h • Ẩm ${snapshot.humidityPercent}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherAlertTile extends StatelessWidget {
  final WeatherAlert alert;

  const _WeatherAlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      WeatherAlertSeverity.info => IosDesign.neonCyan,
      WeatherAlertSeverity.warning => const Color(0xFFFFB020),
      WeatherAlertSeverity.critical => IosDesign.warningRed,
    };
    final icon = switch (alert.severity) {
      WeatherAlertSeverity.info => Icons.wb_cloudy_outlined,
      WeatherAlertSeverity.warning => Icons.warning_amber_rounded,
      WeatherAlertSeverity.critical => Icons.thunderstorm_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherGlyph extends StatelessWidget {
  final int code;
  final double size;

  const _WeatherGlyph({required this.code, required this.size});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    if (code == 0) {
      icon = Icons.wb_sunny_rounded;
      color = const Color(0xFFFFD166);
    } else if (code <= 3) {
      icon = Icons.wb_cloudy_rounded;
      color = const Color(0xFF7AD8FF);
    } else if (code <= 67 || (code >= 80 && code <= 82)) {
      icon = Icons.grain_rounded;
      color = const Color(0xFF5AC8FA);
    } else if (code >= 95) {
      icon = Icons.thunderstorm_rounded;
      color = IosDesign.warningRed;
    } else {
      icon = Icons.cloud_rounded;
      color = Colors.white70;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}
