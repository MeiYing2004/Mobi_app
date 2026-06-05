/// Thời tiết hiện tại + cảnh báo lái xe (Open-Meteo).
class WeatherSnapshot {
  final String locationLabel;
  final double temperatureC;
  final int? highC;
  final int? lowC;
  final String conditionLabel;
  final int weatherCode;
  final double windKmh;
  final int humidityPercent;
  final List<WeatherAlert> alerts;
  final DateTime fetchedAt;

  const WeatherSnapshot({
    required this.locationLabel,
    required this.temperatureC,
    this.highC,
    this.lowC,
    required this.conditionLabel,
    required this.weatherCode,
    required this.windKmh,
    required this.humidityPercent,
    this.alerts = const [],
    required this.fetchedAt,
  });
}

enum WeatherAlertSeverity { info, warning, critical }

class WeatherAlert {
  final String title;
  final String message;
  final WeatherAlertSeverity severity;

  const WeatherAlert({
    required this.title,
    required this.message,
    this.severity = WeatherAlertSeverity.info,
  });
}
