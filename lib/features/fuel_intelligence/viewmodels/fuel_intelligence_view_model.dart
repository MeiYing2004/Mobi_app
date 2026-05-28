import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../intelligence/driving_behavior/driving_behavior_analyzer.dart';
import '../../../intelligence/driving_behavior/driving_behavior_models.dart';
import '../../../intelligence/prediction/fuel_prediction_engine.dart';
import '../../../intelligence/prediction/fuel_prediction_models.dart';
import '../../../intelligence/simulation/route_fuel_simulation_engine.dart';
import '../../../intelligence/telemetry/telemetry_sample.dart';
import '../../../intelligence/warnings/fuel_warning_models.dart';
import '../../../intelligence/warnings/warnings_engine.dart';
import '../../../models/gas_station.dart';
import '../../../models/place_model.dart';
import '../../../services/directions_service.dart';
import '../../../services/elevation_service.dart';
import '../../../services/fuel_service.dart';
import '../../../services/fuel_station_service.dart';
import '../../../services/gas_station_service.dart';
import '../../../services/graphhopper_directions_service.dart';
import '../../../services/location_service.dart';

class FuelIntelligenceViewModel extends ChangeNotifier {
  final FuelService fuel;
  final LocationService location;

  final DrivingBehaviorAnalyzer _behaviorAnalyzer = DrivingBehaviorAnalyzer();
  final FuelPredictionEngine _predictionEngine = FuelPredictionEngine();
  final RouteFuelSimulationEngine _simulationEngine =
      const RouteFuelSimulationEngine();
  final ElevationService _elevationService = const ElevationService();
  final WarningsEngine _warningsEngine = const WarningsEngine();
  final FuelStationService _stations = FuelStationService(nearby: GasStationService());

  final DirectionsService _osrm = const DirectionsService();
  final GraphHopperDirectionsService _graphhopper =
      const GraphHopperDirectionsService();

  Timer? _debounce;
  int _workSeq = 0;
  bool _started = false;
  FuelPredictionState? _prediction;
  List<FuelWarning> _warnings = const [];
  List<FuelWarning> _stableWarnings = const [];
  DateTime? _lastWarningsUpdatedAt;
  List<GasStation> _nearbyStations = const [];
  RouteFuelPrediction? _routePrediction;
  RouteFuelSimulationResult? _routeSimulation;
  List<LatLng> _routePoints = const [];
  LatLng? _emptyPoint;
  GasStation? _emergencyStation;
  List<RankedFuelStation> _rankedStations = const [];
  PlaceDetails? _originalDestinationBeforeRefuel;
  bool _autoRefuelRerouteActive = false;
  String? _autoRefuelStatusMessage;
  DateTime? _lastAutoRefuelRerouteAt;
  String? _activeAutoRefuelStationId;
  double _lastObservedFuelLiters = 0.0;
  DrivingBehaviorMetrics? _behaviorMetrics;
  double _trafficFactor = 1.0;
  double _trafficFactorSmoothed = 1.0;
  double _arrivalFuelPercentSmoothed = 0.0;
  double _riskScoreSmoothed = 0.0;
  RouteRiskLevel _riskLevelStable = RouteRiskLevel.safe;
  int _riskEscalationHits = 0;
  int _riskDeescalationHits = 0;

  // Route + elevation cache.
  LatLng? _lastRoutedOrigin;
  DateTime? _lastRoutedAt;
  double _routeDistanceKm = 0.0;
  int _routeDurationSeconds = 0;
  String? _elevationKey;
  List<double>? _routeElevations;
  bool _routeLoading = false;
  bool _stationsLoading = false;

  FuelPredictionState? get prediction => _prediction;
  List<FuelWarning> get warnings => _warnings;
  List<GasStation> get nearbyStations => _nearbyStations;
  RouteFuelPrediction? get routePrediction => _routePrediction;
  RouteFuelSimulationResult? get routeSimulation => _routeSimulation;
  List<LatLng> get routePoints => _routePoints;
  LatLng? get emptyPoint => _emptyPoint;
  GasStation? get emergencyStation => _emergencyStation;
  List<RankedFuelStation> get rankedStations => _rankedStations;
  DrivingBehaviorMetrics? get behaviorMetrics => _behaviorMetrics;
  double get trafficFactor => _trafficFactor;

  PlaceDetails? _destination;
  PlaceDetails? get destination => _destination;
  bool get autoRefuelRerouteActive => _autoRefuelRerouteActive;
  String? get autoRefuelStatusMessage => _autoRefuelStatusMessage;
  PlaceDetails? get originalDestinationBeforeRefuel =>
      _originalDestinationBeforeRefuel;
  List<PlaceDetails> _destinationHistory = const [];
  List<PlaceDetails> get destinationHistory => List.unmodifiable(_destinationHistory);

  // Behavior analyzer wants delta distance to compute stop-per-km.
  double _lastTotalDistanceKm = 0.0;

  FuelIntelligenceViewModel({
    required this.fuel,
    required this.location,
  }) {
    _behaviorAnalyzer.reset();
    _predictionEngine.reset();
    _restoreBackgroundSnapshot();
    _lastObservedFuelLiters = fuel.currentFuelLiters;
  }

  void start() {
    if (_started) return;
    _started = true;
    _lastTotalDistanceKm = location.totalDistanceKm;
    fuel.addListener(_onSignal);
    location.addListener(_onSignal);
    _scheduleStep(immediate: true);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    fuel.removeListener(_onSignal);
    location.removeListener(_onSignal);
    _debounce?.cancel();
    _debounce = null;
  }

  void setDestination(PlaceDetails? dest) {
    _clearAutoRefuelState();
    _setDestinationInternal(dest);
  }

  void _setDestinationInternal(PlaceDetails? dest) {
    if (dest != null) {
      _pushDestinationHistory(dest);
    }
    _destination = dest;
    _routePrediction = null;
    _routeSimulation = null;
    _routePoints = const [];
    _emptyPoint = null;
    _routeElevations = null;
    _lastRoutedOrigin = null;
    _lastRoutedAt = null;
    _routeDistanceKm = 0.0;
    _routeDurationSeconds = 0;
    _elevationKey = null;
    _saveBackgroundSnapshot();
    notifyListeners();
    _scheduleStep(immediate: true, forceStationsRefresh: true);
  }

  void clearDestinationHistory() {
    _destinationHistory = const [];
    _saveBackgroundSnapshot();
    notifyListeners();
  }

  Future<void> refreshStations() async {
    await _loadNearbyStations(force: true);
    _scheduleStep(immediate: true);
  }

  Future<void> _step({bool forceStationsRefresh = false}) async {
    if (!_started) return;
    final seq = ++_workSeq;

    final speedKmh = location.speedKmh;
    final totalKm = location.totalDistanceKm;
    final deltaKm = (totalKm - _lastTotalDistanceKm).clamp(0.0, 1.2);
    _lastTotalDistanceKm = totalKm;
    final sample = TelemetrySample(
      timestamp: DateTime.now(),
      speedKmh: speedKmh,
      bearingDeg: location.bearing,
    );
    _behaviorAnalyzer.ingest(sample, deltaDistanceKm: deltaKm);
    final behavior = _behaviorAnalyzer.snapshot();
    _behaviorMetrics = behavior;
    final trafficRaw = _estimateTrafficFactor(
      behavior: behavior,
      speedKmh: speedKmh,
    );
    _trafficFactorSmoothed = _smoothValue(
      previous: _trafficFactorSmoothed,
      target: trafficRaw,
      alpha: 0.23,
    );
    _trafficFactor = _trafficFactorSmoothed;

    if ((forceStationsRefresh || _nearbyStations.isEmpty) && !_stationsLoading) {
      await _loadNearbyStations(force: forceStationsRefresh);
    }

    await _ensureRoute(behavior: behavior, seq: seq);
    _routePrediction = _computeRoutePredictionFromSimulation(behavior: behavior);

    final isIdling = (speedKmh ?? 0) < 2;
    final predictionState = _predictionEngine.tick(
      fuel: fuel,
      behavior: behavior,
      speedKmh: speedKmh,
      routePrediction: _routePrediction,
      isIdling: isIdling,
      elevationFactor: _elevationFactorForPrediction(),
      trafficFactor: _trafficFactor,
      hudInsights: _buildHudInsights(
        behavior: behavior,
        prediction: _routePrediction,
      ),
      confidenceOverride: _buildPredictionConfidence(
        behavior: behavior,
        trafficFactor: _trafficFactor,
      ),
    );
    _prediction = predictionState;
    _handleAutoRefuelReroute(predictionState);

    _rankedStations = _stations.rankStationsForRoute(
      nearby: _nearbyStations,
      remainingRangeKm: predictionState.remainingRangeKm,
      routePoints: _routePoints,
      routeDistanceKm: _routeDistanceKm,
      trafficFactor: _trafficFactor,
    );
    _emergencyStation = _stations.recommendEmergencyStation(
      nearby: _nearbyStations,
      remainingRangeKm: predictionState.remainingRangeKm,
      routePoints: _routePoints,
      routeDistanceKm: _routeDistanceKm,
      trafficFactor: _trafficFactor,
    );
    _emergencyStation = _emergencyStation ?? (_rankedStations.isNotEmpty ? _rankedStations.first.station : null);
    final rawWarnings = _warningsEngine.buildWarnings(
      prediction: predictionState,
      emergencyStation: _emergencyStation,
    );
    _warnings = _stabilizeWarnings(rawWarnings);

    _saveBackgroundSnapshot();
    notifyListeners();
  }

  void _handleAutoRefuelReroute(FuelPredictionState predictionState) {
    final now = DateTime.now();
    final deltaFuelLiters = fuel.currentFuelLiters - _lastObservedFuelLiters;
    _lastObservedFuelLiters = fuel.currentFuelLiters;
    final route = _routePrediction;
    final destination = _destination;

    if (_autoRefuelRerouteActive && destination != null) {
      final distToStopKm = _distanceFromUserTo(destination.location);
      final arrivedAtStop = distToStopKm != null && distToStopKm <= 0.22;
      final remainingRangeKm = predictionState.remainingRangeKm;
      if (arrivedAtStop) {
        _autoRefuelStatusMessage =
            'Da toi diem dung tiep nhien lieu. Neu chua do them, voi muc hien tai ban chi di them ~${remainingRangeKm.toStringAsFixed(0)} km truoc khi can muc du phong.';
      } else {
        _autoRefuelStatusMessage =
            'Dang huong den cay xang de tiep nhien lieu. Voi muc hien tai ban chi di them ~${remainingRangeKm.toStringAsFixed(0)} km neu khong do them.';
      }
    }

    if (_autoRefuelRerouteActive &&
        deltaFuelLiters >= 1.2 &&
        _originalDestinationBeforeRefuel != null) {
      final resume = _originalDestinationBeforeRefuel!;
      _clearAutoRefuelState(keepMessage: true);
      _autoRefuelStatusMessage =
          'Da tiep nhien lieu. Tiep tuc hanh trinh den ${resume.name}.';
      _setDestinationInternal(resume);
      return;
    }

    if (route?.insufficientFuel != true || _emergencyStation == null) return;
    final cooldownReady = _lastAutoRefuelRerouteAt == null ||
        now.difference(_lastAutoRefuelRerouteAt!) >= const Duration(seconds: 45);
    if (!cooldownReady) return;

    final station = _emergencyStation!;
    final stationDest = _placeFromGasStation(station);
    final alreadyHeadingToStation = _destination?.placeId == stationDest.placeId;
    if (_autoRefuelRerouteActive && alreadyHeadingToStation) return;

    // If route context changed and AI picked a better station, switch to it.
    final aiPickedDifferentStation = _autoRefuelRerouteActive &&
        _activeAutoRefuelStationId != null &&
        _activeAutoRefuelStationId != station.id;
    if (aiPickedDifferentStation) {
      _activeAutoRefuelStationId = station.id;
      _lastAutoRefuelRerouteAt = now;
      _autoRefuelStatusMessage =
          'Tuyen da thay doi. Da cap nhat cay xang phu hop hon: ${station.name}.';
      _setDestinationInternal(stationDest);
      return;
    }

    if (!_autoRefuelRerouteActive) {
      _originalDestinationBeforeRefuel = _destination;
    }
    _autoRefuelRerouteActive = true;
    _activeAutoRefuelStationId = station.id;
    _lastAutoRefuelRerouteAt = now;
    _autoRefuelStatusMessage =
        'Khong du xang den dich. Da tu chuyen huong den cay xang gan nhat: ${station.name}.';
    _setDestinationInternal(stationDest);
  }

  double? _distanceFromUserTo(LatLng target) {
    final pos = location.currentPosition;
    if (pos == null) return null;
    return const Distance().as(
      LengthUnit.Kilometer,
      LatLng(pos.latitude, pos.longitude),
      target,
    );
  }

  PlaceDetails _placeFromGasStation(GasStation station) {
    return PlaceDetails(
      placeId: 'auto_station:${station.id}',
      name: station.name,
      formattedAddress: station.address.isNotEmpty
          ? station.address
          : 'Cay xang gan nhat',
      location: station.location,
    );
  }

  void _clearAutoRefuelState({bool keepMessage = false}) {
    _originalDestinationBeforeRefuel = null;
    _autoRefuelRerouteActive = false;
    _lastAutoRefuelRerouteAt = null;
    _activeAutoRefuelStationId = null;
    if (!keepMessage) {
      _autoRefuelStatusMessage = null;
    }
  }

  void _onSignal() {
    _scheduleStep();
  }

  void _scheduleStep({bool immediate = false, bool forceStationsRefresh = false}) {
    if (!_started) return;

    _debounce?.cancel();
    if (immediate) {
      // ignore: discarded_futures
      _step(forceStationsRefresh: forceStationsRefresh);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 220), () {
      // ignore: discarded_futures
      _step(forceStationsRefresh: forceStationsRefresh);
    });
  }

  Future<void> _loadNearbyStations({required bool force}) async {
    _stationsLoading = true;
    final pos = location.currentPosition;
    final origin = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(21.0285, 105.8542);
    try {
      final aroundUser = await _stations.nearbyStations(
        origin: origin,
        radiusKm: 5,
        limit: 15,
        forceRefresh: force,
      );
      final merged = <String, GasStation>{
        for (final s in aroundUser) s.id: _withDistanceFromOrigin(s, origin),
      };

      final dest = _destination;
      if (dest != null) {
        final aroundDestination = await _stations.nearbyStations(
          origin: dest.location,
          radiusKm: 4.5,
          limit: 15,
          forceRefresh: force,
        );
        for (final s in aroundDestination) {
          merged.putIfAbsent(s.id, () => _withDistanceFromOrigin(s, origin));
        }
      }

      if (_routePoints.length >= 2 && _routeDistanceKm > 1.2) {
        final alongRoute = await _stations.stationsAlongRoute(
          routePoints: _routePoints,
          origin: origin,
          routeDistanceKm: _routeDistanceKm,
          sampleEveryKm: 8,
          radiusKm: 1.8,
          perSampleLimit: 6,
          maxStations: 24,
        );
        for (final s in alongRoute) {
          merged.putIfAbsent(s.id, () => _withDistanceFromOrigin(s, origin));
        }
      }

      final sorted = merged.values.toList(growable: false)
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      _nearbyStations = sorted;
    } catch (_) {
      _nearbyStations = const [];
    } finally {
      _stationsLoading = false;
    }
  }

  GasStation _withDistanceFromOrigin(GasStation station, LatLng origin) {
    final km = const Distance().as(LengthUnit.Kilometer, origin, station.location);
    return GasStation(
      id: station.id,
      osmType: station.osmType,
      osmId: station.osmId,
      name: station.name,
      address: station.address,
      location: station.location,
      distanceKm: km,
      brand: station.brand,
      operatorName: station.operatorName,
      openingHours: station.openingHours,
      phone: station.phone,
      website: station.website,
      fuelTypes: station.fuelTypes,
      services: station.services,
      tags: station.tags,
    );
  }

  Future<void> _ensureRoute({
    required DrivingBehaviorMetrics behavior,
    required int seq,
  }) async {
    final dest = _destination;
    final pos = location.currentPosition;
    if (dest == null || pos == null) return;

    final origin = LatLng(pos.latitude, pos.longitude);
    if (!_shouldReroute(origin: origin)) return;
    if (_routeLoading) return;

    _routeLoading = true;
    try {
      // Prefer GraphHopper when configured; else fall back to OSRM.
      if (_graphhopper.isConfigured) {
        final gh = await _graphhopper.fetchRoute(
          origin: origin,
          destination: dest.location,
        );
        if (seq != _workSeq) return;
        _routePoints = gh.points;
        _routeDistanceKm = gh.distanceKm;
        _routeDurationSeconds = gh.durationSeconds;
      } else {
        final osrm = await _osrm.fetchRoute(
          origin: origin,
          destination: dest.location,
        );
        if (seq != _workSeq) return;
        _routePoints = osrm.points;
        _routeDistanceKm = osrm.distanceKm;
        _routeDurationSeconds = osrm.durationSeconds;
      }
      _lastRoutedOrigin = origin;
      _lastRoutedAt = DateTime.now();

      // Elevation prefetch (best-effort).
      if (_elevationService.isConfigured && _routePoints.length >= 2) {
        final elevKey = _elevationSignature(_routePoints);
        if (_elevationKey != elevKey) {
          _elevationKey = elevKey;
          final sampled = _sampleRoutePointsForElevation(_routePoints);
          final elev = await _elevationService.lookupMeters(sampled);
          if (seq != _workSeq) return;
          _routeElevations = _expandElevations(
            sampled,
            elev,
            _routePoints.length,
          );
        }
      }
    } catch (_) {
      if (seq != _workSeq) return;
      _routePoints = const [];
      _routeSimulation = null;
      _lastRoutedOrigin = null;
      _lastRoutedAt = null;
      _routeDistanceKm = 0.0;
      _routeDurationSeconds = 0;
      _routeElevations = null;
      _emptyPoint = null;
    } finally {
      _routeLoading = false;
    }
  }

  RouteFuelPrediction? _computeRoutePredictionFromSimulation({
    required DrivingBehaviorMetrics behavior,
  }) {
    final dest = _destination;
    if (dest == null || _routePoints.length < 2) return null;

    // Traffic heuristic placeholder: stop-go will be injected later.
    final sim = _simulationEngine.simulate(
      routePoints: _routePoints,
      tankCapacityLiters: fuel.tankCapacityLiters,
      currentFuelLiters: fuel.currentFuelLiters,
      baseLPer100Km: fuel.baseLPer100Km,
      behavior: behavior,
      elevationMeters: _routeElevations,
      trafficJamFactor: _trafficFactor,
    );
    _routeSimulation = sim;
    _emptyPoint = sim.emptyPoint;
    _arrivalFuelPercentSmoothed = _smoothValue(
      previous: _arrivalFuelPercentSmoothed,
      target: sim.arrivalFuelPercent,
      alpha: 0.16,
    );
    final stationDensityScore = _stationDensityScore(_nearbyStations);
    final rawRiskScore = _routeRiskScore(
      arrivalFuelPercent: sim.arrivalFuelPercent,
      insufficientFuel: sim.insufficientFuel,
      trafficFactor: _trafficFactor,
      stationDensityScore: stationDensityScore,
      elevationMeters: _routeElevations,
    );
    _riskScoreSmoothed = _smoothValue(
      previous: _riskScoreSmoothed,
      target: rawRiskScore,
      alpha: 0.2,
    );
    final risk = _classifyRouteRiskWithHysteresis(
      score: _riskScoreSmoothed,
      insufficientFuel: sim.insufficientFuel,
    );
    final insights = _buildHudInsights(
      behavior: behavior,
      prediction: null,
      simulation: sim,
    );

    return RouteFuelPrediction(
      routeDistanceKm: _routeDistanceKm > 0 ? _routeDistanceKm : _polylineDistanceKm(_routePoints),
      routeDurationSeconds: _routeDurationSeconds,
      litersRequired: sim.litersRequired,
      arrivalFuelLiters: sim.arrivalFuelLiters,
      arrivalFuelPercent: _arrivalFuelPercentSmoothed,
      insufficientFuel: sim.insufficientFuel,
      emptyAfterKm: sim.emptyAfterKm,
      riskLevel: risk,
      trafficFactor: _trafficFactor,
      stationDensityScore: stationDensityScore,
      hudInsights: insights,
    );
  }

  double _estimateTrafficFactor({
    required DrivingBehaviorMetrics behavior,
    required double? speedKmh,
  }) {
    final speed = speedKmh ?? 0.0;
    final speedDropSignal = speed < 24 ? 1.0 : (speed < 36 ? 0.55 : 0.15);
    final stopSignal = (behavior.stopPerKm / 5.0).clamp(0.0, 1.0);
    final idleSignal = behavior.idleRatio.clamp(0.0, 1.0);
    final stopGoSignal = behavior.stopGoIndex.clamp(0.0, 1.0);
    final raw = (speedDropSignal * 0.36) +
        (stopSignal * 0.24) +
        (idleSignal * 0.24) +
        (stopGoSignal * 0.16);
    return (1.0 + raw * 0.24).clamp(1.0, 1.32);
  }

  double _routeRiskScore({
    required double arrivalFuelPercent,
    required bool insufficientFuel,
    required double trafficFactor,
    required double stationDensityScore,
    required List<double>? elevationMeters,
  }) {
    if (insufficientFuel) return 10.0;
    final elevDifficulty = _elevationDifficulty(elevationMeters);
    return (arrivalFuelPercent < 10
            ? 2.6
            : arrivalFuelPercent < 16
                ? 1.8
                : arrivalFuelPercent < 24
                    ? 1.0
                    : 0.28) +
        ((trafficFactor - 1.0) * 4.2) +
        (elevDifficulty * 1.35) +
        ((1.0 - stationDensityScore).clamp(0.0, 1.0) * 1.3);
  }

  RouteRiskLevel _classifyRouteRiskWithHysteresis({
    required double score,
    required bool insufficientFuel,
  }) {
    if (insufficientFuel) {
      _riskLevelStable = RouteRiskLevel.critical;
      return _riskLevelStable;
    }
    final target = score >= 3.3
        ? RouteRiskLevel.critical
        : score >= 2.4
            ? RouteRiskLevel.risky
            : score >= 1.35
                ? RouteRiskLevel.moderate
                : RouteRiskLevel.safe;
    if (target.index > _riskLevelStable.index) {
      _riskEscalationHits += 1;
      _riskDeescalationHits = 0;
      if (_riskEscalationHits >= 2) {
        _riskLevelStable = target;
        _riskEscalationHits = 0;
      }
    } else if (target.index < _riskLevelStable.index) {
      _riskDeescalationHits += 1;
      _riskEscalationHits = 0;
      if (_riskDeescalationHits >= 4) {
        _riskLevelStable = target;
        _riskDeescalationHits = 0;
      }
    } else {
      _riskEscalationHits = 0;
      _riskDeescalationHits = 0;
    }
    return _riskLevelStable;
  }

  double _elevationDifficulty(List<double>? elevationMeters) {
    if (elevationMeters == null || elevationMeters.length < 2) return 0.0;
    var climb = 0.0;
    for (var i = 1; i < elevationMeters.length; i++) {
      final dh = elevationMeters[i] - elevationMeters[i - 1];
      if (dh > 0) climb += dh;
    }
    return (climb / 900.0).clamp(0.0, 1.0);
  }

  double _stationDensityScore(List<GasStation> stations) {
    if (stations.isEmpty) return 0.0;
    final nearest = stations.first.distanceKm;
    final nearestScore = (1.0 - (nearest / 10.0)).clamp(0.0, 1.0);
    final countScore = (stations.length / 12.0).clamp(0.0, 1.0);
    return (nearestScore * 0.62) + (countScore * 0.38);
  }

  List<String> _buildHudInsights({
    required DrivingBehaviorMetrics behavior,
    required RouteFuelPrediction? prediction,
    RouteFuelSimulationResult? simulation,
  }) {
    final out = <String>[];
    final p = prediction ?? _routePrediction;
    final sim = simulation ?? _routeSimulation;

    if (sim?.insufficientFuel == true && sim?.emptyAfterKm != null) {
      out.add('Mức nhiên liệu dự phòng sẽ vào ngưỡng nguy cấp sau ~${sim!.emptyAfterKm!.toStringAsFixed(0)} km');
    }
    if (_trafficFactor >= 1.16) {
      out.add('Phía trước có mật độ dừng/đi cao');
    }
    if (behavior.style == DrivingStyle.aggressive || behavior.harshAccelPerMin > 1.2) {
      out.add('Tăng tốc liên tục đang làm tăng mức tiêu hao');
    }
    if (_elevationDifficulty(_routeElevations) >= 0.42) {
      out.add('Đoạn đường dốc phía trước có thể làm giảm tầm hoạt động còn lại');
    }
    if (_emergencyStation != null) {
      out.add('Sắp tới thời điểm phù hợp để tiếp nhiên liệu (${_emergencyStation!.distanceKm.toStringAsFixed(0)} km)');
    }
    if (p != null && p.arrivalFuelPercent > 0 && p.arrivalFuelPercent <= 25) {
      out.add('Dự báo nhiên liệu khi đến nơi: ${p.arrivalFuelPercent.toStringAsFixed(0)}%');
    }
    return out.take(3).toList();
  }

  PredictionConfidence _buildPredictionConfidence({
    required DrivingBehaviorMetrics behavior,
    required double trafficFactor,
  }) {
    final speed = location.speedKmh ?? 0;
    final gpsStability = speed >= 4 ? 1.0 : 0.55;
    final trafficUncertainty = ((trafficFactor - 1.0) / 0.32).clamp(0.0, 1.0);
    final routeComplexity = ((_routePoints.length / 420.0).clamp(0.0, 1.0));
    final stationSupport = _stationDensityScore(_nearbyStations);
    final behaviorVolatility =
        ((behavior.harshAccelPerMin + behavior.harshBrakePerMin) / 4.0)
            .clamp(0.0, 1.0);
    final score = (gpsStability * 0.28) +
        ((1.0 - trafficUncertainty) * 0.2) +
        ((1.0 - routeComplexity) * 0.12) +
        (stationSupport * 0.16) +
        ((1.0 - behaviorVolatility) * 0.24);
    if (score >= 0.67) return PredictionConfidence.high;
    if (score >= 0.42) return PredictionConfidence.medium;
    return PredictionConfidence.low;
  }

  double _elevationFactorForPrediction() {
    final d = _elevationDifficulty(_routeElevations);
    return (1.0 + d * 0.14).clamp(1.0, 1.18);
  }

  List<FuelWarning> _stabilizeWarnings(List<FuelWarning> next) {
    final now = DateTime.now();
    if (_stableWarnings.isEmpty) {
      _stableWarnings = next;
      _lastWarningsUpdatedAt = now;
      return _stableWarnings;
    }

    final prevTop = _stableWarnings.isNotEmpty ? _stableWarnings.first : null;
    final nextTop = next.isNotEmpty ? next.first : null;
    if (prevTop == null || nextTop == null) {
      _stableWarnings = next;
      _lastWarningsUpdatedAt = now;
      return _stableWarnings;
    }

    final elapsed = _lastWarningsUpdatedAt == null
        ? const Duration(seconds: 99)
        : now.difference(_lastWarningsUpdatedAt!);
    final prevScore = _warningScore(prevTop.severity);
    final nextScore = _warningScore(nextTop.severity);

    final escalate = nextScore > prevScore;
    final canDeescalate = elapsed >= const Duration(seconds: 6);
    if (escalate || nextScore == prevScore || canDeescalate) {
      _stableWarnings = next;
      _lastWarningsUpdatedAt = now;
    }
    return _stableWarnings;
  }

  int _warningScore(WarningSeverity s) => switch (s) {
        WarningSeverity.info => 0,
        WarningSeverity.warning => 1,
        WarningSeverity.critical => 2,
      };

  double _smoothValue({
    required double previous,
    required double target,
    required double alpha,
  }) {
    return (previous * (1 - alpha)) + (target * alpha);
  }

  void _restoreBackgroundSnapshot() {
    final snap = _FuelTripSnapshotStore.current;
    if (snap == null) return;
    _routePoints = snap.routePoints;
    _routeDistanceKm = snap.routeDistanceKm;
    _routeDurationSeconds = snap.routeDurationSeconds;
    _emptyPoint = snap.emptyPoint;
    _destination = snap.destination;
    _destinationHistory = snap.destinationHistory;
  }

  void _saveBackgroundSnapshot() {
    _FuelTripSnapshotStore.current = _FuelTripSnapshot(
      routePoints: List<LatLng>.from(_routePoints),
      routeDistanceKm: _routeDistanceKm,
      routeDurationSeconds: _routeDurationSeconds,
      emptyPoint: _emptyPoint,
      destination: _destination,
      destinationHistory: _destinationHistory,
    );
  }

  void _pushDestinationHistory(PlaceDetails place) {
    final next = <PlaceDetails>[
      place,
      ..._destinationHistory.where((e) => e.placeId != place.placeId),
    ];
    if (next.length > 8) {
      next.removeRange(8, next.length);
    }
    _destinationHistory = next;
  }

  double _polylineDistanceKm(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    final d = const Distance();
    var sum = 0.0;
    for (var i = 1; i < pts.length; i++) {
      sum += d.as(LengthUnit.Kilometer, pts[i - 1], pts[i]);
    }
    return sum;
  }

  List<LatLng> _sampleRoutePointsForElevation(List<LatLng> pts) {
    // Cap payload to keep Open-Elevation calls reasonable.
    const maxSamples = 120;
    if (pts.length <= maxSamples) return pts;
    final step = (pts.length / maxSamples).ceil().clamp(1, 999999);
    final out = <LatLng>[];
    for (var i = 0; i < pts.length; i += step) {
      out.add(pts[i]);
    }
    if (out.last != pts.last) out.add(pts.last);
    return out;
  }

  List<double> _expandElevations(
    List<LatLng> sampled,
    List<double> elev,
    int fullLen,
  ) {
    // v1: simple linear expansion by index mapping.
    if (sampled.length < 2 || elev.length != sampled.length) {
      return List<double>.filled(fullLen, 0.0);
    }
    final out = List<double>.filled(fullLen, elev.first);
    for (var i = 0; i < fullLen; i++) {
      final t = i / (fullLen - 1);
      final idx = (t * (elev.length - 1));
      final lo = idx.floor();
      final hi = idx.ceil();
      if (lo == hi) {
        out[i] = elev[lo];
      } else {
        final frac = idx - lo;
        out[i] = elev[lo] * (1 - frac) + elev[hi] * frac;
      }
    }
    return out;
  }

  bool _shouldReroute({required LatLng origin}) {
    if (_destination == null) return false;
    if (_routePoints.length < 2) return true;
    final last = _lastRoutedOrigin;
    if (last == null) return true;

    const dist = Distance();
    final movedMeters = dist.as(LengthUnit.Meter, last, origin);
    if (movedMeters >= 110) return true;

    final t = _lastRoutedAt;
    if (t == null) return true;
    // Safety refresh, still event-driven (checked on location/fuel events).
    if (DateTime.now().difference(t) >= const Duration(seconds: 75)) return true;

    return false;
  }

  String _elevationSignature(List<LatLng> pts) {
    if (pts.isEmpty) return 'empty';
    final first = pts.first;
    final last = pts.last;
    // Stable enough for cache without hashing.
    return '${pts.length}:'
        '${first.latitude.toStringAsFixed(5)},${first.longitude.toStringAsFixed(5)}->'
        '${last.latitude.toStringAsFixed(5)},${last.longitude.toStringAsFixed(5)}';
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

class _FuelTripSnapshot {
  final List<LatLng> routePoints;
  final double routeDistanceKm;
  final int routeDurationSeconds;
  final LatLng? emptyPoint;
  final PlaceDetails? destination;
  final List<PlaceDetails> destinationHistory;

  const _FuelTripSnapshot({
    required this.routePoints,
    required this.routeDistanceKm,
    required this.routeDurationSeconds,
    required this.emptyPoint,
    required this.destination,
    required this.destinationHistory,
  });
}

class _FuelTripSnapshotStore {
  static _FuelTripSnapshot? current;
}

