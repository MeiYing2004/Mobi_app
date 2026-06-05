import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/data/ios_app_catalog.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/system_overlay_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/wallpaper_widget.dart';

/// Spotlight Search — vuốt xuống để tìm ứng dụng.
class SpotlightOverlay extends ConsumerWidget {
  const SpotlightOverlay({
    super.key,
    required this.metrics,
    required this.onAppSelected,
    required this.onDismiss,
  });

  final IosHomeMetrics metrics;
  final void Function(IosAppModel app) onAppSelected;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(spotlightQueryProvider);
    final apps = IosAppCatalog.allApps
        .where((a) =>
            query.isEmpty ||
            a.name.toLowerCase().contains(query.toLowerCase()) ||
            (a.category ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(metrics.horizontalPadding),
              child: Column(
                children: [
                  IosGlassPanel(
                    borderRadius: BorderRadius.circular(16),
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.iconSize * 0.2,
                      vertical: metrics.iconSize * 0.12,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            color: Colors.white70, size: metrics.iconSize * 0.28),
                        SizedBox(width: metrics.iconSize * 0.12),
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: metrics.iconSize * 0.2,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Tìm kiếm',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: ref.read(spotlightQueryProvider.notifier).setQuery,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.06, end: 0),
                  SizedBox(height: metrics.gridSpacing),
                  Expanded(
                    child: ListView.builder(
                      itemCount: apps.length,
                      itemBuilder: (context, i) {
                        final app = apps[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (app.iconGradient?.first ??
                                    Colors.blue)
                                .withValues(alpha: 0.35),
                            child: Icon(app.iconData, color: Colors.white),
                          ),
                          title: Text(app.name,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            app.category ?? '',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          onTap: () {
                            ref.read(spotlightQueryProvider.notifier).clear();
                            onAppSelected(app);
                          },
                        );
                      },
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
