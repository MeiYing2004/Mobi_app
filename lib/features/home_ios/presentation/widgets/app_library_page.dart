import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fuel_tracker_app/features/home_ios/data/ios_app_catalog.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/app_icon.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/wallpaper_widget.dart';

/// App Library — trang cuối, nhóm ứng dụng theo danh mục.
class AppLibraryPage extends StatelessWidget {
  const AppLibraryPage({
    super.key,
    required this.metrics,
    required this.onAppTap,
  });

  final IosHomeMetrics metrics;
  final void Function(IosAppModel app, BuildContext iconContext) onAppTap;

  @override
  Widget build(BuildContext context) {
    final groups = IosAppCatalog.groupedByCategory();
    final sortedKeys = groups.keys.toList()..sort();

    return RepaintBoundary(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          metrics.horizontalPadding,
          metrics.screenHeight * 0.01,
          metrics.horizontalPadding,
          metrics.contentBottomClearance - metrics.dockZoneHeight,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            'App Library',
            style: TextStyle(
              color: Colors.white,
              fontSize: metrics.iconSize * 0.34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.08, end: 0),
          SizedBox(height: metrics.gridSpacing),
          for (final category in sortedKeys) ...[
            _CategorySection(
              title: category,
              apps: groups[category]!,
              metrics: metrics,
              onAppTap: onAppTap,
            ),
            SizedBox(height: metrics.gridSpacing * 1.4),
          ],
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.apps,
    required this.metrics,
    required this.onAppTap,
  });

  final String title;
  final List<IosAppModel> apps;
  final IosHomeMetrics metrics;
  final void Function(IosAppModel app, BuildContext iconContext) onAppTap;

  @override
  Widget build(BuildContext context) {
    return IosGlassPanel(
      borderRadius: BorderRadius.circular(metrics.iconSize * 0.36),
      padding: EdgeInsets.all(metrics.iconSize * 0.22),
      opacity: 0.16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: metrics.iconSize * 0.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: metrics.gridSpacing),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: metrics.columns,
              crossAxisSpacing: metrics.gridSpacing,
              mainAxisSpacing: metrics.gridSpacing * 1.1,
              mainAxisExtent: metrics.iconCellHeight,
            ),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return Builder(
                builder: (iconContext) {
                  return AppIcon(
                    app: app,
                    metrics: metrics,
                    showLabel: true,
                    onTap: () => onAppTap(app, iconContext),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
