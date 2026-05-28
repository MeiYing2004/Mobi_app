import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/ios_design_tokens.dart';
import '../../../core/vehicle_ui_tokens.dart';
import '../../../intelligence/driving_behavior/driving_behavior_models.dart';
import '../../../intelligence/prediction/fuel_prediction_models.dart';
import '../../../intelligence/warnings/fuel_warning_models.dart';
import '../../../models/gas_station.dart';
import '../../../models/place_model.dart';
import '../../../services/fuel_service.dart';
import '../../../services/location_service.dart';
import '../../../services/search_service.dart';
import '../../../widgets/ios_style_widgets.dart';
import '../../fuel_intelligence/viewmodels/fuel_intelligence_view_model.dart';
import '../widgets/fuel_consumption_graph.dart';
import '../widgets/fuel_intelligence_mini_map.dart';

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
  final SearchService _searchService = SearchService();

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
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(gradient: IosDesign.ambientGradient),
          child: SafeArea(
            child: Column(
              children: [
                _Header(
                  onClose: () => Navigator.pop(context, _vm.destination),
                ),
                Expanded(
                  child: Consumer<FuelIntelligenceViewModel>(
                    builder: (context, vm, _) {
                      final p = vm.prediction;
                      if (p == null) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: VehicleUi.accentBlue,
                          ),
                        );
                      }

                      _pushGraphPoint(p);

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        child: Column(
                          children: [
                            _HeroSection(prediction: p),
                            const SizedBox(height: 14),
                            if (vm.warnings.isNotEmpty) ...[
                              _WarningCard(warning: vm.warnings.first),
                              const SizedBox(height: 14),
                            ],
                            IosGlassCard(child: _LiveAnalyticsCard(prediction: p)),
                            const SizedBox(height: 14),
                            const IosGlassCard(child: _FuelDemoTestCard()),
                            const SizedBox(height: 14),
                            IosGlassCard(
                              child: _RouteFuelPredictionCard(
                                prediction: p,
                                destination: vm.destination,
                                destinationHistory: vm.destinationHistory,
                                emergencyStation: vm.emergencyStation,
                                autoRefuelStatusMessage:
                                    vm.autoRefuelStatusMessage,
                                autoRefuelRerouteActive:
                                    vm.autoRefuelRerouteActive,
                                originalDestination:
                                    vm.originalDestinationBeforeRefuel,
                                onPickDestination: () => _openDestinationPicker(vm),
                                onClear: () => vm.setDestination(null),
                                onSelectHistory: vm.setDestination,
                                onClearHistory: vm.clearDestinationHistory,
                              ),
                            ),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bản đồ trực tiếp',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      color: Colors.white.withValues(alpha: 0.92),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  FuelIntelligenceMiniMap(
                                    userLocation: vm.location.currentPosition != null
                                        ? LatLng(
                                            vm.location.currentPosition!.latitude,
                                            vm.location.currentPosition!.longitude,
                                          )
                                        : null,
                                    routePoints: vm.routePoints,
                                    emptyPoint: vm.emptyPoint,
                                    stations: vm.nearbyStations,
                                    emergencyStation: vm.emergencyStation,
                                    riskLevel: p.routeRiskLevel,
                                    fuelPercent: p.fuelPercent,
                                  ),
                                ],
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
                                    arrivalFuelPercent:
                                        p.routePrediction?.arrivalFuelPercent,
                                    emptyAfterKm: p.routePrediction?.emptyAfterKm,
                                    routeDistanceKm:
                                        p.routePrediction?.routeDistanceKm,
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
              ],
            ),
          ),
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

  Future<void> _openDestinationPicker(FuelIntelligenceViewModel vm) async {
    final pos = vm.location.currentPosition;
    final bias = pos != null ? LatLng(pos.latitude, pos.longitude) : null;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DestinationPickerSheet(
        searchService: _searchService,
        biasLocation: bias,
        onPick: (details) {
          Navigator.pop(ctx);
          vm.setDestination(details);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            color: Colors.white70,
          ),
          const Expanded(
            child: Text(
              'Phân tích nhiên liệu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 48),
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
    final cardWidth = MediaQuery.sizeOf(context).width - 40;

    return IosGlassCard(
      glowWarning: prediction.health == FuelHealthStatus.critical,
      borderColor: accent,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedMetricText(
                      value: prediction.fuelPercent,
                      builder: (v) => Text(
                        '${v.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.6,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _AnimatedMetricText(
                      value: prediction.remainingRangeKm,
                      builder: (v) => Text(
                        'Còn đi được ~${v.toStringAsFixed(0)} km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 118,
                  maxWidth: (cardWidth * 0.48).clamp(132.0, 190.0),
                ),
                child: _HealthChip(prediction: prediction),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (prediction.fuelPercent / 100).clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: IosDesign.titanGrayLight,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
            borderRadius: BorderRadius.circular(999),
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
    return '${h} giờ ${m} phút';
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

class _RouteFuelPredictionCard extends StatelessWidget {
  final FuelPredictionState prediction;
  final PlaceDetails? destination;
  final List<PlaceDetails> destinationHistory;
  final GasStation? emergencyStation;
  final String? autoRefuelStatusMessage;
  final bool autoRefuelRerouteActive;
  final PlaceDetails? originalDestination;
  final VoidCallback onPickDestination;
  final VoidCallback onClear;
  final void Function(PlaceDetails? details) onSelectHistory;
  final VoidCallback onClearHistory;

  const _RouteFuelPredictionCard({
    required this.prediction,
    required this.destination,
    required this.destinationHistory,
    required this.emergencyStation,
    required this.autoRefuelStatusMessage,
    required this.autoRefuelRerouteActive,
    required this.originalDestination,
    required this.onPickDestination,
    required this.onClear,
    required this.onSelectHistory,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final rp = prediction.routePrediction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Dự đoán nhiên liệu theo tuyến',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
            TextButton(
              onPressed: onPickDestination,
              child: const Text('Chọn điểm đến'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (rp == null)
          Text(
            'Chọn điểm đến từ màn bản đồ (Search) để dự đoán theo tuyến.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          )
        else ...[
          Text(
            'Cần ~${rp.litersRequired.toStringAsFixed(1)}L • Dự kiến đến nơi còn ${rp.arrivalFuelPercent.toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Rủi ro: ${_riskLabel(rp.riskLevel)} • Giao thông x${rp.trafficFactor.toStringAsFixed(2)}',
            style: TextStyle(
              color: _riskColor(rp.riskLevel).withValues(alpha: 0.95),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          if (rp.insufficientFuel)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠ Dự đoán sẽ cạn nhiên liệu${rp.emptyAfterKm != null ? ' sau ~${rp.emptyAfterKm!.toStringAsFixed(0)} km' : ''}',
                  style: const TextStyle(
                    color: IosDesign.warningRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (emergencyStation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Điểm dừng đề xuất: ${emergencyStation!.name} (${emergencyStation!.distanceKm.toStringAsFixed(1)} km)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFFFB020).withValues(alpha: 0.95),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
        ],
        if (autoRefuelStatusMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            autoRefuelStatusMessage!,
            style: TextStyle(
              color: autoRefuelRerouteActive
                  ? const Color(0xFFFFB020)
                  : IosDesign.neonCyan,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1.2,
            ),
          ),
          if (autoRefuelRerouteActive && originalDestination != null) ...[
            const SizedBox(height: 4),
            Text(
              'Dich goc: ${originalDestination!.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
        if (destination != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  destination!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Xóa'),
              ),
            ],
          ),
        ],
        if (destinationHistory.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch sử điểm đến',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClearHistory,
                child: const Text('Xóa lịch sử'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: destinationHistory
                .map(
                  (h) => ActionChip(
                    onPressed: () => onSelectHistory(h),
                    label: SizedBox(
                      width: 120,
                      child: Text(
                        h.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    avatar: const Icon(Icons.history_rounded, size: 16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }

  String _riskLabel(RouteRiskLevel risk) => switch (risk) {
        RouteRiskLevel.safe => 'An toàn',
        RouteRiskLevel.moderate => 'Trung bình',
        RouteRiskLevel.risky => 'Cao',
        RouteRiskLevel.critical => 'Nguy cấp',
      };

  Color _riskColor(RouteRiskLevel risk) => switch (risk) {
        RouteRiskLevel.safe => IosDesign.neonCyan,
        RouteRiskLevel.moderate => const Color(0xFFFFD166),
        RouteRiskLevel.risky => const Color(0xFFFF9F1C),
        RouteRiskLevel.critical => IosDesign.warningRed,
      };
}

class _DestinationPickerSheet extends StatefulWidget {
  final SearchService searchService;
  final LatLng? biasLocation;
  final void Function(PlaceDetails details) onPick;

  const _DestinationPickerSheet({
    required this.searchService,
    required this.biasLocation,
    required this.onPick,
  });

  @override
  State<_DestinationPickerSheet> createState() => _DestinationPickerSheetState();
}

class _DestinationPickerSheetState extends State<_DestinationPickerSheet> {
  final TextEditingController _ctrl = TextEditingController();
  List<PlaceSuggestion> _items = const [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() => _items = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await widget.searchService.autocomplete(
        input: query,
        biasLocation: widget.biasLocation,
      );
      if (!mounted) return;
      setState(() => _items = res);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + safeBottom),
        child: IosGlassCard(
          borderRadius: 22,
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chọn điểm đến',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ctrl,
                onChanged: (v) => _search(v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nhập địa điểm (vd: HCM, Đà Lạt...)',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                  prefixIcon: const Icon(Icons.search_rounded, color: IosDesign.neonCyan),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: VehicleUi.accentBlue.withValues(alpha: 0.7)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: VehicleUi.accentBlue,
                ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, i) {
                    final s = _items[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        s.primaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        s.secondaryText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      ),
                      onTap: () => widget.onPick(
                        widget.searchService.detailsFromSuggestion(s),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  itemCount: _items.length,
                ),
              ),
            ],
          ),
        ),
      ),
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
              ? '${stationsCount} trạm • gần nhất ${nearestKm!.toStringAsFixed(1)}km'
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

