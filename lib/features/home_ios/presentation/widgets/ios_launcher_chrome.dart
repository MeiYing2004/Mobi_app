import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/launcher_state_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/dynamic_island.dart';

/// Status Bar + Dynamic Island — nội dung chrome (Positioned do parent Stack đặt).
class IosLauncherChrome extends ConsumerWidget {
  const IosLauncherChrome({
    super.key,
    required this.metrics,
  });

  final IosHomeMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditMode = ref.watch(isEditModeProvider);

    final isLight = Theme.of(context).brightness == Brightness.light;

    return IgnorePointer(
      child: IosHomeHeader(
        metrics: metrics,
        islandExpanded: isEditMode,
        isLight: isLight,
      ),
    );
  }
}
