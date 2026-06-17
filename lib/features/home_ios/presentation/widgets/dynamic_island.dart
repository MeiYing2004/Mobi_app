import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:provider/provider.dart';



import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';

import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';

import 'package:fuel_tracker_app/features/home_ios/data/ios_system_bridge.dart';

import 'package:fuel_tracker_app/features/location/data/services/location_service.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_typography.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_spring_widgets.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_status_bar.dart';



enum _IslandMode { collapsed, navigation, fuelWarning, gasStation, gps }



/// Dynamic Island — pill đen ở giữa status bar.

class DynamicIsland extends StatelessWidget {

  const DynamicIsland({

    super.key,

    required this.metrics,

    this.forceExpanded = false,

    this.compact = false,

  });



  final IosHomeMetrics metrics;

  final bool forceExpanded;

  final bool compact;



  @override

  Widget build(BuildContext context) {

    return RepaintBoundary(

      child: _DynamicIslandBody(

        metrics: metrics,

        forceExpanded: forceExpanded,

        compact: compact,

      ),

    );

  }

}



class _DynamicIslandBody extends StatelessWidget {

  const _DynamicIslandBody({

    required this.metrics,

    required this.forceExpanded,

    required this.compact,

  });



  final IosHomeMetrics metrics;

  final bool forceExpanded;

  final bool compact;



  _IslandMode _resolveMode({

    required IosSystemBridge bridge,

    required FuelService fuel,

    required LocationService location,

  }) {

    if (bridge.isNavigating) return _IslandMode.navigation;

    if (fuel.isLowFuel) return _IslandMode.fuelWarning;

    if (bridge.nearestStation != null) return _IslandMode.gasStation;

    if (location.permissionError != null || location.currentPosition == null) {

      return _IslandMode.gps;

    }

    return _IslandMode.collapsed;

  }



  @override

  Widget build(BuildContext context) {

    final bridge = context.watch<IosSystemBridge>();

    final fuel = context.watch<FuelService>();

    final location = context.watch<LocationService>();

    final mode = forceExpanded

        ? _IslandMode.fuelWarning

        : _resolveMode(bridge: bridge, fuel: fuel, location: location);

    final expanded = !compact && (mode != _IslandMode.collapsed || forceExpanded);



    final width = expanded
        ? metrics.islandWidth * 1.52
        : metrics.islandWidth * (compact ? 1.0 : 1.0);

    final height = expanded
        ? metrics.islandHeight * 1.42
        : metrics.islandHeight;



    return IosSpringSizeBox(
      width: width,
      height: height,
      builder: (context, w, h) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(h / 2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A1C),
                Color(0xFF000000),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
              width: 0.65,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: h * 0.24,
                offset: Offset(0, h * 0.07),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: h * 0.14,
                offset: Offset(0, -h * 0.03),
              ),
            ],
          ),
          child: Container(
            width: w,
            height: h,
            padding: EdgeInsets.symmetric(horizontal: w * 0.07),
            child: expanded
                ? _ExpandedContent(
                    mode: mode,
                    fuel: fuel,
                    bridge: bridge,
                    location: location,
                    height: h,
                  )
                : compact
                    ? _CompactIslandSensors(width: w, height: h)
                    : null,
          ),
        );
      },
    );

  }

}



class _ExpandedContent extends StatelessWidget {

  const _ExpandedContent({

    required this.mode,

    required this.fuel,

    required this.bridge,

    required this.location,

    required this.height,

  });



  final _IslandMode mode;

  final FuelService fuel;

  final IosSystemBridge bridge;

  final LocationService location;

  final double height;



  @override

  Widget build(BuildContext context) {

    return Row(

      children: [

        Icon(_icon, color: _color, size: height * 0.38),

        SizedBox(width: height * 0.18),

        Expanded(

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                _title,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: IosTypography.widgetTitle(height * 0.26).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),

              ),

              if (_subtitle.isNotEmpty)

                Text(

                  _subtitle,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: IosTypography.widgetBody(height * 0.2).copyWith(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),

                ),

            ],

          ),

        ),

        if (mode == _IslandMode.navigation)

          SizedBox(

            width: height * 0.55,

            height: height * 0.55,

            child: CircularProgressIndicator(

              value: bridge.navigation?.progress ?? 0,

              strokeWidth: 2.5,

              color: VehicleUi.accentBlue,

              backgroundColor: Colors.white24,

            ),

          ),

      ],

    ).animate(key: ValueKey(mode)).fadeIn(duration: 220.ms);

  }



  IconData get _icon => switch (mode) {

        _IslandMode.navigation => Icons.navigation_rounded,

        _IslandMode.fuelWarning => Icons.warning_amber_rounded,

        _IslandMode.gasStation => Icons.local_gas_station_rounded,

        _IslandMode.gps => Icons.gps_off_rounded,

        _ => Icons.local_gas_station_rounded,

      };



  Color get _color => switch (mode) {

        _IslandMode.fuelWarning => VehicleUi.warningRed,

        _IslandMode.gps => Colors.orangeAccent,

        _ => VehicleUi.accentBlue,

      };



  String get _title => switch (mode) {

        _IslandMode.navigation =>

          bridge.navigation?.destinationName ?? 'Đang điều hướng',

        _IslandMode.fuelWarning => 'Nhiên liệu thấp',

        _IslandMode.gasStation =>

          bridge.nearestStation?.name ?? 'Trạm xăng gần nhất',

        _IslandMode.gps => location.permissionError ?? 'Đang tìm GPS...',

        _ => 'Fuel Tracker',

      };



  String get _subtitle => switch (mode) {

        _IslandMode.navigation =>

          'Còn ${bridge.navigation?.remainingDistanceKm.toStringAsFixed(1)} km · ETA ${bridge.navigation?.etaLabel ?? ''}',

        _IslandMode.fuelWarning =>

          '${fuel.fuelPercent.round()}% · ${fuel.safeRemainingDistanceKm.round()} km còn lại',

        _IslandMode.gasStation =>

          '${bridge.nearestStation?.distanceKm.toStringAsFixed(1)} km · ${bridge.nearestStation?.brand ?? ''}',

        _IslandMode.gps => 'Bật vị trí để theo dõi nhiên liệu',

        _ => '',

      };

}



/// Cảm biến Face ID + camera trong Dynamic Island thu gọn.
class _CompactIslandSensors extends StatelessWidget {
  const _CompactIslandSensors({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: height * 0.22,
          height: height * 0.22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A1C),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        SizedBox(width: width * 0.38),
        Container(
          width: height * 0.34,
          height: height * 0.34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFF2C2C2E),
                Color(0xFF0A0A0B),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Header Home — status bar + island tích hợp.

class IosHomeHeader extends StatelessWidget {
  const IosHomeHeader({
    super.key,
    required this.metrics,
    this.islandExpanded = false,
    this.isLight = false,
  });

  final IosHomeMetrics metrics;
  final bool islandExpanded;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    if (islandExpanded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IosStatusBar(
            metrics: metrics,
            isLight: isLight,
            showIsland: false,
          ),
          SizedBox(height: metrics.screenHeight * 0.004),
          DynamicIsland(metrics: metrics, forceExpanded: islandExpanded),
        ],
      );
    }

    return IosStatusBar(metrics: metrics, isLight: isLight);
  }
}


