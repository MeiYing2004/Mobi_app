import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/osm_config.dart';
import '../../../core/vehicle_ui_tokens.dart';
import '../../../intelligence/prediction/fuel_prediction_models.dart';
import '../../../models/gas_station.dart';

class FuelIntelligenceMiniMap extends StatefulWidget {
  final LatLng? userLocation;
  final List<LatLng> routePoints;
  final LatLng? emptyPoint;
  final List<GasStation> stations;
  final GasStation? emergencyStation;
  final RouteRiskLevel? riskLevel;
  final double fuelPercent;

  const FuelIntelligenceMiniMap({
    super.key,
    required this.userLocation,
    required this.routePoints,
    required this.emptyPoint,
    required this.stations,
    required this.emergencyStation,
    required this.riskLevel,
    required this.fuelPercent,
  });

  @override
  State<FuelIntelligenceMiniMap> createState() => _FuelIntelligenceMiniMapState();
}

class _FuelIntelligenceMiniMapState extends State<FuelIntelligenceMiniMap>
    with SingleTickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController =
      AnimatedMapController(vsync: this);
  MapController get _mapController => _animatedMapController.mapController;

  bool _follow = true;
  late final AnimationController _routePulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat();

  @override
  void didUpdateWidget(covariant FuelIntelligenceMiniMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final p = widget.userLocation;
    final op = oldWidget.userLocation;
    if (!_follow) return;
    if (p != null && (op == null || _movedEnough(op, p))) {
      final distanceM = op == null
          ? 0.0
          : const Distance().as(LengthUnit.Meter, op, p);
      final motionT = (distanceM / 28.0).clamp(0.0, 1.0);
      _animatedMapController.animateTo(
        dest: p,
        zoom: _mapController.camera.zoom,
        rotation: 0,
        duration: Duration(milliseconds: (360 + (360 * motionT)).round()),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _movedEnough(LatLng a, LatLng b) {
    final d = const Distance().as(LengthUnit.Meter, a, b);
    return d > 10;
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.userLocation ?? AppConstantsFallback.center;
    final t = _routePulse.value;
    final pulse = (0.6 + 0.4 * math.sin(t * math.pi * 2)).clamp(0.0, 1.0);
    final routeColor = _routeColor(widget.riskLevel);
    final lowFuelTension = ((40 - widget.fuelPercent) / 40).clamp(0.0, 1.0);

    final markers = <Marker>[
      if (widget.userLocation != null)
        Marker(
          point: widget.userLocation!,
          width: 54,
          height: 54,
          child: const _UserPulseMarker(
            key: ValueKey('userPulse'),
          ),
        ),
      for (final s in widget.stations.take(18))
        Marker(
          point: s.location,
          width: 38,
          height: 38,
          child: _StationMarker(
            key: ValueKey('station:${s.id}:${s.distanceKm.toStringAsFixed(2)}'),
            highlight: widget.emergencyStation?.id == s.id,
          ),
        ),
      if (widget.emptyPoint != null)
        Marker(
          point: widget.emptyPoint!,
          width: 44,
          height: 44,
          child: const _EmptyPointMarker(
            key: ValueKey('emptyPoint'),
          ),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15.8,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture && _follow) {
                    setState(() => _follow = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: OsmConfig.darkTileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.mobiapp.fuel_tracker_app',
                ),
                if (widget.routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.routePoints,
                        strokeWidth: 6.4 + (0.8 * lowFuelTension),
                        color: routeColor
                            .withValues(alpha: (0.15 + 0.1 * pulse).clamp(0.0, 0.3)),
                      ),
                      Polyline(
                        points: widget.routePoints,
                        strokeWidth: 3.4 + (0.4 * lowFuelTension),
                        color: routeColor.withValues(alpha: 0.92),
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.22),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _FollowButton(
                active: _follow,
                onTap: () {
                  setState(() => _follow = true);
                  final p = widget.userLocation;
                  if (p == null) return;
                  _animatedMapController.animateTo(
                    dest: p,
                    zoom: 15.8,
                    rotation: 0,
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _routeColor(RouteRiskLevel? risk) {
    return switch (risk) {
      RouteRiskLevel.safe => const Color(0xFF19D3FF),
      RouteRiskLevel.moderate => const Color(0xFFFFD166),
      RouteRiskLevel.risky => const Color(0xFFFF9F1C),
      RouteRiskLevel.critical => const Color(0xFFFF5A36),
      null => const Color(0xFF19D3FF),
    };
  }

  @override
  void dispose() {
    _routePulse.dispose();
    _animatedMapController.dispose();
    super.dispose();
  }
}

class _UserPulseMarker extends StatelessWidget {
  const _UserPulseMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VehicleUi.accentBlue.withValues(alpha: 0.16),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 0.85, end: 1.3, duration: 1700.ms)
            .fadeOut(begin: 0.7, duration: 1700.ms),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: VehicleUi.accentBlue.withValues(alpha: 0.9),
              width: 3.2,
            ),
            boxShadow: [
              BoxShadow(
                color: VehicleUi.accentBlue.withValues(alpha: 0.18),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StationMarker extends StatelessWidget {
  final bool highlight;

  const _StationMarker({super.key, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFFFFB020) : const Color(0xFFEA4335);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: highlight ? Border.all(color: color, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: highlight ? 12 : 6,
            offset: const Offset(0, 2),
          ),
          if (highlight)
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      padding: EdgeInsets.all(highlight ? 8 : 6),
      child: Icon(
        Icons.local_gas_station_rounded,
        color: color,
        size: highlight ? 22 : 20,
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms, curve: Curves.easeOutCubic)
        .scaleXY(begin: 0.92, end: 1.0, duration: 320.ms, curve: Curves.easeOutBack);
  }
}

class _EmptyPointMarker extends StatelessWidget {
  const _EmptyPointMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -math.pi / 8,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.5),
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
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
          begin: 0.96,
          end: 1.04,
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _FollowButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FollowButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = active ? VehicleUi.accentBlue : Colors.white70;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            shape: BoxShape.circle,
            border: Border.all(color: c.withValues(alpha: 0.28)),
          ),
          child: Icon(
            Icons.my_location_rounded,
            size: 16,
            color: c.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

class AppConstantsFallback {
  static const center = LatLng(21.0285, 105.8542);
}

