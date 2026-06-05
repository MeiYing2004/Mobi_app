import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';
import 'package:fuel_tracker_app/features/location/data/services/location_service.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_spring_widgets.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/wallpaper_widget.dart';

/// Control Center — vuốt từ góc phải trên.
class ControlCenterOverlay extends StatelessWidget {
  const ControlCenterOverlay({
    super.key,
    required this.metrics,
    required this.onDismiss,
  });

  final IosHomeMetrics metrics;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final fuel = context.watch<FuelService>();
    final location = context.watch<LocationService>();

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.2),
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () {},
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: IosSpringSlidePanel(
                child: Container(
                width: metrics.screenWidth,
                padding: EdgeInsets.fromLTRB(
                  metrics.horizontalPadding,
                  metrics.topPadding + 48,
                  metrics.horizontalPadding,
                  24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: metrics.iconSize * 0.24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: metrics.gridSpacing),
                    Wrap(
                      spacing: metrics.gridSpacing,
                      runSpacing: metrics.gridSpacing,
                      children: [
                        _ToggleTile(
                          icon: Icons.wifi_rounded,
                          label: 'Wi‑Fi',
                          active: true,
                          metrics: metrics,
                        ),
                        _ToggleTile(
                          icon: Icons.bluetooth_rounded,
                          label: 'Bluetooth',
                          active: true,
                          metrics: metrics,
                        ),
                        _ToggleTile(
                          icon: Icons.local_gas_station_rounded,
                          label: 'Fuel ${fuel.fuelPercent.round()}%',
                          active: !fuel.isLowFuel,
                          metrics: metrics,
                        ),
                        _ToggleTile(
                          icon: Icons.gps_fixed_rounded,
                          label: location.currentPosition != null ? 'GPS' : 'No GPS',
                          active: location.currentPosition != null,
                          metrics: metrics,
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.gridSpacing),
                    IosGlassPanel(
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.brightness_6_rounded, color: Colors.white),
                          Expanded(
                            child: Slider(
                              value: 0.65,
                              onChanged: (_) {},
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.metrics,
  });

  final IconData icon;
  final String label;
  final bool active;
  final IosHomeMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return IosGlassPanel(
      borderRadius: BorderRadius.circular(18),
      padding: EdgeInsets.all(metrics.iconSize * 0.18),
      child: SizedBox(
        width: metrics.iconCellWidth * 0.95,
        child: Column(
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white54,
                size: metrics.iconSize * 0.32),
            SizedBox(height: metrics.iconSize * 0.08),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: metrics.iconSize * 0.12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
