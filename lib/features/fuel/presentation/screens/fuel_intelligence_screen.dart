import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/ios_design_tokens.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/fuel/intelligence/driving_behavior/driving_behavior_models.dart';
import 'package:fuel_tracker_app/features/fuel/intelligence/prediction/fuel_prediction_models.dart';
import 'package:fuel_tracker_app/features/fuel/intelligence/warnings/fuel_warning_models.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';
import 'package:fuel_tracker_app/features/location/data/services/location_service.dart';
import 'package:fuel_tracker_app/shared/widgets/ios_style_widgets.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_shell_insets.dart';
import 'package:fuel_tracker_app/features/fuel/presentation/viewmodels/fuel_intelligence_view_model.dart';
import 'package:fuel_tracker_app/features/fuel/presentation/widgets/fuel_consumption_graph.dart';
import 'package:fuel_tracker_app/features/fuel/presentation/widgets/fuel_intelligence_shell.dart';
import 'package:fuel_tracker_app/features/fuel/presentation/widgets/fuel_weather_card.dart';

class FuelIntelligenceScreen extends StatefulWidget {
  const FuelIntelligenceScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => const FuelIntelligenceScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );
  }

  @override
  State<FuelIntelligenceScreen> createState() => _FuelIntelligenceScreenState();
}

class _FuelIntelligenceScreenState extends State<FuelIntelligenceScreen> {
  late FuelIntelligenceViewModel _vm;
  bool _vmReady = false;

  final List<FuelGraphPoint> _graph = <FuelGraphPoint>[];

  @override
  void initState() {
    super.initState();
    // VM created in build (needs Provider values). We'll start in didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vmReady) return;
    final fuel = context.read<FuelService>();
    final loc = context.read<LocationService>();
    _vm = FuelIntelligenceViewModel(fuel: fuel, location: loc)..start();
    _vmReady = true;
  }

  @override
  void dispose() {
    _vm.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shellInsets = IosShellInsets.maybeOf(context);
    final metrics = IosHomeMetrics.of(context);
    final bottomInset = shellInsets?.bottom ?? metrics.shellBottomInset;

    return ChangeNotifierProvider.value(
      value: _vm,
      child: FuelIntelligenceShell(
        title: 'Phân tích nhiên liệu',
        onClose: () => Navigator.pop(context),
        body: Consumer<FuelIntelligenceViewModel>(
          builder: (context, vm, _) {
            if (!vm.isReady) {
              return const FuelIntelligenceContentLoader(
                message: 'Đang phân tích nhiên liệu...',
              );
            }

            if (vm.loadError != null && vm.prediction == null) {
              return FuelIntelligenceEmptyState(
                message: vm.loadError!,
                onRetry: vm.retry,
              );
            }

            final p = vm.prediction;
            if (p == null) {
              return FuelIntelligenceEmptyState(
                message: vm.loadError ??
                    'Chưa có dữ liệu phân tích. Bật GPS và thử lại.',
                onRetry: vm.retry,
              );
            }

            _pushGraphPoint(p);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 8, 20, 28 + bottomInset + 36),
              child: Column(
                children: [
                  if (vm.loadError != null) ...[
                    _InlineErrorBanner(message: vm.loadError!),
                    const SizedBox(height: 12),
                  ],
                  _HeroSection(prediction: p),
                  const SizedBox(height: 14),
                  if (vm.warnings.isNotEmpty) ...[
                    _WarningCard(warning: vm.warnings.first),
                    const SizedBox(height: 14),
                  ],
                  IosGlassCard(child: _LiveAnalyticsCard(prediction: p)),
                  const SizedBox(height: 14),
                  const IosGlassCard(child: _FuelDemoTestCard()),
                  if (p.hudInsights.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    IosGlassCard(
                      child: _PredictiveHudCard(
                        insights: p.hudInsights,
                        risk: p.routeRiskLevel,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  IosGlassCard(
                    child: _NearbyStationsCard(
                      prediction: p,
                      stationsCount: vm.nearbyStations.length,
                      nearestKm: vm.rankedStations.isNotEmpty
                          ? vm.rankedStations.first.station.distanceKm
                          : (vm.nearbyStations.isNotEmpty
                              ? vm.nearbyStations.first.distanceKm
                              : null),
                      onRefresh: vm.refreshStations,
                    ),
                  ),
                  const SizedBox(height: 14),
                  IosGlassCard(
                    padding: const EdgeInsets.all(12),
                    child: FuelWeatherCard(
                      weather: vm.weather,
                      loading: vm.weatherLoading,
                      onRefresh: () => vm.refreshWeather(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  IosGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mức tiêu hao nhiên liệu (thời gian thực)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FuelConsumptionGraph(
                          points: _graph,
                          minLPer100Km: 2,
                          maxLPer100Km: 22,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _pushGraphPoint(FuelPredictionState p) {
    _graph.add(FuelGraphPoint(lPer100Km: p.currentLPer100Km));
    if (_graph.length > 50) {
      _graph.removeAt(0);
    }
  }

}

class _InlineErrorBanner extends StatelessWidget {
  final String message;

  const _InlineErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: IosDesign.warningRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IosDesign.warningRed.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: IosDesign.warningRed.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final FuelPredictionState prediction;

  const _HeroSection({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final low = prediction.health != FuelHealthStatus.ok;
    final tension = ((35 - prediction.fuelPercent) / 35).clamp(0.0, 1.0);
    final accent = low ? IosDesign.warningRed : IosDesign.neonCyan;

    return IosGlassCard(
      glowWarning: prediction.health == FuelHealthStatus.critical,
      borderColor: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _VerticalFuelGauge(
            percent: prediction.fuelPercent,
            accent: accent,
            pulse: low,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _HealthChip(prediction: prediction),
                ),
                const SizedBox(height: 6),
                _AnimatedMetricText(
                  value: prediction.fuelPercent,
                  builder: (v) => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        v.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          height: 0.95,
                          color: accent,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 3, bottom: 7),
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: accent.withValues(alpha: 0.82),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _AnimatedMetricText(
                  value: prediction.remainingRangeKm,
                  builder: (v) => Text(
                    'Còn đi được ~${v.toStringAsFixed(0)} km',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '≈ ${_fmtDuration(prediction.timeToEmpty)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(
          onPlay: (c) => low ? c.repeat(reverse: true) : null,
        )
        .shimmer(
          duration: Duration(milliseconds: (1800 - (500 * tension)).round()),
          color: accent.withValues(alpha: low ? (0.12 + 0.12 * tension) : 0),
          angle: 0.2,
        );
  }

  String _fmtDuration(Duration d) {
    if (d == Duration.zero) return '0 phút';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '$m phút';
    return '$h giờ $m phút';
  }
}

/// Thanh nhiên liệu dọc — kiểu bình xăng với gradient + glow.
class _VerticalFuelGauge extends StatelessWidget {
  final double percent;
  final Color accent;
  final bool pulse;

  const _VerticalFuelGauge({
    required this.percent,
    required this.accent,
    this.pulse = false,
  });

  static const _barH = 132.0;
  static const _barW = 22.0;

  @override
  Widget build(BuildContext context) {
    final fill = (percent / 100).clamp(0.0, 1.0);

    Widget gauge(double animatedFill) {
      return SizedBox(
        width: 44,
        height: _barH + 28,
        child: Column(
          children: [
            Text(
              'F',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.38),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (pulse)
                    Container(
                      width: _barW + 14,
                      height: _barH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 20,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                  Container(
                    width: _barW,
                    height: _barH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: Colors.white.withValues(alpha: 0.07),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Vạch mốc 25 / 50 / 75%
                          ...[0.25, 0.5, 0.75].map(
                            (t) => Positioned(
                              bottom: _barH * t,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 560),
                            curve: Curves.easeOutCubic,
                            width: _barW,
                            height: _barH * animatedFill,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  accent,
                                  accent.withValues(alpha: 0.72),
                                  accent.withValues(alpha: 0.38),
                                ],
                                stops: const [0.0, 0.55, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                          ),
                          // Highlight trên mặt chất lỏng
                          if (animatedFill > 0.08)
                            Positioned(
                              bottom: _barH * animatedFill - 6,
                              left: 4,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'E',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.38),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fill),
      duration: const Duration(milliseconds: 680),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => gauge(v),
    );
  }
}

class _HealthChip extends StatelessWidget {
  final FuelPredictionState prediction;

  const _HealthChip({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final style = switch (prediction.drivingStyle) {
      DrivingStyle.eco => 'Tiết kiệm',
      DrivingStyle.normal => 'Thường',
      DrivingStyle.aggressive => 'Mạnh',
    };
    final health = switch (prediction.health) {
      FuelHealthStatus.ok => 'Ổn',
      FuelHealthStatus.warning => 'Cảnh báo',
      FuelHealthStatus.critical => 'Nguy',
    };
    final color = prediction.health == FuelHealthStatus.critical
        ? IosDesign.warningRed
        : (prediction.health == FuelHealthStatus.warning
            ? const Color(0xFFFFB020)
            : IosDesign.neonCyan);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          '$style • $health • ${_confidenceLabel(prediction.confidence)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  String _confidenceLabel(PredictionConfidence c) => switch (c) {
        PredictionConfidence.low => 'Thấp',
        PredictionConfidence.medium => 'TB',
        PredictionConfidence.high => 'Cao',
      };
}

class _AnimatedMetricText extends StatefulWidget {
  final double value;
  final Widget Function(double animatedValue) builder;

  const _AnimatedMetricText({
    required this.value,
    required this.builder,
  });

  @override
  State<_AnimatedMetricText> createState() => _AnimatedMetricTextState();
}

class _AnimatedMetricTextState extends State<_AnimatedMetricText> {
  late double _previous = widget.value;

  @override
  void didUpdateWidget(covariant _AnimatedMetricText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previous = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _previous, end: widget.value),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => widget.builder(v),
    );
  }
}

class _LiveAnalyticsCard extends StatelessWidget {
  final FuelPredictionState prediction;

  const _LiveAnalyticsCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phân tích lái xe trực tiếp',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: IosStatChip(
                icon: Icons.speed_rounded,
                label: 'Hiện tại',
                value: '${prediction.currentLPer100Km.toStringAsFixed(1)} L/100',
                accent: VehicleUi.accentBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: IosStatChip(
                icon: Icons.query_stats_rounded,
                label: 'Trung bình',
                value: '${prediction.avgLPer100Km.toStringAsFixed(1)} L/100',
                accent: IosDesign.neonCyan,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FuelDemoTestCard extends StatelessWidget {
  const _FuelDemoTestCard();

  @override
  Widget build(BuildContext context) {
    final fuel = context.watch<FuelService>();
    final max = fuel.tankCapacityLiters;

    Widget preset({
      required String label,
      required double liters,
      required Color color,
    }) {
      return Expanded(
        child: FilledButton.tonal(
          onPressed: () => fuel.updateCurrentFuel(liters.clamp(0, max)),
          style: FilledButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.14),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bảng test xăng (demo)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Xe demo: ${fuel.vehicleName}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Giả lập mức xăng để test UI/cảnh báo khi chưa có cảm biến xe.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 12,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hiện tại: ${fuel.currentFuelLiters.toStringAsFixed(1)} L / ${fuel.tankCapacityLiters.toStringAsFixed(0)} L (${fuel.fuelPercent.toStringAsFixed(0)}%)',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Reserve: ${fuel.criticalReserveLiters.toStringAsFixed(1)}L • Tầm an toàn ~${fuel.safeRemainingDistanceKm.toStringAsFixed(0)} km',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Slider(
          value: fuel.currentFuelLiters.clamp(0.0, max),
          min: 0,
          max: max,
          activeColor: fuel.isLowFuel ? IosDesign.warningRed : VehicleUi.accentBlue,
          onChanged: fuel.updateCurrentFuel,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            preset(
              label: '10% (cảnh báo)',
              liters: max * 0.10,
              color: IosDesign.warningRed,
            ),
            const SizedBox(width: 8),
            preset(
              label: '50% (trung bình)',
              liters: max * 0.50,
              color: const Color(0xFFFFB020),
            ),
            const SizedBox(width: 8),
            preset(
              label: '90% (an toàn)',
              liters: max * 0.90,
              color: IosDesign.neonCyan,
            ),
          ],
        ),
      ],
    );
  }
}

class _NearbyStationsCard extends StatelessWidget {
  final FuelPredictionState prediction;
  final int stationsCount;
  final double? nearestKm;
  final Future<void> Function() onRefresh;

  const _NearbyStationsCard({
    required this.prediction,
    required this.stationsCount,
    required this.nearestKm,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = prediction.health != FuelHealthStatus.ok;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Trạm xăng lân cận',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
            IconButton(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh_rounded),
              color: Colors.white70,
              tooltip: 'Làm mới',
            ),
          ],
        ),
        Text(
          nearestKm != null
              ? '$stationsCount trạm • gần nhất ${nearestKm!.toStringAsFixed(1)}km'
              : 'Đang tìm trạm xăng gần nhất...',
          style: TextStyle(
            color: highlight
                ? const Color(0xFFFFB020)
                : Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  final FuelWarning warning;

  const _WarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    final color = switch (warning.severity) {
      WarningSeverity.info => IosDesign.neonCyan,
      WarningSeverity.warning => const Color(0xFFFFB020),
      WarningSeverity.critical => IosDesign.warningRed,
    };
    final pulseMs = switch (warning.severity) {
      WarningSeverity.info => 2300,
      WarningSeverity.warning => 1700,
      WarningSeverity.critical => 1150,
    };
    return IosGlassCard(
      glowWarning: warning.severity == WarningSeverity.critical,
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            warning.title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            warning.message,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
          ),
        ],
      ),
    )
        .animate(
          onPlay: (c) => warning.severity == WarningSeverity.info
              ? null
              : c.repeat(reverse: true),
        )
        .tint(
          color: color.withValues(
            alpha: warning.severity == WarningSeverity.critical ? 0.08 : 0.045,
          ),
          duration: Duration(milliseconds: pulseMs),
          curve: Curves.easeInOut,
        );
  }
}

class _PredictiveHudCard extends StatelessWidget {
  final List<String> insights;
  final RouteRiskLevel? risk;

  const _PredictiveHudCard({
    required this.insights,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (risk) {
      RouteRiskLevel.safe => ('An toàn', IosDesign.neonCyan),
      RouteRiskLevel.moderate => ('Trung bình', const Color(0xFFFFD166)),
      RouteRiskLevel.risky => ('Cao', const Color(0xFFFF9F1C)),
      RouteRiskLevel.critical => ('Nguy cấp', IosDesign.warningRed),
      null => ('Chưa rõ', Colors.white70),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Gợi ý dự báo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Tuyến: $label',
                style: TextStyle(
                  color: color.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final s in insights)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: VehicleUi.accentBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

