import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_spring_widgets.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/wallpaper_widget.dart';

/// Notification Center — vuốt từ góc trái trên.
class NotificationCenterOverlay extends StatelessWidget {
  const NotificationCenterOverlay({
    super.key,
    required this.metrics,
    required this.onDismiss,
  });

  final IosHomeMetrics metrics;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final fuel = context.watch<FuelService>();
    final now = DateTime.now();

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.2),
        alignment: Alignment.topLeft,
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
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông báo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: metrics.iconSize * 0.24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: metrics.gridSpacing),
                    _NotificationCard(
                      title: fuel.isLowFuel ? 'Nhiên liệu thấp' : 'Fuel Tracker',
                      body: fuel.isLowFuel
                          ? 'Còn ${fuel.fuelPercent.round()}% — ${fuel.safeRemainingDistanceKm.round()} km an toàn'
                          : '${fuel.vehicleName} · ${fuel.fuelPercent.round()}% nhiên liệu',
                      time: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                      icon: Icons.local_gas_station_rounded,
                      accent: fuel.isLowFuel ? Colors.orange : Colors.blue,
                      metrics: metrics,
                    ),
                    SizedBox(height: metrics.gridSpacing * 0.8),
                    _NotificationCard(
                      title: 'Fuel Tracker Pro',
                      body: 'Theo dõi nhiên liệu realtime qua GPS',
                      time: 'Hôm nay',
                      icon: Icons.navigation_rounded,
                      accent: Colors.green,
                      metrics: metrics,
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.accent,
    required this.metrics,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color accent;
  final IosHomeMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return IosGlassPanel(
      borderRadius: BorderRadius.circular(18),
      padding: EdgeInsets.all(metrics.iconSize * 0.18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: metrics.iconSize * 0.26),
          ),
          SizedBox(width: metrics.iconSize * 0.14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: metrics.iconSize * 0.16,
                          )),
                    ),
                    Text(time,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: metrics.iconSize * 0.12,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: metrics.iconSize * 0.14,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
