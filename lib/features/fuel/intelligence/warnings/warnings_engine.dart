import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';
import 'package:fuel_tracker_app/features/fuel/intelligence/prediction/fuel_prediction_models.dart';
import 'package:fuel_tracker_app/features/fuel/intelligence/warnings/fuel_warning_models.dart';

class WarningsEngine {
  const WarningsEngine();

  List<FuelWarning> buildWarnings({
    required FuelPredictionState prediction,
    required GasStation? emergencyStation,
  }) {
    final out = <FuelWarning>[];

    final rp = prediction.routePrediction;
    if (rp != null && rp.insufficientFuel) {
      final stationLine = emergencyStation != null
          ? 'Trạm đề xuất: ${emergencyStation.name} (${emergencyStation.distanceKm.toStringAsFixed(1)} km).'
          : 'Nên đổ xăng ngay tại trạm gần nhất.';
      final emptyLine = rp.emptyAfterKm != null
          ? 'Dự trữ nhiên liệu sẽ nguy hiểm sau ~${rp.emptyAfterKm!.toStringAsFixed(0)} km.'
          : null;
      out.add(
        FuelWarning(
          severity: WarningSeverity.critical,
          title: 'Mức dự trữ nhiên liệu nguy hiểm',
          message:
              'Dự kiến cần ~${rp.litersRequired.toStringAsFixed(1)} L cho tuyến này. '
              '${emptyLine ?? ''} '
              '$stationLine',
        ),
      );
    } else if (rp != null && rp.riskLevel == RouteRiskLevel.risky) {
      out.add(
        const FuelWarning(
          severity: WarningSeverity.warning,
          title: 'Rủi ro tuyến đang tăng',
          message:
              'Giao thông và địa hình làm tăng mức tiêu hao. Nên chuẩn bị đổ xăng sớm.',
        ),
      );
    } else if (rp != null && rp.riskLevel == RouteRiskLevel.moderate) {
      out.add(
        const FuelWarning(
          severity: WarningSeverity.info,
          title: 'Tuyến vẫn ổn',
          message:
              'Xu hướng nhiên liệu ổn định — lái êm hơn sẽ giúp dự trữ tốt hơn khi tới nơi.',
        ),
      );
    } else if (prediction.health == FuelHealthStatus.warning) {
      out.add(
        FuelWarning(
          severity: WarningSeverity.warning,
          title: 'Dự trữ nhiên liệu đang cạn',
          message:
              'Quãng đường còn lại ~${prediction.remainingRangeKm.toStringAsFixed(0)} km (≈ ${_formatDuration(prediction.timeToEmpty)}).',
        ),
      );
    }

    return out;
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '0 phút';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '$m phút';
    return '$h giờ $m phút';
  }
}

