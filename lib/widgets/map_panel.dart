import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../core/ios_design_tokens.dart';
import '../core/map_style.dart';
import '../core/osm_config.dart';
import '../core/vehicle_ui_tokens.dart';
import '../models/gas_station.dart';
import '../models/place_model.dart';
import '../services/location_service.dart';

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
  final LatLng? fuelEmptyPoint;
  final GasStation? activeDestination;
  final PlaceDetails? searchedPlace;

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
    this.fuelEmptyPoint,
    this.activeDestination,
    this.searchedPlace,
  });

  // Muted navigation tone: cinematic but understated.
  static const _routeRed = Color(0xFFE35B53);

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isLight = b == Brightness.light;
    final gasMarkers = gasStations.map((s) {
      final isDest = activeDestination?.id == s.id;
      return Marker(
        point: s.location,
        width: isDest ? 48 : 40,
        height: isDest ? 48 : 40,
        child: GestureDetector(
          onTap: () => onStationTap?.call(s),
          child: _GasMarkerIcon(isDestination: isDest),
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
      if (searchedPlace != null)
        Marker(
          point: searchedPlace!.location,
          width: 46,
          height: 46,
          alignment: Alignment.center,
          child: const _SearchedPlaceMarker(),
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
                MarkerClusterLayerWidget(
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
                          boxShadow: [
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
      ],
    );
  }

  static TileLayer _tileLayerForStyle(MapVisualStyle style) {
    switch (style) {
      case MapVisualStyle.dark:
        return TileLayer(
          key: const ValueKey(MapVisualStyle.dark),
          urlTemplate: OsmConfig.darkTileUrl,
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.mobiapp.fuel_tracker_app',
        );
      case MapVisualStyle.standard:
        return TileLayer(
          key: const ValueKey(MapVisualStyle.standard),
          urlTemplate: OsmMapTiles.cartoVoyager,
          subdomains: const ['a', 'b', 'c', 'd'],
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
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.mobiapp.fuel_tracker_app',
        );
    }
  }
}

class _GasMarkerIcon extends StatelessWidget {
  final bool isDestination;

  const _GasMarkerIcon({required this.isDestination});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: isDestination
            ? Border.all(color: MapPanel._routeRed, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: isDestination ? 10 : 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(isDestination ? 8 : 6),
      child: Icon(
        Icons.local_gas_station_rounded,
        color: isDestination ? MapPanel._routeRed : const Color(0xFFEA4335),
        size: isDestination ? 24 : 20,
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
            boxShadow: [
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

class _SearchedPlaceMarker extends StatelessWidget {
  const _SearchedPlaceMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: VehicleUi.accentBlueGlow,
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: VehicleUi.accentBlue,
        ),
        child: Center(
          child: Icon(Icons.place_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
