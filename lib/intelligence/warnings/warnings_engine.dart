import '../../models/gas_station.dart';
import '../prediction/fuel_prediction_models.dart';
import 'fuel_warning_models.dart';

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
          ? 'Recommended station is ${emergencyStation.name} at ${emergencyStation.distanceKm.toStringAsFixed(1)}km.'
          : 'Recommended refuel now at the nearest station.';
      final emptyLine = rp.emptyAfterKm != null
          ? 'Fuel reserve becomes critical in ~${rp.emptyAfterKm!.toStringAsFixed(0)}km.'
          : null;
      out.add(
        FuelWarning(
          severity: WarningSeverity.critical,
          title: 'Fuel reserve is critical',
          message:
              'Projected demand is ~${rp.litersRequired.toStringAsFixed(1)}L for this route. '
              '${emptyLine ?? ''} '
              '$stationLine',
        ),
      );
    } else if (rp != null && rp.riskLevel == RouteRiskLevel.risky) {
      out.add(
        FuelWarning(
          severity: WarningSeverity.warning,
          title: 'Route risk is rising',
          message:
              'Traffic and terrain are increasing consumption. Recommended refuel window is approaching.',
        ),
      );
    } else if (rp != null && rp.riskLevel == RouteRiskLevel.moderate) {
      out.add(
        FuelWarning(
          severity: WarningSeverity.info,
          title: 'Route remains manageable',
          message:
              'Fuel trend is stable, but adaptive driving now will improve reserve at arrival.',
        ),
      );
    } else if (prediction.health == FuelHealthStatus.warning) {
      out.add(
        FuelWarning(
          severity: WarningSeverity.warning,
          title: 'Fuel reserve is tightening',
          message:
              'Remaining range is ~${prediction.remainingRangeKm.toStringAsFixed(0)}km (≈ ${_formatDuration(prediction.timeToEmpty)}).',
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
    return '${h}h ${m}m';
  }
}

