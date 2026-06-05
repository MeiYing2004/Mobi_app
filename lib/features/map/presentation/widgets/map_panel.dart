import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import 'package:fuel_tracker_app/core/config/constants.dart';
import 'package:fuel_tracker_app/core/ios_design_tokens.dart';
import 'package:fuel_tracker_app/core/config/lan_dev_config.dart';
import 'package:fuel_tracker_app/features/map/core/map_style.dart';
import 'package:fuel_tracker_app/core/config/osm_config.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/gas_station.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/trip_fuel_status.dart';
import 'package:fuel_tracker_app/features/location/data/services/location_service.dart';

/// Bản đồ OpenStreetMap — dark mode, cluster cây xăng, tuyến đỏ OSRM.
class MapPanel extends StatelessWidget {
  final MapController mapController;
  final LocationService locationService;
  final LatLng mapTarget;
  final bool hasPosition;
  final List<GasStation> gasStations;
  final bool lowFuel;
  final MapVisualStyle visualStyle;
  final bool navigationMode;
  final VoidCallback? onMapReady;
  final VoidCallback? onUserPanStarted;
  final void Function(GasStation station)? onStationTap;
  final List<LatLng>? routePolyline;
  /// Đường tạm (GPS → đích) khi OSRM đang tính.
  final List<LatLng>? routePreviewPolyline;
  final LatLng? fuelEmptyPoint;
  final GasStation? activeDestination;
  final double? rangeCircleKm;
  final TripFuelStatus? rangeStatus;
  final String? highlightedStationId;
  final bool loadingStations;

  const MapPanel({
    super.key,
    required this.mapController,
    required this.locationService,
    required this.mapTarget,
    required this.hasPosition,
    this.gasStations = const [],
    this.lowFuel = false,
    this.visualStyle = MapVisualStyle.dark,
    this.navigationMode = false,
    this.onMapReady,
    this.onUserPanStarted,
    this.onStationTap,
    this.routePolyline,
    this.routePreviewPolyline,
    this.fuelEmptyPoint,
    this.activeDestination,
    this.rangeCircleKm,
    this.rangeStatus,
    this.highlightedStationId,
    this.loadingStations = false,
  });

  // Muted navigation tone: cinematic but understated.
  static const _routeRed = Color(0xFFE35B53);

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isLight = b == Brightness.light;
    final dest = activeDestination;
    final gasMarkers = gasStations
        .where((s) => !_isDestinationStation(s, dest))
        .map((s) {
      final isHighlight =
          highlightedStationId != null && highlightedStationId == s.id;
      return Marker(
        point: s.location,
        width: isHighlight ? 48 : 40,
        height: isHighlight ? 48 : 40,
        child: GestureDetector(
          onTap: () => onStationTap?.call(s),
          child: _GasMarkerIcon(
            isHighlighted: isHighlight,
            brand: s.brand,
          ),
        ),
      );
    }).toList();

    final overlayMarkers = <Marker>[
      if (hasPosition)
        Marker(
          point: LatLng(
            locationService.currentPosition!.latitude,
            locationService.currentPosition!.longitude,
          ),
          width: 52,
          height: 52,
          alignment: Alignment.center,
          child: _UserLocationMarker(
            color: lowFuel ? IosDesign.warningRed : VehicleUi.accentBlue,
            bearing: locationService.bearing,
            navigationMode: navigationMode,
          ),
        ),
      if (fuelEmptyPoint != null)
        Marker(
          point: fuelEmptyPoint!,
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: _FuelEmptyMarker(),
        ),
      if (dest != null)
        Marker(
          point: dest.location,
          width: 52,
          height: 66,
          alignment: Alignment.bottomCenter,
          child: _DestinationPinMarker(
            key: ValueKey(
              '${dest.location.latitude.toStringAsFixed(5)},'
              '${dest.location.longitude.toStringAsFixed(5)}',
            ),
          ),
        ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base map grading (separate light/dark environments).
        ColorFiltered(
          colorFilter: isLight
              ? const ColorFilter.matrix([
                  1.08, 0, 0, 0, 18, // lift exposure
                  0, 1.08, 0, 0, 18,
                  0, 0, 1.06, 0, 14, // subtle cool tint
                  0, 0, 0, 1, 0,
                ])
              : const ColorFilter.matrix([
                  0.9, 0.04, 0.04, 0, 10, // r (cool + desat)
                  0.04, 0.9, 0.03, 0, 10, // g (cool + desat)
                  0.04, 0.04, 0.9, 0, 12, // b (subtle cool tint)
                  0, 0, 0, 1, 0, // a
                ]),
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: mapTarget,
              initialZoom: AppConstants.mapZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapReady: onMapReady,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) onUserPanStarted?.call();
              },
            ),
            children: [
              _tileLayerForStyle(isLight && visualStyle == MapVisualStyle.dark
                  ? MapVisualStyle.standard
                  : visualStyle),
              if (hasPosition &&
                  rangeCircleKm != null &&
                  rangeCircleKm! > 0 &&
                  rangeStatus != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        locationService.currentPosition!.latitude,
                        locationService.currentPosition!.longitude,
                      ),
                      radius: rangeCircleKm! * 1000,
                      useRadiusInMeter: true,
                      color: rangeStatus!.circleFill.withValues(alpha: 0.10),
                      borderColor:
                          rangeStatus!.circleBorder.withValues(alpha: 0.55),
                      borderStrokeWidth: 2.2,
                    ),
                  ],
                ),
              if (routePreviewPolyline != null &&
                  routePreviewPolyline!.length >= 2 &&
                  (routePolyline == null || routePolyline!.length < 2))
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePreviewPolyline!,
                      strokeWidth: 4.5,
                      color: _routeRed.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              if (routePolyline != null && routePolyline!.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePolyline!,
                      strokeWidth: 7.0,
                      color: _routeRed.withValues(alpha: 0.22),
                    ),
                    Polyline(
                      points: routePolyline!,
                      strokeWidth: 4.0,
                      color: _routeRed.withValues(alpha: 0.92),
                      borderColor: Colors.white.withValues(alpha: 0.68),
                      borderStrokeWidth: 1.1,
                    ),
                  ],
                ),
              if (gasMarkers.isNotEmpty)
                (routePolyline != null && routePolyline!.length >= 2)
                    ? MarkerLayer(markers: gasMarkers)
                    : MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 50,
                          size: const Size(42, 42),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(48),
                          markers: gasMarkers,
                          builder: (context, markers) {
                            return Container(
                              decoration: BoxDecoration(
                                color: VehicleUi.accentBlue.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  width: 1.3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: VehicleUi.accentBlueGlow,
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${markers.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              MarkerLayer(markers: overlayMarkers),
            ],
          ),
        ).animate().fadeIn(duration: 430.ms, curve: Curves.easeOutCubic),
        // Map contrast scrim + subtle edge depth.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: VehicleUi.mapContrastFor(b)),
          ),
        ),
        if (!isLight)
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: VehicleUi.screenVignette,
              ),
            ),
          ),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: VehicleUi.ambientRadialGlowFor(b),
            ),
          ),
        ),
        if (!hasPosition)
          ColoredBox(
            color: (isLight ? Colors.white : Colors.black)
                .withValues(alpha: isLight ? 0.55 : 0.28),
            child: const Center(
              child: CircularProgressIndicator(color: VehicleUi.accentBlue),
            ),
          ),
        if (loadingStations)
          Positioned(
            top: 108,
            left: 20,
            right: 20,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VehicleUi.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Đang tải trạm xăng...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static TileLayer _tileLayerForStyle(MapVisualStyle style) {
    final useProxy = LanDevConfig.useDevProxy;
    switch (style) {
      case MapVisualStyle.dark:
        return TileLayer(
          key: const ValueKey(MapVisualStyle.dark),
          urlTemplate: OsmConfig.darkTileUrl,
          subdomains: useProxy ? const [] : const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.mobiapp.fuel_tracker_app',
        );
      case MapVisualStyle.standard:
        return TileLayer(
          key: const ValueKey(MapVisualStyle.standard),
          urlTemplate: OsmMapTiles.cartoVoyager,
          subdomains: useProxy ? const [] : const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.mobiapp.fuel_tracker_app',
        );
      case MapVisualStyle.satellite:
        return TileLayer(
          key: const ValueKey(MapVisualStyle.satellite),
          urlTemplate: OsmMapTiles.esriWorldImagery,
          userAgentPackageName: 'com.mobiapp.fuel_tracker_app',
        );
      case MapVisualStyle.terrain:
        return TileLayer(
          key: const ValueKey(MapVisualStyle.terrain),
          urlTemplate: OsmMapTiles.openTopoMap,
          subdomains: useProxy ? const [] : const ['a', 'b', 'c'],
          userAgentPackageName: 'com.mobiapp.fuel_tracker_app',
        );
    }
  }
}

bool _isDestinationStation(GasStation station, GasStation? destination) {
  if (destination == null) return false;
  if (station.id == destination.id) return true;
  return const Distance().as(
        LengthUnit.Meter,
        station.location,
        destination.location,
      ) <
      50;
}

/// Pin đích premium — gradient, bóng đổ, bo tròn kiểu Apple Maps / Uber.
class _DestinationPinMarker extends StatelessWidget {
  const _DestinationPinMarker({super.key});

  static const _baseWidth = 40.0;
  static const _baseHeight = 52.0;

  static double _scaleFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 393.0).clamp(0.88, 1.22);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scaleFor(context);
    final width = _baseWidth * scale;
    final height = _baseHeight * scale;
    final hub = width * 0.36;

    final marker = RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 1,
              child: CustomPaint(
                size: Size(width * 0.52, height * 0.1),
                painter: const _DestinationGroundShadowPainter(),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: const _PremiumDestinationPinPainter(),
                child: Align(
                  alignment: const Alignment(0, -0.2),
                  child: Container(
                    width: hub,
                    height: hub,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 4 * scale,
                          offset: Offset(0, 1.5 * scale),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.place_rounded,
                      size: hub * 0.58,
                      color: MapPanel._routeRed,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return marker
        .animate()
        .scale(
          begin: const Offset(0.55, 0.55),
          end: const Offset(1, 1),
          duration: 460.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 220.ms, curve: Curves.easeOut);
  }
}

class _PremiumDestinationPinPainter extends CustomPainter {
  const _PremiumDestinationPinPainter();

  static const _gradientColors = [
    Color(0xFFFF9A94),
    Color(0xFFE35B53),
    Color(0xFFB83D38),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final path = _pinPath(size);
    final bounds = path.getBounds();

    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.38),
      7,
      false,
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _gradientColors,
          stops: [0.0, 0.52, 1.0],
        ).createShader(bounds),
    );

    final headCenter = Offset(size.width / 2, size.height * 0.34);
    canvas.drawCircle(
      Offset(headCenter.dx - size.width * 0.11, headCenter.dy - size.height * 0.08),
      size.width * 0.11,
      Paint()..color = Colors.white.withValues(alpha: 0.24),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  ui.Path _pinPath(Size size) {
    final w = size.width;
    final h = size.height;
    final tip = Offset(w / 2, h - 1.5);
    final headRadius = w * 0.41;
    final headCenterY = headRadius + h * 0.05;

    return ui.Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(
        w * 0.1,
        h * 0.7,
        w * 0.12,
        headCenterY + headRadius * 0.15,
        w / 2 - headRadius,
        headCenterY,
      )
      ..arcToPoint(
        Offset(w / 2 + headRadius, headCenterY),
        radius: Radius.circular(headRadius),
        clockwise: true,
      )
      ..cubicTo(
        w * 0.88,
        headCenterY + headRadius * 0.15,
        w * 0.9,
        h * 0.7,
        tip.dx,
        tip.dy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant _PremiumDestinationPinPainter oldDelegate) =>
      false;
}

class _DestinationGroundShadowPainter extends CustomPainter {
  const _DestinationGroundShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
  }

  @override
  bool shouldRepaint(covariant _DestinationGroundShadowPainter oldDelegate) =>
      false;
}

class _GasMarkerIcon extends StatelessWidget {
  final bool isHighlighted;
  final String brand;

  const _GasMarkerIcon({
    this.isHighlighted = false,
    this.brand = 'Fuel',
  });

  Color get _accent {
    if (isHighlighted) return const Color(0xFFFFB020);
    final b = brand.toLowerCase();
    if (b.contains('petrolimex')) return const Color(0xFF00A651);
    if (b.contains('pvoil')) return const Color(0xFF0066B3);
    if (b.contains('comeco') || b.contains('mipec')) return const Color(0xFFE11D48);
    return const Color(0xFFEA4335);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isHighlighted ? _accent : Colors.transparent,
          width: isHighlighted ? 3 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: isHighlighted ? 0.55 : 0.25),
            blurRadius: isHighlighted ? 14 : 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isHighlighted ? 8 : 6),
      child: Icon(
        Icons.local_gas_station_rounded,
        color: _accent,
        size: isHighlighted ? 24 : 20,
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  final Color color;
  final double bearing;
  final bool navigationMode;

  const _UserLocationMarker({
    required this.color,
    required this.bearing,
    required this.navigationMode,
  });

  @override
  Widget build(BuildContext context) {
    if (navigationMode) {
      return Transform.rotate(
        angle: bearing * math.pi / 180,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: VehicleUi.accentBlue.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: VehicleUi.accentBlueGlow,
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(0.86, 0.86),
              end: const Offset(1.28, 1.28),
              duration: 1700.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeOut(begin: 0.65, delay: 160.ms, duration: 1350.ms),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color.withValues(alpha: 0.75), width: 3.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 0.96,
              end: 1.0,
              duration: 2100.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}

class _FuelEmptyMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const danger = IosDesign.warningRed;
    const warn = Color(0xFFFFB020);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: danger.withValues(alpha: 0.14),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(
              begin: 0.84,
              end: 1.32,
              duration: 1600.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeOut(begin: 0.65, duration: 1600.ms),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                warn.withValues(alpha: 0.95),
                danger.withValues(alpha: 0.95),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: danger.withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: Colors.white,
            size: 22,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 0.98,
              end: 1.04,
              duration: 1100.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}
