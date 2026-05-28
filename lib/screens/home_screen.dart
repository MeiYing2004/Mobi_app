import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/interaction_controller.dart';
import '../core/ios_design_tokens.dart';
import '../core/map_style.dart';
import '../core/micro_motion_spec.dart';
import '../core/motion_director.dart';
import '../core/vehicle_ui_tokens.dart';
import '../models/fuel_warning_event.dart';
import '../models/gas_station.dart';
import '../models/navigation_route.dart';
import '../models/place_model.dart';
import '../services/directions_service.dart';
import '../services/fuel_service.dart';
import '../services/gas_station_service.dart';
import '../services/location_service.dart';
import '../services/route_fuel_service.dart';
import '../services/search_service.dart';
import '../widgets/ios_style_widgets.dart';
import '../widgets/map_panel.dart';
import '../widgets/navigation_hud.dart';
import '../widgets/quick_action_chips.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/vehicle_bottom_nav.dart';
import '../widgets/vehicle_dashboard_panel.dart';
import '../widgets/cinematic_sheet.dart';
import '../features/fuel_intelligence/screens/fuel_intelligence_screen.dart';

/// Shell navigation OSM — search, fuel dashboard, chỉ đường OSRM.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(vsync: this);
  MapController get _mapController => _animatedMapController.mapController;

  LocationService? _locationService;
  FuelService? _fuelService;
  final GasStationService _gasStationService = GasStationService();
  final DirectionsService _directionsService = const DirectionsService();
  final RouteFuelService _routeFuelService = const RouteFuelService();
  final SearchService _searchService = SearchService();

  bool _followUser = true;
  bool _navigationFollow = false;
  bool _mapReady = false;
  bool _loadingRoute = false;
  NavigationRoute? _activeRoute;
  PlaceDetails? _searchedPlace;
  List<GasStation> _stations = [];
  MapVisualStyle _mapStyle = MapVisualStyle.dark;
  int _navIndex = 0;
  bool _dashboardCollapsed = false;
  String _profileName = 'Minh Hoàng';
  String _profileVehicle = 'Kawasaki Ninja 400';
  String _profileAvatar = '🏍️';
  late final MotionDirector _motionDirector;
  late final InteractionController _interactionController;

  @override
  void initState() {
    super.initState();
    _motionDirector = MotionDirector(vsync: this);
    _interactionController = InteractionController(
      motionDirector: _motionDirector,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locationService ??= context.read<LocationService>()
      ..addListener(_onLocationChanged);
    _fuelService ??= context.read<FuelService>()
      ..onLowFuelWarning = _onLowFuelWarning;

    _locationService!.onDistanceTraveled =
        _fuelService!.consumeDistanceMeters;
    _loadGasStations();
  }

  void _onLocationChanged() {
    if (_activeRoute != null && _navigationFollow) {
      _followNavigationCamera();
    } else if (_followUser) {
      _animateToUser();
    }
    _loadGasStations();
  }

  Future<void> _loadGasStations() async {
    final pos = _locationService?.currentPosition;
    final origin = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : AppConstants.defaultVietnamLocation;
    final list = await _gasStationService.findNearestStations(origin: origin);
    if (mounted) setState(() => _stations = list);
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

  void _followNavigationCamera() {
    if (!_mapReady) return;
    final pos = _locationService?.currentPosition;
    if (pos == null) return;
    _animatedMapController.animateTo(
      dest: LatLng(pos.latitude, pos.longitude),
      zoom: 17.5,
      rotation: -_locationService!.bearing,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _onLowFuelWarning(FuelWarningEvent event) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: IosDesign.warningRed.withValues(alpha: 0.92),
        content: Text(event.message),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      ),
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

  Future<void> _startNavigation(GasStation station) async {
    final pos = _locationService?.currentPosition;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần GPS để chỉ đường')),
      );
      return;
    }

    final fuel = context.read<FuelService>();

    setState(() {
      _loadingRoute = true;
      _activeRoute = null;
    });

    try {
      final origin = LatLng(pos.latitude, pos.longitude);
      final directions = await _directionsService.fetchRoute(
        origin: origin,
        destination: station.location,
      );
      final analysis = _routeFuelService.analyze(
        routePoints: directions.points,
        routeDistanceKm: directions.distanceKm,
        fuel: fuel,
        destination: station,
        nearbyStations: _stations,
      );
      final eta =
          DateTime.now().add(Duration(seconds: directions.durationSeconds));
      final route = NavigationRoute(
        destination: station,
        polylinePoints: directions.points,
        distanceKm: directions.distanceKm,
        durationSeconds: directions.durationSeconds,
        eta: eta,
        fuelAnalysis: analysis,
      );

      if (!mounted) return;
      setState(() {
        _activeRoute = route;
        _loadingRoute = false;
        _navigationFollow = false;
        _followUser = true;
      });
      _interactionController.activateNavigation();
      _fitRouteOnMap(directions.points);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRoute = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lấy được tuyến: $e')),
      );
    }
  }

  void _clearNavigation() {
    setState(() {
      _activeRoute = null;
      _navigationFollow = false;
      _followUser = true;
    });
    _interactionController.deactivateNavigation();
    _animateToUser();
  }

  void _animateTo(LatLng target, {double zoom = 16.8}) {
    if (!_mapReady) return;
    _animatedMapController.animateTo(
      dest: target,
      zoom: zoom,
      rotation: 0,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPlaceSelected(PlaceDetails place) {
    setState(() {
      _searchedPlace = place;
      _activeRoute = null;
      _loadingRoute = false;
      _followUser = false;
    });

    _animateTo(place.location, zoom: 16.8);
    _openPlaceSheet(place);
  }

  void _openPlaceSheet(PlaceDetails place) {
    final pos = _locationService?.currentPosition;
    final origin = pos != null ? LatLng(pos.latitude, pos.longitude) : null;
    final km = origin != null
        ? const Distance().as(LengthUnit.Kilometer, origin, place.location)
        : null;

    _interactionController.openSheet();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (ctx) {
        return CinematicSheet(
          initialExtent: 0.42,
          minExtent: 0.30,
          maxExtent: 0.78,
          motionDirector: _motionDirector,
          onExtent: (e) => _interactionController.expandSheet(
            ((e - 0.30) / (0.78 - 0.30)).clamp(0.0, 1.0),
          ),
          builder: (context, scroll, extent) => _PlaceBottomSheet(
            place: place,
            distanceKm: km,
            scrollController: scroll,
            onDirections: () {
              Navigator.pop(ctx);
              _startNavigationToPlace(place, distanceKm: km);
            },
          ),
        );
      },
    ).whenComplete(() {
      _interactionController.collapseSheet();
    });
  }

  Future<void> _startNavigationToPlace(
    PlaceDetails place, {
    double? distanceKm,
  }) async {
    final pos = _locationService?.currentPosition;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần GPS để chỉ đường')),
      );
      return;
    }

    final fuel = context.read<FuelService>();

    setState(() {
      _loadingRoute = true;
      _activeRoute = null;
    });

    try {
      final origin = LatLng(pos.latitude, pos.longitude);
      final directions = await _directionsService.fetchRoute(
        origin: origin,
        destination: place.location,
      );

      final dest = GasStation(
        id: 'place:${place.placeId}',
        osmType: 'place',
        osmId: place.placeId.hashCode,
        name: place.name.isNotEmpty ? place.name : 'Điểm đến',
        address: place.formattedAddress,
        location: place.location,
        distanceKm: distanceKm ??
            const Distance().as(LengthUnit.Kilometer, origin, place.location),
        brand: 'Place',
      );

      final analysis = _routeFuelService.analyze(
        routePoints: directions.points,
        routeDistanceKm: directions.distanceKm,
        fuel: fuel,
        destination: dest,
        nearbyStations: _stations,
      );

      final eta =
          DateTime.now().add(Duration(seconds: directions.durationSeconds));
      final route = NavigationRoute(
        destination: dest,
        polylinePoints: directions.points,
        distanceKm: directions.distanceKm,
        durationSeconds: directions.durationSeconds,
        eta: eta,
        fuelAnalysis: analysis,
      );

      if (!mounted) return;
      setState(() {
        _activeRoute = route;
        _loadingRoute = false;
        _navigationFollow = false;
        _followUser = true;
      });
      _interactionController.activateNavigation();
      _fitRouteOnMap(directions.points);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRoute = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không lấy được tuyến: $e')),
      );
    }
  }

  void _fitRouteOnMap(List<LatLng> points) {
    if (!_mapReady || points.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.fromLTRB(48, 120, 48, 300),
          ),
        );
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted || _activeRoute == null) return;
          setState(() => _navigationFollow = true);
          _followNavigationCamera();
        });
      } catch (_) {}
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
                      child: Icon(
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
        if (_stations.isNotEmpty) {
          _startNavigation(_stations.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chưa có cây xăng gần bạn')),
          );
          setState(() => _navIndex = 0);
        }
        return;
      case 2:
        FuelIntelligenceScreen.open(context).whenComplete(() {
          if (!mounted) return;
          setState(() => _navIndex = 0);
        });
        return;
      case 3:
        _openSearchHistorySheet().whenComplete(() {
          if (mounted) setState(() => _navIndex = 0);
        });
        return;
      case 4:
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
      builder: (ctx) => _ProfileEditorSheet(
        name: _profileName,
        vehicle: _profileVehicle,
        avatar: _profileAvatar,
        onSave: ({required name, required vehicle, required avatar}) {
          setState(() {
            _profileName = name;
            _profileVehicle = vehicle;
            _profileAvatar = avatar;
          });
          Navigator.pop(ctx);
        },
      ),
    ).whenComplete(() {
      _interactionController.collapseSheet();
    });
  }

  Future<void> _openSearchHistorySheet() {
    _interactionController.openSheet();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SearchHistorySheet(
        initialItems: _searchService.recentPlaces,
        onPick: (place) {
          _searchService.rememberPlace(place);
          Navigator.pop(ctx);
          _onPlaceSelected(place);
        },
        onClear: () {
          _searchService.clearHistory();
        },
      ),
    ).whenComplete(() {
      _interactionController.collapseSheet();
    });
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

    final navigating = _activeRoute != null;
    const navBarHeight = VehicleBottomNav.barHeight;

    // Adaptive layout anchors (match iPhone premium proportions).
    final navBottom = 8.0 + safe.bottom;
    // Add a bit more breathing room between dock and dashboard.
    final statsBottom = navBottom + navBarHeight + 30.0;
    final statsWidth = (screenW * 0.9).clamp(300.0, 500.0);
    final statsHeight = (screenH * (low ? 0.22 : 0.2)).clamp(158.0, 200.0);
    // Keep right-side controls visually detached from dashboard.
    final controlsBottom = statsBottom + statsHeight + 30.0;
    final carBottom = navBottom + navBarHeight + (screenH * 0.1).clamp(88.0, 130.0);
    final fabBottom = navigating ? navBottom + 280 : carBottom + 8;
    final locError = loc.permissionError;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: VehicleUi.surfaceDark,
        body: Stack(
        fit: StackFit.expand,
        children: [
          MapPanel(
            mapController: _mapController,
            locationService: loc,
            mapTarget: mapTarget,
            hasPosition: pos != null,
            gasStations: _stations,
            lowFuel: low,
            visualStyle: _mapStyle,
            routePolyline: _activeRoute?.polylinePoints,
            fuelEmptyPoint: _activeRoute?.fuelAnalysis.emptyPointOnRoute,
            activeDestination: _activeRoute?.destination,
            searchedPlace: _searchedPlace,
            onMapReady: _onMapReady,
            navigationMode: navigating && _navigationFollow,
            onUserPanStarted: () {
              setState(() {
                _followUser = false;
                _navigationFollow = false;
              });
              _interactionController.focusMap();
            },
            onStationTap: _openStationSheet,
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
          if (!navigating && !_loadingRoute)
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (locError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Material(
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
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SearchBarWidget(
                          searchService: _searchService,
                          biasLocation: pos != null
                              ? LatLng(pos.latitude, pos.longitude)
                              : null,
                          onPlaceSelected: _onPlaceSelected,
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
                          child: Text(
                            _profileAvatar,
                            style: const TextStyle(fontSize: 20, height: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                QuickActionChips(
                  items: [
                    QuickActionChipData(
                      label: 'Nhà riêng',
                      icon: Icons.home_outlined,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chưa lưu địa chỉ nhà')),
                      ),
                    ),
                    QuickActionChipData(
                      label: 'Cơ quan',
                      icon: Icons.work_outline_rounded,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chưa lưu địa chỉ cơ quan')),
                      ),
                    ),
                    QuickActionChipData(
                      label: 'Cây xăng',
                      icon: Icons.local_gas_station_outlined,
                      onTap: () {
                        if (_stations.isNotEmpty) {
                          _openStationSheet(_stations.first);
                        }
                      },
                    ),
                    QuickActionChipData(
                      label: 'Quán ăn',
                      icon: Icons.restaurant_outlined,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gõ "quán ăn" trên thanh tìm kiếm'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (!navigating && !_loadingRoute) ...[
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
            // Car button anchored near dock (premium iPhone layout).
            Positioned(
              right: 20,
              bottom: carBottom,
              child: _RouteActionButton(
                onTap: () {
                  if (_stations.isNotEmpty) {
                    _startNavigation(_stations.first);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chưa có cây xăng gần bạn'),
                      ),
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
                            VehicleDashboardPanel(
                              fuel: fuel,
                              lowFuel: low,
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
              child: VehicleBottomNav(
                currentIndex: _navIndex,
                onTap: _onNavTap,
                items: const [
                  VehicleNavItem(icon: Icons.map_outlined, label: 'Bản đồ'),
                  VehicleNavItem(
                    icon: Icons.directions_rounded,
                    label: 'Chỉ đường',
                  ),
                  VehicleNavItem(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Nhiên liệu',
                  ),
                  VehicleNavItem(icon: Icons.history_rounded, label: 'Lịch sử'),
                  VehicleNavItem(
                    icon: Icons.settings_outlined,
                    label: 'Cài đặt',
                  ),
                ],
              ),
            ),
          ],
          if (navigating && _activeRoute != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NavigationHud(
                route: _activeRoute!,
                onClose: _clearNavigation,
                motionDirector: _motionDirector,
                onSwitchCloserStation:
                    _activeRoute!.fuelAnalysis.suggestedCloserStation != null
                        ? () => _startNavigation(
                              _activeRoute!
                                  .fuelAnalysis.suggestedCloserStation!,
                            )
                        : null,
              ),
            ),
          if (navigating)
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
                  _MapControlButton(
                    icon: Icons.fit_screen_outlined,
                    onTap: () => _fitRouteOnMap(_activeRoute!.polylinePoints),
                  ),
                ],
              ),
            ),
          if (_loadingRoute)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: VehicleUi.glassFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VehicleUi.glassBorder),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: VehicleUi.accentBlue),
                      SizedBox(height: 16),
                      Text(
                        'Đang tính tuyến...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (low && !navigating)
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
        ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationService?.removeListener(_onLocationChanged);
    _locationService?.onDistanceTraveled = null;
    _fuelService?.onLowFuelWarning = null;
    _animatedMapController.dispose();
    _interactionController.dispose();
    _motionDirector.dispose();
    super.dispose();
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

class _ProfileEditorSheet extends StatefulWidget {
  final String name;
  final String vehicle;
  final String avatar;
  final void Function({
    required String name,
    required String vehicle,
    required String avatar,
  })
  onSave;

  const _ProfileEditorSheet({
    required this.name,
    required this.vehicle,
    required this.avatar,
    required this.onSave,
  });

  @override
  State<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _SearchHistorySheet extends StatefulWidget {
  final List<PlaceDetails> initialItems;
  final ValueChanged<PlaceDetails> onPick;
  final VoidCallback onClear;

  const _SearchHistorySheet({
    required this.initialItems,
    required this.onPick,
    required this.onClear,
  });

  @override
  State<_SearchHistorySheet> createState() => _SearchHistorySheetState();
}

class _SearchHistorySheetState extends State<_SearchHistorySheet> {
  late List<PlaceDetails> _items = List<PlaceDetails>.from(widget.initialItems);

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
                      'Lịch sử tìm kiếm',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  if (_items.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        widget.onClear();
                        setState(() => _items = const []);
                      },
                      child: const Text('Xóa lịch sử'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_items.isEmpty)
                Text(
                  'Chưa có địa điểm nào trong lịch sử.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, i) {
                      final p = _items[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.history_rounded,
                          color: VehicleUi.accentBlue,
                        ),
                        title: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          p.formattedAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.64),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => widget.onPick(p),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditorSheetState extends State<_ProfileEditorSheet> {
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.name,
  );
  late final TextEditingController _vehicleCtrl = TextEditingController(
    text: widget.vehicle,
  );
  late String _avatar = widget.avatar;

  static const List<String> _avatarChoices = ['🏍️', '🧑‍🚀', '😎', '🔥', '🚗', '🛵'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
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
              const Text(
                'Hồ sơ người dùng',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Tên hiển thị'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _vehicleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Xe đang dùng'),
              ),
              const SizedBox(height: 12),
              Text(
                'Avatar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _avatarChoices
                    .map(
                      (a) => InkWell(
                        onTap: () => setState(() => _avatar = a),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                              color: (_avatar == a
                                      ? VehicleUi.accentBlue
                                      : Colors.white.withValues(alpha: 0.2))
                                  .withValues(alpha: 0.85),
                              width: _avatar == a ? 1.8 : 1.0,
                            ),
                          ),
                          child: Text(a, style: const TextStyle(fontSize: 21)),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final name = _nameCtrl.text.trim().isEmpty
                        ? widget.name
                        : _nameCtrl.text.trim();
                    final vehicle = _vehicleCtrl.text.trim().isEmpty
                        ? widget.vehicle
                        : _vehicleCtrl.text.trim();
                    widget.onSave(name: name, vehicle: vehicle, avatar: _avatar);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: VehicleUi.accentBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lưu hồ sơ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: VehicleUi.accentBlue.withValues(alpha: 0.7)),
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

class _PlaceBottomSheet extends StatelessWidget {
  final PlaceDetails place;
  final double? distanceKm;
  final VoidCallback onDirections;
  final ScrollController scrollController;

  const _PlaceBottomSheet({
    required this.place,
    required this.distanceKm,
    required this.onDirections,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final kmLabel =
        distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km' : null;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
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
                  Icons.place_rounded,
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
                      place.name,
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
                      place.formattedAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: VehicleUi.textMuted.withValues(alpha: 0.92),
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (kmLabel != null) ...[
            const SizedBox(height: 12),
            _QuietRow(
              icon: Icons.near_me_outlined,
              label: 'Khoảng cách',
              value: kmLabel,
              maxLines: 1,
            ),
          ],
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
