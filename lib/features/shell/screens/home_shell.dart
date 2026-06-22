import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/features/geocoding/core/place_location_utils.dart';
import 'package:fuel_tracker_app/core/refuel_debug_tools.dart';
import 'package:fuel_tracker_app/core/interaction_controller.dart';
import 'package:fuel_tracker_app/core/ios_design_tokens.dart';
import 'package:fuel_tracker_app/features/map/core/map_style.dart';
import 'package:fuel_tracker_app/core/micro_motion_spec.dart';
import 'package:fuel_tracker_app/core/motion_director.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/location/core/gps_tracking_policy.dart';
import 'package:fuel_tracker_app/features/navigation/core/navigation_performance.dart';
import 'package:fuel_tracker_app/features/navigation/core/route_off_route.dart';
import 'package:fuel_tracker_app/features/navigation/core/route_snap_warning.dart';
import 'package:fuel_tracker_app/features/navigation/core/polyline_utils.dart';
import 'package:fuel_tracker_app/features/navigation/core/route_progress_utils.dart';
import 'package:fuel_tracker_app/features/navigation/data/session/navigation_session_store.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/fuel_warning_event.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';
import 'package:fuel_tracker_app/features/navigation/data/models/navigation_route.dart';
import 'package:fuel_tracker_app/features/geocoding/data/models/place_model.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/refuel_flow_phase.dart';
import 'package:fuel_tracker_app/features/geocoding/data/exceptions/map_navigation_exceptions.dart';
import 'package:fuel_tracker_app/features/navigation/data/repositories/map_navigation_repository.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/gas_station_service.dart';
import 'package:fuel_tracker_app/features/location/data/services/location_service.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_system_bridge.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_station_service.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/route_fuel_service.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/trip_fuel_status.dart';
import 'package:fuel_tracker_app/shared/widgets/ios_style_widgets.dart';
import 'package:fuel_tracker_app/features/map/presentation/widgets/map_panel.dart';
import 'package:fuel_tracker_app/features/geocoding/presentation/widgets/map_search_bar.dart';
import 'package:fuel_tracker_app/features/navigation/presentation/widgets/navigation_hud.dart';
import 'package:fuel_tracker_app/features/premium/premium_manager.dart';
import 'package:fuel_tracker_app/features/premium/widgets/premium_guard.dart';
import 'package:fuel_tracker_app/features/shell/widgets/shell_bottom_nav.dart';
import 'package:fuel_tracker_app/shared/widgets/vehicle_dashboard_panel.dart';
import 'package:fuel_tracker_app/shared/widgets/cinematic_sheet.dart';
import 'package:fuel_tracker_app/features/fuel/presentation/screens/fuel_intelligence_screen.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_shell_insets.dart';
import 'package:fuel_tracker_app/shared/screens/profile_settings_sheet.dart';
import 'package:fuel_tracker_app/shared/widgets/account_drawer/account_drawer.dart';
import 'package:fuel_tracker_app/shared/widgets/toast/toast_service.dart';
import 'package:fuel_tracker_app/shared/widgets/avatar/user_avatar_widget.dart';
import 'package:fuel_tracker_app/core/theme/luxury_tokens.dart';
import 'package:fuel_tracker_app/core/theme/luxury_widgets.dart';

/// Shell điều phối bản đồ OSM — tìm kiếm Nominatim, chỉ đường OSRM, trạm xăng Overpass.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.inLauncherMode = false});

  /// Đang chạy bên trong LauncherShell — không render chrome iOS giả.
  final bool inLauncherMode;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(vsync: this);
  MapController get _mapController => _animatedMapController.mapController;

  LocationService? _locationService;
  FuelService? _fuelService;
  IosSystemBridge? _systemBridge;
  final GasStationService _gasStationService = GasStationService();
  final MapNavigationRepository _mapNavigation = MapNavigationRepository();
  final RouteFuelService _routeFuelService = const RouteFuelService();
  late final FuelStationService _fuelStationService =
      FuelStationService(nearby: _gasStationService);
  VoidCallback? _fuelListener;

  bool _followUser = true;
  bool _navigationFollow = false;
  bool _mapReady = false;
  bool _loadingRoute = false;
  bool _loadingStations = false;
  /// Đang ở chế độ chỉ đường (tới cây xăng / tuyến).
  bool _isNavigating = false;
  /// Đích tạm hiển thị trên bản đồ khi OSRM chưa trả polyline.
  GasStation? _pendingNavDestination;
  /// Tăng mỗi lần bắt đầu/hủy chỉ đường — hủy kết quả async cũ (OSRM, enrich).
  int _navigationSession = 0;
  NavigationRoute? _activeRoute;
  List<GasStation> _stations = [];
  RefuelFlowPhase? _refuelPhase;
  GasStation? _savedTripDestination;
  GasStation? _activeRefuelStation;
  MapVisualStyle _mapStyle = MapVisualStyle.dark;
  int _navIndex = 0;
  bool _dashboardCollapsed = false;
  bool _searchPanelOpen = false;
  late final MotionDirector _motionDirector;
  late final InteractionController _interactionController;

  bool _navigationSessionRestoreAttempted = false;
  bool _rerouteInFlight = false;
  DateTime? _lastOffRouteRerouteAt;
  DateTime? _lastNavGpsCheckAt;
  DateTime? _rerouteBlockedUntil;
  List<LatLng>? _navRouteCorridor;
  DateTime? _lastGasStationsLoadAt;
  LatLng? _lastGasStationsLoadOrigin;
  bool _gasStationsLoadInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motionDirector = MotionDirector(vsync: this);
    _interactionController = InteractionController(
      motionDirector: _motionDirector,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistNavigationSession();
      debugPrint('[NavSession] lifecycle save ($state)');
    } else if (state == AppLifecycleState.resumed) {
      _rerouteBlockedUntil = DateTime.now().add(
        NavigationPerformance.lifecycleRerouteGrace,
      );
      debugPrint('[NavSession] lifecycle resumed');
      unawaited(_tryRestoreNavigationSession());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locationService ??= context.read<LocationService>()
      ..addListener(_onLocationChanged);
    _fuelService ??= context.read<FuelService>()
      ..onLowFuelWarning = _onLowFuelWarning;
    _fuelListener ??= _refreshActiveTrip;
    _fuelService!.removeListener(_fuelListener!);
    _fuelService!.addListener(_fuelListener!);
    _systemBridge ??= context.read<IosSystemBridge>();

    _locationService!.onDistanceTraveled =
        _fuelService!.consumeDistanceMeters;
    _loadGasStations();

    if (!_navigationSessionRestoreAttempted) {
      _navigationSessionRestoreAttempted = true;
      unawaited(_tryRestoreNavigationSession());
    }
  }

  LatLng? _navigationUserLatLng() {
    final loc = _locationService;
    if (loc == null) return null;
    if (_isNavigating) {
      return loc.navigationLatLng ??
          (loc.currentPosition != null
              ? LatLng(
                  loc.currentPosition!.latitude,
                  loc.currentPosition!.longitude,
                )
              : null);
    }
    final pos = loc.currentPosition;
    if (pos == null) return null;
    return LatLng(pos.latitude, pos.longitude);
  }

  void _onLocationChanged() {
    if (_isNavigating && _activeRoute != null) {
      unawaited(_handleNavigationGps());
    }
    if (_activeRoute != null && _navigationFollow) {
      _followNavigationCamera();
    } else if (_followUser) {
      _animateToUser();
    }
    _loadGasStations();
    _refreshActiveTrip();
    _syncNavigationBridge();
    _checkRefuelArrival();
  }

  Future<void> _handleNavigationGps() async {
    final route = _activeRoute;
    final loc = _locationService;
    if (route == null || loc == null || !_isNavigating) return;

    final now = DateTime.now();
    if (_lastNavGpsCheckAt != null &&
        now.difference(_lastNavGpsCheckAt!) <
            NavigationPerformance.navigationGpsCheckInterval) {
      return;
    }
    _lastNavGpsCheckAt = now;

    if (_rerouteBlockedUntil != null && now.isBefore(_rerouteBlockedUntil!)) {
      return;
    }

    final user = _navigationUserLatLng();
    if (user == null) return;

    final offM = offRouteDistanceM(
      route.polylinePoints,
      user,
      precomputedCorridor: _navRouteCorridor,
    );
    final action = classifyOffRouteMeters(offM);

    switch (action) {
      case OffRouteAction.immediateReroute:
        await _rerouteActiveTrip(immediate: true, offRouteM: offM);
      case OffRouteAction.triggerReroute:
        await _rerouteActiveTrip(immediate: false, offRouteM: offM);
      case OffRouteAction.onRoute:
      case OffRouteAction.updateProgressOnly:
        break;
    }
  }

  Future<void> _rerouteActiveTrip({
    required bool immediate,
    required double offRouteM,
  }) async {
    if (_rerouteInFlight || _activeRoute == null || !_isNavigating) return;

    final now = DateTime.now();
    if (_lastOffRouteRerouteAt != null &&
        now.difference(_lastOffRouteRerouteAt!) <
            NavigationPerformance.rerouteMinInterval) {
      return;
    }

    if (!immediate &&
        _lastOffRouteRerouteAt != null &&
        now.difference(_lastOffRouteRerouteAt!) <
            GpsTrackingPolicy.rerouteCooldown) {
      return;
    }

    final loc = _locationService;
    final fuel = _fuelService;
    if (loc == null || fuel == null) return;

    final origin = _navigationUserLatLng();
    if (origin == null) return;

    final session = _navigationSession;
    final destination = _activeRoute!.destination;

    _rerouteInFlight = true;
    _lastOffRouteRerouteAt = DateTime.now();
    debugPrint(
      '[NavGPS] reroute immediate=$immediate offRoute=${offRouteM.round()}m',
    );

    try {
      final route = await _planRouteQuick(
        origin: origin,
        destination: destination,
        fuel: fuel,
        logTag: immediate ? 'reroute-now' : 'reroute',
      );
      if (!_navigationSessionValid(session)) return;
      _applyNavigationRoute(
        session,
        route,
        navigationFollow: _navigationFollow,
        caller: 'offRouteReroute',
      );
      _persistNavigationSession();
      _syncNavigationBridge();
    } catch (e) {
      debugPrint('[NavGPS] reroute failed: $e');
    } finally {
      _rerouteInFlight = false;
    }
  }

  void _persistNavigationSession() {
    final route = _activeRoute;
    if (route == null || !_isNavigating) {
      unawaited(NavigationSessionStore.clear());
      return;
    }
    unawaited(
      NavigationSessionStore.save(
        NavigationSessionSnapshot(
          savedAt: DateTime.now(),
          destination: route.destination,
          polyline: route.polylinePoints,
          distanceKm: route.distanceKm,
          durationSeconds: route.durationSeconds,
          destinationSnapMeters: route.destinationSnapMeters,
          refuelPhase: _refuelPhase,
          savedTripDestination: _savedTripDestination,
        ),
      ),
    );
  }

  Future<void> _tryRestoreNavigationSession() async {
    if (!mounted || _activeRoute != null) return;

    final snap = await NavigationSessionStore.load();
    if (snap == null || !snap.isNavigating || snap.polyline.length < 2) {
      return;
    }

    if (!mounted) return;
    final fuel = _fuelService;
    if (fuel == null) return;
    final origin = _navigationUserLatLng() ??
        (snap.polyline.isNotEmpty ? snap.polyline.first : null);
    if (origin == null) return;

    final analysis = _routeFuelService.analyze(
      routePoints: snap.polyline,
      routeDistanceKm: snap.distanceKm,
      fuel: fuel,
      destination: snap.destination,
      nearbyStations: _stations,
      origin: origin,
    );

    if (!mounted) return;

    setState(() {
      _isNavigating = true;
      _loadingRoute = false;
      _loadingStations = false;
      _refuelPhase = snap.refuelPhase;
      _savedTripDestination = snap.savedTripDestination;
      _activeRoute = NavigationRoute(
        destination: snap.destination,
        polylinePoints: snap.polyline,
        distanceKm: snap.distanceKm,
        durationSeconds: snap.durationSeconds,
        eta: DateTime.now().add(Duration(seconds: snap.durationSeconds)),
        fuelAnalysis: analysis,
        destinationSnapMeters: snap.destinationSnapMeters,
      );
      _pendingNavDestination = null;
    });

    _rebuildNavRouteCorridor(snap.polyline);
    await _locationService?.setNavigationMode(true);
    _interactionController.activateNavigation();
    _syncNavigationBridge();
    _navLog('✓ restored navigation from persisted session');
  }

  void _checkRefuelArrival() {
    if (_refuelPhase != RefuelFlowPhase.goToGasStation ||
        _activeRoute == null ||
        _activeRefuelStation == null) {
      return;
    }
    final pos = _locationService?.currentPosition;
    if (pos == null) return;
    final distKm = const Distance().as(
      LengthUnit.Kilometer,
      LatLng(pos.latitude, pos.longitude),
      _activeRoute!.destination.location,
    );
    if (distKm <= 0.22) {
      if (_refuelPhase == RefuelFlowPhase.arrivedGasStation) return;
      setState(() => _refuelPhase = RefuelFlowPhase.arrivedGasStation);
      _syncNavigationBridge();
      unawaited(_replenishRouteToSavedDestination());
    }
  }

  void _clearRefuelFlow() {
    _refuelPhase = null;
    _savedTripDestination = null;
    _activeRefuelStation = null;
  }

  bool _navigationSessionValid(int session) =>
      mounted && _navigationSession == session;

  bool _routeStillCurrent(int session, String destinationId) =>
      _navigationSessionValid(session) &&
      _activeRoute?.destination.id == destinationId;

  void _navLog(String message, {int? session}) {
    final tag = session != null
        ? '[Nav][req=$session][cur=$_navigationSession]'
        : '[Nav][cur=$_navigationSession]';
    debugPrint('$tag $message');
  }

  void _navLogGuard(
    String step,
    int session,
    String destinationId, {
    bool logStillCurrent = true,
  }) {
    final valid = _navigationSessionValid(session);
    final activeDest = _activeRoute?.destination.id ?? 'null';
    final stillCurrent = logStillCurrent
        ? _routeStillCurrent(session, destinationId)
        : null;
    debugPrint(
      '[Nav][guard][$step] req=$session cur=$_navigationSession '
      'mounted=$mounted valid=$valid '
      'stillCurrent=$stillCurrent activeDest=$activeDest expectedDest=$destinationId',
    );
  }

  void _applyNavigationRoute(
    int session,
    NavigationRoute route, {
    bool loadingRoute = false,
    bool? loadingStations,
    bool? navigationFollow,
    bool? followUser,
    String caller = 'unknown',
  }) {
    final destId = route.destination.id;
    final points = route.polylinePoints.length;
    _navLog(
      '→ _applyNavigationRoute($caller) dest=$destId '
      'polylinePoints=$points loadingRoute=$loadingRoute',
      session: session,
    );
    if (!_navigationSessionValid(session)) {
      _navLogGuard('_applyNavigationRoute BLOCKED', session, destId);
      return;
    }
    setState(() {
      _activeRoute = route;
      _loadingRoute = loadingRoute;
      _pendingNavDestination = null;
      if (loadingStations != null) _loadingStations = loadingStations;
      if (navigationFollow != null) _navigationFollow = navigationFollow;
      if (followUser != null) _followUser = followUser;
    });
    _navLog(
      '✓ setState done ($caller) dest=$destId '
      'polylinePoints=${_activeRoute?.polylinePoints.length ?? 0} '
      '_loadingRoute=$_loadingRoute mapReady=$_mapReady',
      session: session,
    );
    _rebuildNavRouteCorridor(route.polylinePoints);
    _persistNavigationSession();
  }

  void _rebuildNavRouteCorridor(List<LatLng> points) {
    _navRouteCorridor =
        points.length >= 2 ? densifyPolyline(points) : null;
  }

  void _clearNavigationRouteForSession(int session, {String caller = 'unknown'}) {
    _navLog('→ _clearNavigationRouteForSession($caller)', session: session);
    if (!_navigationSessionValid(session)) {
      _navLogGuard('_clearNavigationRouteForSession BLOCKED', session, 'n/a',
          logStillCurrent: false);
      return;
    }
    setState(() {
      _activeRoute = null;
      _loadingRoute = false;
      _loadingStations = false;
      _isNavigating = false;
      _pendingNavDestination = null;
    });
    _navRouteCorridor = null;
    _navLog('✓ route cleared ($caller)', session: session);
    unawaited(_locationService?.setNavigationMode(false));
    unawaited(NavigationSessionStore.clear());
    _syncNavigationBridge();
    _interactionController.deactivateNavigation();
  }

  void _setNavigationLoadingForSession(int session, bool loading) {
    if (!_navigationSessionValid(session)) return;
    setState(() => _loadingRoute = loading);
  }

  void _setNavigationFollowForSession(int session, bool follow) {
    if (!_navigationSessionValid(session)) return;
    setState(() => _navigationFollow = follow);
  }

  void _setLoadingStationsForSession(int session, bool loading) {
    if (!_navigationSessionValid(session)) return;
    setState(() => _loadingStations = loading);
  }

  GasStation _gasStationFromPlace(PlaceDetails place, {double? distanceKm}) {
    return GasStation(
      id: 'place:${place.placeId}',
      osmType: 'place',
      osmId: place.placeId.hashCode,
      name: place.name.isNotEmpty ? place.name : 'Điểm đến',
      address: place.formattedAddress,
      location: place.location,
      distanceKm: distanceKm ?? 0,
      brand: 'Place',
    );
  }

  /// Xóa tuyến cũ (polyline, marker đích) và vô hiệu mọi request chỉ đường trước đó.
  int _beginNavigationRequest({
    bool preserveRefuelFlow = false,
    GasStation? previewDestination,
  }) {
    _navigationSession++;
    final session = _navigationSession;
    _navLog(
      '→ _beginNavigationRequest preserveRefuel=$preserveRefuelFlow '
      'preview=${previewDestination?.name}',
      session: session,
    );
    setState(() {
      _isNavigating = true;
      _activeRoute = null;
      _loadingRoute = true;
      _loadingStations = false;
      _navigationFollow = false;
      _followUser = true;
      _searchPanelOpen = false;
      _pendingNavDestination = previewDestination;
      if (!preserveRefuelFlow) {
        _clearRefuelFlow();
      }
    });
    _syncNavigationBridge();
    _interactionController.activateNavigation();
    _interactionController.collapseSheet();
    unawaited(_locationService?.setNavigationMode(true));
    _navLog(
      '✓ navigation UI armed _isNavigating=$_isNavigating',
      session: session,
    );
    return session;
  }

  GasStation? _resolveNearestRefuelStation(NavigationRoute route) {
    final highlighted = route.highlightedRefuelStation;
    if (highlighted != null) return highlighted;

    final fuel = context.read<FuelService>();
    final nearby = _stations.isNotEmpty ? _stations : route.stationsOnRoute;

    final ranked = _fuelStationService.recommendEmergencyStation(
      nearby: nearby,
      remainingRangeKm: fuel.remainingDistanceKm,
      routePoints: route.polylinePoints,
      routeDistanceKm: route.distanceKm,
    );
    if (ranked != null) return ranked;

    // Hết tầm — vẫn tự chọn trạm gần nhất trên tuyến.
    final onRoute = route.stationsOnRoute.isNotEmpty
        ? route.stationsOnRoute
        : filterStationsNearPolyline(_stations, route.polylinePoints);
    if (onRoute.isNotEmpty) {
      final sorted = List<GasStation>.from(onRoute)
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return sorted.first;
    }

    if (_stations.isEmpty) return null;
    return _stations.first;
  }

  Future<void> _goToNearestGasStation() async {
    final route = _activeRoute;
    if (route == null) return;

    final station = _resolveNearestRefuelStation(route);
    if (station == null) {
      if (!mounted) return;
      AppToastService.warning(
        title: 'Không tìm thấy trạm',
        message: 'Không tìm thấy trạm xăng gần bạn',
      );
      return;
    }

    _savedTripDestination ??= route.destination;
    _activeRefuelStation = station;
    setState(() => _refuelPhase = RefuelFlowPhase.goToGasStation);
    await _startNavigation(station, preserveRefuelFlow: true);
  }

  void _demoRefuelCompleted() {
    if (!refuelDebugToolsEnabled) return;
    context.read<FuelService>().simulateRefuelForDebug();
    setState(() => _refuelPhase = RefuelFlowPhase.readyToContinueTrip);
    unawaited(_replenishRouteToSavedDestination());
  }

  /// Tính lại tuyến từ vị trí hiện tại (trạm xăng) tới đích đã lưu.
  Future<void> _replenishRouteToSavedDestination() async {
    final saved = _savedTripDestination;
    if (saved == null || _activeRoute == null) return;

    final pos = _locationService?.currentPosition;
    if (pos == null) return;

    final phase = _refuelPhase;
    if (phase != RefuelFlowPhase.arrivedGasStation &&
        phase != RefuelFlowPhase.readyToContinueTrip &&
        phase != RefuelFlowPhase.continueTrip) {
      return;
    }

    final fuel = context.read<FuelService>();
    final origin = LatLng(pos.latitude, pos.longitude);
    final session = _navigationSession;
    _navLog('→ _replenishRouteToSavedDestination dest=${saved.id}',
        session: session);
    _setNavigationLoadingForSession(session, true);

    try {
      _navLog('trước _planRouteQuick (replenish)', session: session);
      final route = await _planRouteQuick(
        origin: origin,
        destination: saved,
        fuel: fuel,
        logTag: 'replenish',
      );
      _navLog(
        'sau _planRouteQuick (replenish) polyline=${route.polylinePoints.length}',
        session: session,
      );
      _navLogGuard('replenish post-OSRM', session, saved.id);
      if (!_navigationSessionValid(session)) return;
      if (_savedTripDestination?.id != saved.id) {
        _navLog('ABORT replenish: saved destination changed', session: session);
        _setNavigationLoadingForSession(session, false);
        return;
      }
      if (_refuelPhase != RefuelFlowPhase.arrivedGasStation &&
          _refuelPhase != RefuelFlowPhase.readyToContinueTrip &&
          _refuelPhase != RefuelFlowPhase.continueTrip) {
        _navLog('ABORT replenish: refuel phase=$_refuelPhase',
            session: session);
        _setNavigationLoadingForSession(session, false);
        return;
      }

      _navLogGuard('replenish trước _applyNavigationRoute', session, saved.id);
      _applyNavigationRoute(session, route, caller: 'replenish');
      _syncNavigationBridge();
      _interactionController.activateNavigation();
      if (_mapReady) {
        _fitRouteOnMap(route.polylinePoints, navigationSession: session);
      } else {
        _navLog('SKIP _fitRouteOnMap: map not ready', session: session);
      }
      unawaited(_enrichRouteWithStations(
        route: route,
        origin: origin,
        fuel: fuel,
        navigationSession: session,
      ));
    } catch (e) {
      _navLog('replenish catch: $e', session: session);
      if (!_navigationSessionValid(session)) return;
      _setNavigationLoadingForSession(session, false);
      if (!mounted) return;
      AppToastService.error(
        title: 'Không tính được tuyến',
        message: '$e',
      );
    }
  }

  Future<void> _continueOriginalTrip() async {
    final saved = _savedTripDestination;
    if (saved == null) return;

    setState(() => _refuelPhase = RefuelFlowPhase.continueTrip);
    await _startNavigation(saved, preserveRefuelFlow: true);
    if (!mounted) return;
    setState(_clearRefuelFlow);
  }

  void _refreshActiveTrip() {
    final route = _activeRoute;
    if (route == null || !mounted) return;
    final session = _navigationSession;
    final destId = route.destination.id;
    final pos = _locationService?.currentPosition;
    if (pos == null) return;

    final fuel = context.read<FuelService>();
    final origin = LatLng(pos.latitude, pos.longitude);
    final analysis = _routeFuelService.analyze(
      routePoints: route.polylinePoints,
      routeDistanceKm: route.distanceKm,
      fuel: fuel,
      destination: route.destination,
      nearbyStations: _stations,
      routeStations: route.stationsOnRoute,
      origin: origin,
    );

    if (!_routeStillCurrent(session, destId)) return;
    setState(() {
      _activeRoute = NavigationRoute(
        destination: route.destination,
        polylinePoints: route.polylinePoints,
        distanceKm: route.distanceKm,
        durationSeconds: route.durationSeconds,
        eta: route.eta,
        fuelAnalysis: analysis,
        stationsOnRoute: route.stationsOnRoute,
        destinationSnapMeters: route.destinationSnapMeters,
      );
    });
    _syncNavigationBridge();
    _checkRefuelArrival();
  }

  void _syncNavigationBridge() {
    if (!mounted) return;
    final bridge = _systemBridge;
    if (bridge == null) return;
    final route = _activeRoute;
    if (route == null) {
      bridge.clearNavigation();
      return;
    }

    final user = _navigationUserLatLng();
    final metrics = routeProgressMetrics(
      routePoints: route.polylinePoints,
      totalDistanceKm: route.distanceKm,
      totalDurationSeconds: route.durationSeconds,
      userLocation: user,
    );

    bridge.setNavigation(
      NavigationIslandSnapshot(
        destinationName: route.destination.name,
        remainingDistanceKm: metrics.remainingKm,
        progress: metrics.progress,
        etaLabel: metrics.etaLabel,
      ),
    );
  }

  Future<void> _loadGasStations() async {
    if (_gasStationsLoadInFlight) return;

    final pos = _locationService?.currentPosition;
    final origin = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : AppConstants.defaultVietnamLocation;

    final now = DateTime.now();
    if (_lastGasStationsLoadAt != null &&
        _lastGasStationsLoadOrigin != null &&
        now.difference(_lastGasStationsLoadAt!) <
            NavigationPerformance.gasStationsReloadInterval) {
      final moved = Geolocator.distanceBetween(
        _lastGasStationsLoadOrigin!.latitude,
        _lastGasStationsLoadOrigin!.longitude,
        origin.latitude,
        origin.longitude,
      );
      if (moved < NavigationPerformance.gasStationsMinMoveM) return;
    }

    _gasStationsLoadInFlight = true;
    try {
      final route = _activeRoute;
      final radiusKm = route != null
          ? (route.distanceKm * 0.55).clamp(5.0, 20.0)
          : 5.0;
      final list = await _gasStationService.findNearestStations(
        origin: origin,
        radiusKm: radiusKm,
      );
      _lastGasStationsLoadAt = now;
      _lastGasStationsLoadOrigin = origin;
      if (mounted) setState(() => _stations = list);
    } finally {
      _gasStationsLoadInFlight = false;
    }
  }

  Future<void> _refreshGasStations() async {
    final pos = _locationService?.currentPosition;
    final origin = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : AppConstants.defaultVietnamLocation;
    final list = await _gasStationService.findNearestStations(
      origin: origin,
      forceRefresh: true,
    );
    if (mounted) setState(() => _stations = list);
  }

  void _onMapReady() {
    _mapReady = true;
    final route = _activeRoute;
    if (route != null && route.polylinePoints.length >= 2) {
      _fitRouteOnMap(
        route.polylinePoints,
        navigationSession: _navigationSession,
      );
      return;
    }
    if (_isNavigating && _pendingNavDestination != null) {
      _focusMapOnPlace(_pendingNavDestination!.location, zoom: 14.8);
      return;
    }
    _animateToUser();
  }

  void _animateToUser({double? zoom}) {
    if (!_mapReady) return;
    final pos = _locationService?.currentPosition;
    if (pos == null) return;
    _animatedMapController.animateTo(
      dest: LatLng(pos.latitude, pos.longitude),
      zoom: zoom ?? AppConstants.mapZoom,
      rotation: 0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  double? _distanceToPlaceKm(PlaceDetails place) {
    final pos = _locationService?.currentPosition;
    if (pos == null) return null;
    return const Distance().as(
      LengthUnit.Kilometer,
      LatLng(pos.latitude, pos.longitude),
      place.location,
    );
  }

  void _followNavigationCamera() {
    if (!_mapReady) return;
    final target = _navigationUserLatLng();
    if (target == null) return;
    _animatedMapController.animateTo(
      dest: target,
      zoom: 17.5,
      rotation: -_locationService!.bearing,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _onLowFuelWarning(FuelWarningEvent event) {
    if (!mounted) return;
    AppToastService.warning(
      title: event.title,
      message: event.message,
    );
    showIosWarningDialog(context, title: event.title, message: event.message);
  }

  void _openStationSheet(GasStation station) {
    _interactionController.openSheet();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (ctx) => CinematicSheet(
        initialExtent: 0.38,
        minExtent: 0.28,
        maxExtent: 0.72,
        motionDirector: _motionDirector,
        onExtent: (e) => _interactionController.expandSheet(
          ((e - 0.28) / (0.72 - 0.28)).clamp(0.0, 1.0),
        ),
        builder: (context, scroll, extent) => _GasStationBottomSheet(
          station: station,
          scrollController: scroll,
          onDirections: () {
            Navigator.pop(ctx);
            _startNavigation(station);
          },
        ),
      ),
    ).whenComplete(() {
      _interactionController.collapseSheet();
    });
  }

  /// Luồng chỉ đường duy nhất — Enter và chạm gợi ý Nominatim.
  Future<void> _navigateToPlace(PlaceDetails place) async {
    final validated = PlaceLocationValidator.navigable(place);
    if (validated == null) {
      final reason = PlaceLocationValidator.rejectReason(place.location);
      _showRouteError(
        reason == null
            ? 'Địa điểm không có tọa độ hợp lệ'
            : 'Tọa độ không hợp lệ ($reason)',
      );
      return;
    }

    if (_mapReady) {
      _focusMapOnPlace(validated.location, zoom: 16.2);
    }

    final km = _distanceToPlaceKm(validated);
    final dest = _gasStationFromPlace(validated, distanceKm: km);
    await _navigateToDestination(dest);
  }

  /// OSRM vẽ polyline → Overpass lấy trạm xăng trong hành lang quanh tuyến.
  Future<void> _navigateToDestination(
    GasStation destination, {
    bool preserveRefuelFlow = false,
  }) async {
    final loc = _locationService;
    if (loc == null) {
      _showRouteError('Dịch vụ vị trí chưa sẵn sàng');
      return;
    }

    LatLng? origin = loc.currentPosition != null
        ? LatLng(
            loc.currentPosition!.latitude,
            loc.currentPosition!.longitude,
          )
        : await loc.resolveOriginForRouting(
            waitTimeout: const Duration(seconds: 2),
          );

    if (origin == null) {
      if (loc.permissionError != null) {
        _showRouteError(loc.permissionError!);
        return;
      }
      origin = loc.defaultRoutingOrigin;
    }

    final fuel = _fuelService;
    if (fuel == null) {
      _showRouteError('Dịch vụ nhiên liệu chưa sẵn sàng');
      return;
    }
    final session = _beginNavigationRequest(
      preserveRefuelFlow: preserveRefuelFlow,
      previewDestination: destination,
    );
    if (_mapReady) {
      _focusMapOnPlace(destination.location, zoom: 15.6);
    }

    final destId = destination.id;
    _navLog('→ _navigateToDestination ${destination.name} id=$destId',
        session: session);

    try {
      final route = await _planRouteQuick(
        origin: origin,
        destination: destination,
        fuel: fuel,
        logTag: 'navigate',
      );
      _navLogGuard('post-OSRM', session, destId);
      if (!_navigationSessionValid(session)) return;
      if (route.polylinePoints.length < 2) {
        throw RoutingException(
          'Tuyến rỗng (${route.polylinePoints.length} điểm)',
        );
      }

      _setLoadingStationsForSession(session, true);
      var routeStations = <GasStation>[];
      try {
        routeStations = await _fuelStationService.stationsAlongRoute(
          routePoints: route.polylinePoints,
          origin: origin,
          routeDistanceKm: route.distanceKm,
        );
      } catch (e) {
        _navLog('stationsAlongRoute bootstrap: $e', session: session);
      }
      if (_stations.isEmpty) {
        await _loadGasStations();
      }
      final bootstrapStations = _mergeGasStations(
        routeStations,
        filterStationsNearPolyline(_stations, route.polylinePoints),
      )
          .where((s) => !_isDestinationGasStation(s, destination))
          .toList();
      _setLoadingStationsForSession(session, false);

      final bootstrapAnalysis = _routeFuelService.analyze(
        routePoints: route.polylinePoints,
        routeDistanceKm: route.distanceKm,
        fuel: fuel,
        destination: destination,
        nearbyStations: _stations,
        routeStations: bootstrapStations,
        origin: origin,
      );

      _applyNavigationRoute(
        session,
        NavigationRoute(
          destination: route.destination,
          polylinePoints: route.polylinePoints,
          distanceKm: route.distanceKm,
          durationSeconds: route.durationSeconds,
          eta: route.eta,
          fuelAnalysis: bootstrapAnalysis,
          stationsOnRoute: bootstrapStations,
          destinationSnapMeters: route.destinationSnapMeters,
        ),
        loadingRoute: false,
        navigationFollow: false,
        followUser: true,
        caller: 'navigateToDestination',
      );
      _showRouteSnapWarning(route.destinationSnapMeters);
      _syncNavigationBridge();
      _interactionController.activateNavigation();
      _fitRouteOnMap(route.polylinePoints, navigationSession: session);

      if (bootstrapStations.length < 3) {
        unawaited(_enrichRouteWithStations(
          route: route,
          origin: origin,
          fuel: fuel,
          navigationSession: session,
        ));
      }
    } catch (e) {
      _navLog('navigateToDestination catch: $e', session: session);
      if (!_navigationSessionValid(session)) return;
      _clearNavigationRouteForSession(session, caller: 'navigateToDestination');
      _showRouteError(_routeErrorMessage(e));
    }
  }

  Future<void> _startNavigation(
    GasStation station, {
    bool preserveRefuelFlow = false,
  }) async {
    await _navigateToDestination(
      station,
      preserveRefuelFlow: preserveRefuelFlow,
    );
  }

  RefuelFlowPhase? _refuelPhaseForHud(NavigationRoute route) {
    if (_refuelPhase != null) return _refuelPhase;
    if (route.fuelAnalysis.insufficientFuel) {
      return RefuelFlowPhase.needRefuel;
    }
    return null;
  }

  bool _canStartRefuelDetour(NavigationRoute route) {
    if (_refuelPhase == RefuelFlowPhase.goToGasStation ||
        _refuelPhase == RefuelFlowPhase.arrivedGasStation ||
        _refuelPhase == RefuelFlowPhase.readyToContinueTrip ||
        _refuelPhase == RefuelFlowPhase.continueTrip) {
      return false;
    }
    return route.fuelAnalysis.insufficientFuel;
  }

  void _clearNavigation() {
    _navigationSession++;
    _navLog('→ _clearNavigation (user)');
    setState(() {
      _isNavigating = false;
      _pendingNavDestination = null;
      _activeRoute = null;
      _loadingRoute = false;
      _loadingStations = false;
      _navigationFollow = false;
      _followUser = true;
      _clearRefuelFlow();
    });
    _navRouteCorridor = null;
    unawaited(_locationService?.setNavigationMode(false));
    unawaited(NavigationSessionStore.clear());
    _syncNavigationBridge();
    _interactionController.deactivateNavigation();
    _interactionController.collapseSheet();
    _animateToUser();
  }

  /// Zoom bản đồ tới tọa độ.
  void _focusMapOnPlace(LatLng target, {double zoom = 16.8}) {
    void apply() {
      _mapController.move(target, zoom);
      _animatedMapController.animateTo(
        dest: target,
        zoom: zoom,
        rotation: 0,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    }

    if (!_mapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_mapReady) {
          apply();
        } else {
          _focusMapOnPlace(target, zoom: zoom);
        }
      });
      return;
    }
    apply();
  }

  /// Trạm xăng trên đoạn đường tuyến — dùng Overpass + trạm quanh GPS làm fallback.
  List<GasStation> _mapStationsForDisplay(NavigationRoute? trip) {
    if (_loadingRoute) return const [];
    if (trip == null) return _stations;
    if (trip.polylinePoints.length < 2) return const [];
    return _stationsAlongActiveRoute(trip);
  }

  List<GasStation> _stationsAlongActiveRoute(NavigationRoute trip) {
    final fromRoute = trip.stationsOnRoute;
    final fromNearby = filterStationsNearPolyline(
      _stations,
      trip.polylinePoints,
    );
    final merged = _mergeGasStations(fromRoute, fromNearby);
    return merged
        .where((s) => !_isDestinationGasStation(s, trip.destination))
        .toList();
  }

  List<GasStation> _mergeGasStations(List<GasStation> primary, List<GasStation> extra) {
    if (extra.isEmpty) return primary;
    if (primary.isEmpty) return extra;
    final seen = {for (final s in primary) s.id};
    final out = List<GasStation>.from(primary);
    for (final s in extra) {
      if (seen.add(s.id)) out.add(s);
    }
    return out;
  }

  bool _isDestinationGasStation(GasStation station, GasStation destination) {
    if (station.id == destination.id) return true;
    return _isSameMapPoint(station.location, destination.location, maxMeters: 50);
  }

  bool _isSameMapPoint(LatLng a, LatLng b, {double maxMeters = 35}) {
    return const Distance().as(LengthUnit.Meter, a, b) <= maxMeters;
  }

  void _showRouteError(String message) {
    if (!mounted) return;
    AppToastService.error(
      title: 'Lỗi điều hướng',
      message: message,
      duration: const Duration(seconds: 4),
    );
  }

  void _showRouteSnapWarning(double? snapMeters) {
    if (!mounted || snapMeters == null) return;
    final msg = RouteSnapWarning.messageForSnapMeters(snapMeters);
    if (msg == null) return;
    AppToastService.warning(
      title: 'Cảnh báo định vị',
      message: msg,
      duration: Duration(
        seconds: RouteSnapWarning.isStrongWarning(snapMeters) ? 5 : 3,
      ),
    );
  }

  String _routeErrorMessage(Object e) {
    if (e is RoutingException) return e.message;
    return 'Không lấy được tuyến: $e';
  }

  Future<NavigationRoute> _planRouteQuick({
    required LatLng origin,
    required GasStation destination,
    required FuelService fuel,
    String logTag = 'plan',
  }) async {
    _navLog(
      '[$logTag] trước OSRM '
      '(${origin.latitude},${origin.longitude})→'
      '(${destination.location.latitude},${destination.location.longitude}) '
      'destId=${destination.id}',
    );
    final plan = await _mapNavigation.planRoute(
      origin: origin,
      destination: destination.location,
    );
    _navLog(
      '[$logTag] sau OSRM points=${plan.points.length} '
      'osrmDistanceKm=${plan.distanceKm.toStringAsFixed(2)} '
      'durationSec=${plan.durationSeconds} (OSRM)',
    );
    final analysis = _routeFuelService.analyze(
      routePoints: plan.points,
      routeDistanceKm: plan.distanceKm,
      fuel: fuel,
      destination: destination,
      nearbyStations: _stations,
      origin: origin,
    );
    final built = NavigationRoute(
      destination: destination,
      polylinePoints: plan.points,
      distanceKm: plan.distanceKm,
      durationSeconds: plan.durationSeconds,
      eta: plan.eta,
      fuelAnalysis: analysis,
      stationsOnRoute: const [],
      destinationSnapMeters: plan.destinationSnapMeters,
    );
    _navLog(
      '[$logTag] NavigationRoute built polyline=${built.polylinePoints.length}',
    );
    return built;
  }

  Future<void> _enrichRouteWithStations({
    required NavigationRoute route,
    required LatLng origin,
    required FuelService fuel,
    required int navigationSession,
  }) async {
    final destId = route.destination.id;
    _navLog('→ _enrichRouteWithStations dest=$destId', session: navigationSession);
    _navLogGuard('enrich start', navigationSession, destId);
    if (!_routeStillCurrent(navigationSession, destId)) return;
    _setLoadingStationsForSession(navigationSession, true);

    try {
      _navLog('trước stationsAlongRoute', session: navigationSession);
      final routeStations = await _fuelStationService.stationsAlongRoute(
        routePoints: route.polylinePoints,
        origin: origin,
        routeDistanceKm: route.distanceKm,
      );
      final mergedStations = _mergeGasStations(
        routeStations,
        filterStationsNearPolyline(_stations, route.polylinePoints),
      );
      _navLog(
        'sau stationsAlongRoute overpass=${routeStations.length} '
        'merged=${mergedStations.length}',
        session: navigationSession,
      );
      _navLogGuard('enrich post-stations', navigationSession, destId);
      if (!_routeStillCurrent(navigationSession, destId)) return;
      final analysis = _routeFuelService.analyze(
        routePoints: route.polylinePoints,
        routeDistanceKm: route.distanceKm,
        fuel: fuel,
        destination: route.destination,
        nearbyStations: _stations,
        routeStations: mergedStations,
        origin: origin,
      );
      _navLogGuard('enrich trước _applyNavigationRoute', navigationSession, destId);
      if (!_routeStillCurrent(navigationSession, destId)) return;
      _applyNavigationRoute(
        navigationSession,
        NavigationRoute(
          destination: route.destination,
          polylinePoints: route.polylinePoints,
          distanceKm: route.distanceKm,
          durationSeconds: route.durationSeconds,
          eta: route.eta,
          fuelAnalysis: analysis,
          stationsOnRoute: mergedStations,
          destinationSnapMeters: route.destinationSnapMeters,
        ),
        loadingStations: false,
        caller: 'enrich',
      );
      _syncNavigationBridge();
      _navLog('✓ enrich done', session: navigationSession);
    } catch (e) {
      _navLog('enrich catch: $e', session: navigationSession);
      if (!_routeStillCurrent(navigationSession, destId)) return;
      if (_navigationSessionValid(navigationSession)) {
        final fallback = _stationsAlongActiveRoute(route);
        if (fallback.isNotEmpty) {
          final analysis = _routeFuelService.analyze(
            routePoints: route.polylinePoints,
            routeDistanceKm: route.distanceKm,
            fuel: fuel,
            destination: route.destination,
            nearbyStations: _stations,
            routeStations: fallback,
            origin: origin,
          );
          _applyNavigationRoute(
            navigationSession,
            NavigationRoute(
              destination: route.destination,
              polylinePoints: route.polylinePoints,
              distanceKm: route.distanceKm,
              durationSeconds: route.durationSeconds,
              eta: route.eta,
              fuelAnalysis: analysis,
              stationsOnRoute: fallback,
              destinationSnapMeters: route.destinationSnapMeters,
            ),
            loadingStations: false,
            caller: 'enrich-fallback',
          );
          _syncNavigationBridge();
        } else {
          _showRouteError('Không thể tải trạm xăng');
        }
      }
    } finally {
      _setLoadingStationsForSession(navigationSession, false);
    }
  }

  void _fitRouteOnMap(
    List<LatLng> points, {
    int? navigationSession,
  }) {
    _navLog(
      '→ _fitRouteOnMap points=${points.length} mapReady=$_mapReady',
      session: navigationSession,
    );
    if (!_mapReady || points.isEmpty) {
      _navLog(
        'SKIP _fitRouteOnMap mapReady=$_mapReady empty=${points.isEmpty}',
        session: navigationSession,
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) {
        _navLog('SKIP fitCamera postFrame: !mounted || !mapReady',
            session: navigationSession);
        return;
      }
      if (navigationSession != null &&
          !_navigationSessionValid(navigationSession)) {
        _navLogGuard('_fitRouteOnMap BLOCKED', navigationSession,
            _activeRoute?.destination.id ?? 'n/a');
        return;
      }
      try {
        _navLog('fitCamera bounds (${points.length} pts)',
            session: navigationSession);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.fromLTRB(48, 120, 48, 300),
          ),
        );
        Future.delayed(const Duration(milliseconds: 900), () {
          if (navigationSession == null) {
            if (!mounted || _activeRoute == null) return;
            _navLog('navigationFollow=true (no session)');
            setState(() => _navigationFollow = true);
            _followNavigationCamera();
            return;
          }
          if (!_navigationSessionValid(navigationSession) ||
              _activeRoute == null) {
            _navLog(
              'SKIP navigationFollow delayed: valid='
              '${_navigationSessionValid(navigationSession)} '
              'activeRoute=${_activeRoute != null}',
              session: navigationSession,
            );
            return;
          }
          _navLog('navigationFollow=true (delayed)', session: navigationSession);
          _setNavigationFollowForSession(navigationSession, true);
          _followNavigationCamera();
        });
      } catch (e) {
        _navLog('fitCamera error: $e', session: navigationSession);
      }
    });
  }

  void _showLayerSheet() {
    _interactionController.openSheet();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (ctx) {
        Widget item({
          required IconData icon,
          required String title,
          required bool selected,
          required VoidCallback onTap,
        }) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white.withValues(alpha: 0.80), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: MicroMotionSpec.slow,
                      curve: MicroMotionSpec.fadeCurve,
                      child: const Icon(
                        Icons.check_rounded,
                        color: VehicleUi.accentBlue,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return CinematicSheet(
          initialExtent: 0.30,
          minExtent: 0.24,
          maxExtent: 0.55,
          motionDirector: _motionDirector,
          onExtent: (e) => _interactionController.expandSheet(
            ((e - 0.24) / (0.55 - 0.24)).clamp(0.0, 1.0),
          ),
          builder: (context, scroll, extent) => SafeArea(
            top: false,
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                const CinematicGrabber(),
                Text(
                  'Kiểu bản đồ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                item(
                  icon: Icons.dark_mode_outlined,
                  title: 'Ban đêm',
                  selected: _mapStyle == MapVisualStyle.dark,
                  onTap: () {
                    setState(() => _mapStyle = MapVisualStyle.dark);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 6),
                item(
                  icon: Icons.map_outlined,
                  title: 'Mặc định',
                  selected: _mapStyle == MapVisualStyle.standard,
                  onTap: () {
                    setState(() => _mapStyle = MapVisualStyle.standard);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 6),
                item(
                  icon: Icons.satellite_alt_outlined,
                  title: 'Vệ tinh',
                  selected: _mapStyle == MapVisualStyle.satellite,
                  onTap: () {
                    setState(() => _mapStyle = MapVisualStyle.satellite);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 6),
                item(
                  icon: Icons.terrain_outlined,
                  title: 'Địa hình',
                  selected: _mapStyle == MapVisualStyle.terrain,
                  onTap: () {
                    setState(() => _mapStyle = MapVisualStyle.terrain);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _interactionController.collapseSheet();
    });
  }

  void _onNavTap(int i) {
    setState(() => _navIndex = i);

    switch (i) {
      case 0:
        return;
      case 1:
        FuelIntelligenceScreen.open(context).whenComplete(() {
          if (!mounted) return;
          setState(() => _navIndex = 0);
        });
        return;
      case 2:
        _openProfileSheet().whenComplete(() {
          if (mounted) setState(() => _navIndex = 0);
        });
        return;
    }
  }

  Future<void> _openProfileSheet() {
    _interactionController.openSheet();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const ProfileSettingsSheet(),
    ).whenComplete(() {
      _interactionController.collapseSheet();
    });
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _closeDrawer() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
    }
  }

  Future<void> _onDrawerItem(String id) async {
    await AccountDrawerActions.handle(
      context,
      itemId: id,
      closeDrawer: _closeDrawer,
      onHome: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationService>();
    final fuel = context.watch<FuelService>();
    final pos = loc.currentPosition;
    final low = fuel.isLowFuel;
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final safe = mq.padding;
    final screenW = size.width;
    final screenH = size.height;

    final mapTarget = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : AppConstants.defaultVietnamLocation;

    final hasRoute = _activeRoute != null;
    final inNavigation = _isNavigating || hasRoute;
    final tripRoute = _activeRoute;
    final mapDestination = tripRoute?.destination ?? _pendingNavDestination;
    final routePreviewPolyline = _loadingRoute &&
            mapDestination != null &&
            (tripRoute == null || tripRoute.polylinePoints.length < 2)
        ? [
            pos != null
                ? LatLng(pos.latitude, pos.longitude)
                : AppConstants.defaultVietnamLocation,
            mapDestination.location,
          ]
        : null;
    final mapGasStations = _mapStationsForDisplay(tripRoute);
    final rangeCircleKm = pos != null && inNavigation
        ? fuel.remainingDistanceKm
        : null;
    final rangeStatus = tripRoute != null
        ? tripRoute.fuelAnalysis.status
        : (fuel.isLowFuel ? TripFuelStatus.warning : TripFuelStatus.safe);
    final highlightStationId = tripRoute?.highlightedRefuelStation?.id;
    const navBarHeight = ShellBottomNav.barHeight;

    // Adaptive layout anchors (match iPhone premium proportions).
    final navBottom = widget.inLauncherMode
        ? (IosShellInsets.maybeOf(context)?.bottom ?? 8) + 8
        : 8.0 + safe.bottom;
    // Add a bit more breathing room between dock and dashboard.
    final statsBottom = navBottom + navBarHeight + 30.0;
    final statsWidth = (screenW * 0.9).clamp(300.0, 500.0);
    final statsHeight = (screenH * (low ? 0.22 : 0.2)).clamp(158.0, 200.0);
    // Keep right-side controls visually detached from dashboard.
    final controlsBottom = statsBottom + statsHeight + 30.0;
    final carBottom = navBottom + navBarHeight + (screenH * 0.1).clamp(88.0, 130.0);
    final fabBottom = inNavigation ? navBottom + 96 : carBottom + 8;
    final locError = loc.permissionError;

    final shell = AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        drawerEnableOpenDragGesture: true,
        drawerScrimColor: Colors.black.withValues(alpha: 0.45),
        onDrawerChanged: (open) {
          if (open) {
            _interactionController.openSheet();
          } else {
            _interactionController.collapseSheet();
          }
        },
        drawer: Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          width: MediaQuery.sizeOf(context).width,
          child: AccountDrawer(onItemSelected: _onDrawerItem),
        ),
        backgroundColor: VehicleUi.surfaceDark,
        body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          MapParallaxShell(
            child: MapPanel(
            mapController: _mapController,
            locationService: loc,
            mapTarget: mapTarget,
            hasPosition: pos != null,
            gasStations: mapGasStations,
            loadingStations: hasRoute && _loadingStations,
            lowFuel: low,
            visualStyle: _mapStyle,
            routePolyline: tripRoute?.polylinePoints,
            routePreviewPolyline: routePreviewPolyline,
            fuelEmptyPoint: tripRoute?.fuelAnalysis.emptyPointOnRoute,
            activeDestination: mapDestination,
            rangeCircleKm: rangeCircleKm,
            rangeStatus: rangeStatus,
            highlightedStationId: highlightStationId,
            onMapReady: _onMapReady,
            navigationMode: inNavigation && (_navigationFollow || _loadingRoute),
            onUserPanStarted: () {
              setState(() {
                _followUser = false;
                _navigationFollow = false;
              });
              _interactionController.focusMap();
            },
            onStationTap: _openStationSheet,
          ),
          ),
          // Cinematic focus layer: map dims + haze when sheets are active.
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _motionDirector,
              builder: (context, _) {
                final t = _motionDirector.mapDim.clamp(0.0, 1.0);
                if (t <= 0.001) return const SizedBox.shrink();
                return Opacity(
                  opacity: t,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.26),
                        ],
                        stops: const [0.0, 0.52, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!inNavigation && !_searchPanelOpen) ...[
            AnimatedPositioned(
              duration: MicroMotionSpec.slow,
              curve: MicroMotionSpec.fadeCurve,
              right: 20,
              // Expanded dashboard: controls stay higher.
              // Collapsed dashboard: controls glide down near bottom controls.
              bottom: _dashboardCollapsed
                  ? (carBottom + 76)
                  : (controlsBottom + 12),
              child: _MapControlsStack(
                onLayers: _showLayerSheet,
                onRefreshStations: _refreshGasStations,
                onLocate: () {
                  setState(() => _followUser = true);
                  _animateToUser();
                },
              ),
            ),
            Positioned(
              right: 20,
              bottom: carBottom,
              child: _RouteActionButton(
                onTap: () {
                  if (_stations.isNotEmpty) {
                    _startNavigation(_stations.first);
                  } else {
                    AppToastService.info(
                      title: 'Thông tin',
                      message: 'Chưa có cây xăng gần bạn',
                    );
                  }
                },
              ),
            ),
            Positioned(
              left: (screenW - statsWidth) / 2,
              width: statsWidth,
              bottom: statsBottom,
              child: AnimatedSwitcher(
                duration: MicroMotionSpec.slow,
                switchInCurve: MicroMotionSpec.fadeCurve,
                switchOutCurve: MicroMotionSpec.fadeCurve,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _dashboardCollapsed
                    ? Align(
                        key: const ValueKey('dashboard_collapsed'),
                        alignment: Alignment.centerRight,
                        child: _DashboardCollapsedButton(
                          onTap: () => setState(() => _dashboardCollapsed = false),
                        ),
                      )
                    : SizedBox(
                        key: const ValueKey('dashboard_expanded'),
                        width: statsWidth,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            PremiumGuard(
                              feature: PremiumFeature.remainingRange,
                              lockedPreview:
                                  const _LockedFuelDashboardPreview(),
                              child: VehicleDashboardPanel(
                                fuel: fuel,
                                lowFuel: low,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 16,
                              child: _DashboardCollapseButton(
                                onTap: () => setState(() => _dashboardCollapsed = true),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: navBottom,
              child: ShellBottomNav(
                currentIndex: _navIndex,
                onTap: _onNavTap,
                items: const [
                  VehicleNavItem(icon: Icons.map_outlined, label: 'Bản đồ'),
                  VehicleNavItem(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Nhiên liệu',
                  ),
                  VehicleNavItem(
                    icon: Icons.settings_outlined,
                    label: 'Cài đặt',
                  ),
                ],
              ),
            ),
          ],
          if (inNavigation && !hasRoute && _loadingRoute)
            Positioned(
              left: 16,
              right: 16,
              bottom: navBottom + 12,
              child: _NavigationComputingCard(
                destinationName: mapDestination?.name ?? 'Điểm đến',
                onClose: _clearNavigation,
              ),
            ),
          if (hasRoute && tripRoute != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: navBottom,
              child: NavigationHud(
                route: tripRoute,
                motionDirector: _motionDirector,
                onClose: _clearNavigation,
                refuelPhase: _refuelPhaseForHud(tripRoute),
                onNavigateToNearestStation:
                    _canStartRefuelDetour(tripRoute)
                        ? _goToNearestGasStation
                        : null,
                onContinueTrip:
                    _refuelPhase == RefuelFlowPhase.arrivedGasStation ||
                            _refuelPhase == RefuelFlowPhase.readyToContinueTrip
                        ? _continueOriginalTrip
                        : null,
                onDemoRefuel: refuelDebugToolsEnabled &&
                        (_refuelPhase == RefuelFlowPhase.goToGasStation ||
                            _refuelPhase == RefuelFlowPhase.arrivedGasStation)
                    ? _demoRefuelCompleted
                    : null,
              ),
            ),
          if (inNavigation)
            Positioned(
              right: 12,
              bottom: fabBottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapControlButton(
                    icon: Icons.my_location_rounded,
                    onTap: () {
                      setState(() {
                        _navigationFollow = true;
                        _followUser = true;
                      });
                      _followNavigationCamera();
                    },
                  ),
                  const SizedBox(height: 10),
                  if (hasRoute)
                    _MapControlButton(
                      icon: Icons.fit_screen_outlined,
                      onTap: () =>
                          _fitRouteOnMap(tripRoute!.polylinePoints),
                    ),
                ],
              ),
            ),
          if (low && !inNavigation)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: IosDesign.warningRed.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
          if (!inNavigation)
            Positioned(
              top: widget.inLauncherMode
                  ? (IosShellInsets.maybeOf(context)?.top ?? 0)
                  : 0,
              left: 0,
              right: 0,
              child: Material(
                type: MaterialType.transparency,
                elevation: _searchPanelOpen ? 28 : 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (locError != null)
                        Material(
                          color: VehicleUi.warningRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_off_outlined,
                                  size: 18,
                                  color: VehicleUi.warningRed,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    locError,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFCA5A5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (locError != null) const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HamburgerButton(onTap: _openDrawer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MapSearchBar(
                              searchService: _mapNavigation.geocoding,
                              enabled: !inNavigation,
                              biasLocation: pos != null
                                  ? LatLng(pos.latitude, pos.longitude)
                                  : null,
                              onNavigate: _navigateToPlace,
                              onPanelOpenChanged: (open) {
                                if (_searchPanelOpen == open) return;
                                setState(() => _searchPanelOpen = open);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: _openProfileSheet,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: VehicleUi.card.withValues(alpha: 0.92),
                                border: Border.all(color: VehicleUi.glassBorder),
                                boxShadow: VehicleUi.floatingShadowNear,
                              ),
                              alignment: Alignment.center,
                              child: UserAvatarWidget(size: 44, fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );

    if (widget.inLauncherMode) {
      return PopScope(canPop: false, child: shell);
    }
    return shell;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistNavigationSession();
    _locationService?.removeListener(_onLocationChanged);
    _locationService?.onDistanceTraveled = null;
    if (_fuelListener != null) {
      _fuelService?.removeListener(_fuelListener!);
    }
    _fuelService?.onLowFuelWarning = null;
    _systemBridge?.clearNavigation();
    _animatedMapController.dispose();
    _interactionController.dispose();
    _motionDirector.dispose();
    super.dispose();
  }
}

/// Nút hamburger — góc trên trái, glass style.
class _HamburgerButton extends StatefulWidget {
  const _HamburgerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_HamburgerButton> createState() => _HamburgerButtonState();
}

class _HamburgerButtonState extends State<_HamburgerButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? MicroMotionSpec.pressedScale : 1,
        duration: MicroMotionSpec.fast,
        curve: MicroMotionSpec.emphasisCurve,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VehicleUi.card.withValues(alpha: 0.95),
                LuxuryTokens.backgroundElevated.withValues(alpha: 0.9),
              ],
            ),
            border: Border.all(color: LuxuryTokens.glassBorderBright),
            boxShadow: LuxuryTokens.elevation(2, glow: LuxuryTokens.neonBlue),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.menu_rounded,
            color: LuxuryTokens.neonBlue,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Unified floating map controls — single glass capsule.
class _MapControlsStack extends StatelessWidget {
  final VoidCallback onLayers;
  final VoidCallback onLocate;
  final VoidCallback onRefreshStations;

  const _MapControlsStack({
    required this.onLayers,
    required this.onLocate,
    required this.onRefreshStations,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: VehicleUi.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
          border: Border.all(color: VehicleUi.glassBorder),
          boxShadow: VehicleUi.floatingShadowNear,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapControlButton(icon: Icons.layers_outlined, onTap: onLayers),
            Container(
              width: 28,
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: VehicleUi.glassBorder,
            ),
            _MapControlButton(
              icon: Icons.refresh_rounded,
              onTap: onRefreshStations,
            ),
            Container(
              width: 28,
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: VehicleUi.glassBorder,
            ),
            _MapControlButton(icon: Icons.my_location_rounded, onTap: onLocate),
          ],
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: VehicleUi.accentBlue.withValues(alpha: 0.18),
        highlightColor: VehicleUi.accentBlue.withValues(alpha: 0.08),
        child: SizedBox(
          width: 44,
          height: 40,
          child: Icon(icon, color: VehicleUi.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _RouteActionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RouteActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VehicleUi.radiusMd),
        splashColor: VehicleUi.accentBlue.withValues(alpha: 0.22),
        highlightColor: VehicleUi.accentBlue.withValues(alpha: 0.10),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VehicleUi.radiusMd),
            color: VehicleUi.accentBlue,
            boxShadow: [
              BoxShadow(
                color: VehicleUi.accentBlue.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _DashboardCollapseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DashboardCollapseButton({required this.onTap});

  @override
  State<_DashboardCollapseButton> createState() => _DashboardCollapseButtonState();
}

class _DashboardCollapseButtonState extends State<_DashboardCollapseButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? MicroMotionSpec.pressedScale : 1.0,
        duration: MicroMotionSpec.fast,
        curve: MicroMotionSpec.emphasisCurve,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Icon(
            Icons.remove_rounded,
            size: 16,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _DashboardCollapsedButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DashboardCollapsedButton({required this.onTap});

  @override
  State<_DashboardCollapsedButton> createState() => _DashboardCollapsedButtonState();
}

class _DashboardCollapsedButtonState extends State<_DashboardCollapsedButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? MicroMotionSpec.pressedScale : 1.0,
        duration: MicroMotionSpec.fast,
        curve: MicroMotionSpec.emphasisCurve,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: VehicleUi.card.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: VehicleUi.glassBorder),
            boxShadow: VehicleUi.floatingShadowNear,
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: VehicleUi.accentBlue,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _LockedFuelDashboardPreview extends StatelessWidget {
  const _LockedFuelDashboardPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LuxuryTokens.radiusLg),
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(LuxuryTokens.radiusLg),
            border: Border.all(
              color: LuxuryTokens.neonBlue.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: LuxuryTokens.elevation(2, glow: LuxuryTokens.neonBlue),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuxuryTokens.neonBlue.withValues(alpha: 0.16),
                      border: Border.all(
                        color: LuxuryTokens.neonCyan.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 22,
                      color: LuxuryTokens.neonCyan,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Chỉ dành cho Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nâng cấp để xem quãng đường còn lại & hiệu suất.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: VehicleUi.textSecondary.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GasStationBottomSheet extends StatelessWidget {
  final GasStation station;
  final VoidCallback onDirections;
  final ScrollController scrollController;

  const _GasStationBottomSheet({
    required this.station,
    required this.onDirections,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    Widget chip(String text, {IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: ListView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 0, 16, 18 + safeBottom),
        children: [
          const CinematicGrabber(),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VehicleUi.accentBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: VehicleUi.accentBlueGlow.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.local_gas_station_rounded,
                  color: VehicleUi.accentBlue.withValues(alpha: 0.95),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${station.distanceKm.toStringAsFixed(1)} km • ${station.brand}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: VehicleUi.textMuted.withValues(alpha: 0.92),
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _QuietRow(
            icon: Icons.schedule_rounded,
            label: 'Giờ mở cửa',
            value: station.openingHoursLabel,
          ),
          if (station.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _QuietRow(
              icon: Icons.place_outlined,
              label: 'Địa chỉ',
              value: station.address,
              maxLines: 2,
            ),
          ],
          if ((station.operatorName ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _QuietRow(
              icon: Icons.apartment_rounded,
              label: 'Đơn vị',
              value: station.operatorName!,
              maxLines: 1,
            ),
          ],
          if ((station.phone ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _QuietRow(
              icon: Icons.call_rounded,
              label: 'SĐT',
              value: station.phone!,
              maxLines: 1,
            ),
          ],
          if ((station.website ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _QuietRow(
              icon: Icons.public_rounded,
              label: 'Website',
              value: station.website!,
              maxLines: 1,
            ),
          ],
          if (station.fuelTypes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Loại nhiên liệu',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: station.fuelTypes
                  .take(12)
                  .map((t) => chip(t, icon: Icons.local_gas_station_rounded))
                  .toList(),
            ),
          ],
          if (station.services.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Dịch vụ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: station.services
                  .take(14)
                  .map((t) => chip(t, icon: Icons.check_circle_outline_rounded))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          _QuietRow(
            icon: Icons.tag_rounded,
            label: 'OSM',
            value:
                '${station.osmType} #${station.osmId} • ${station.id}',
            maxLines: 1,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDirections,
              style: FilledButton.styleFrom(
                backgroundColor: VehicleUi.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_rounded, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'Bắt đầu điều hướng',
                    style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bề mặt nổi • tương tác kéo lên',
            style: TextStyle(
              color: VehicleUi.textMuted.withValues(alpha: 0.75),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh HUD tạm khi đang tính tuyến (trước khi có polyline OSRM).
class _NavigationComputingCard extends StatelessWidget {
  final String destinationName;
  final VoidCallback onClose;

  const _NavigationComputingCard({
    required this.destinationName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: VehicleUi.card.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: VehicleUi.glassBorder),
          boxShadow: VehicleUi.floatingShadowNear,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: VehicleUi.accentBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Đang tính tuyến…',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destinationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: VehicleUi.textMuted.withValues(alpha: 0.95),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              tooltip: 'Hủy',
            ),
          ],
        ),
      ),
    );
  }
}

class _QuietRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const _QuietRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: VehicleUi.textMuted.withValues(alpha: 0.9)),
        const SizedBox(width: 10),
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: TextStyle(
              color: VehicleUi.textMuted.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}
