import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/launcher_state_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/dynamic_island.dart';

/// Status Bar + Dynamic Island — dự phòng khi không dùng [IPhone17ProMaxFrame].
///
/// Trên Desktop/Web preview, chrome được vẽ duy nhất bởi khung thiết bị.
class IosLauncherChrome extends ConsumerWidget {
  const IosLauncherChrome({
    super.key,
    required this.metrics,
  });

  final IosHomeMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditMode = ref.watch(isEditModeProvider);
    final openApp = ref.watch(openAppProvider);

    // App nền sáng (Group3 demo) — status bar dùng chữ đen cho dễ đọc.
    final isLight = (openApp?.isGroup3Demo ?? false) ||
        Theme.of(context).brightness == Brightness.light;

    return IgnorePointer(
      child: IosHomeHeader(
        metrics: metrics,
        islandExpanded: isEditMode,
        isLight: isLight,
      ),
    );
  }
}
