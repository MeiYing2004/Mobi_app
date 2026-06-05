import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overlay hệ thống iOS — Spotlight, Control Center, Notification Center.
enum IosSystemOverlay {
  none,
  spotlight,
  controlCenter,
  notificationCenter,
}

class SystemOverlayNotifier extends Notifier<IosSystemOverlay> {
  @override
  IosSystemOverlay build() => IosSystemOverlay.none;

  void show(IosSystemOverlay overlay) {
    if (state == overlay) return;
    state = overlay;
  }

  void dismiss() {
    if (state == IosSystemOverlay.none) return;
    state = IosSystemOverlay.none;
  }

  void toggle(IosSystemOverlay overlay) {
    state = state == overlay ? IosSystemOverlay.none : overlay;
  }
}

final systemOverlayProvider =
    NotifierProvider<SystemOverlayNotifier, IosSystemOverlay>(
  SystemOverlayNotifier.new,
);

class SpotlightNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;

  void clear() => state = '';
}

final spotlightQueryProvider =
    NotifierProvider<SpotlightNotifier, String>(SpotlightNotifier.new);
