import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';

/// Trạng thái launcher — app đang mở, chế độ chỉnh sửa, trang hiện tại.
class LauncherState {
  const LauncherState({
    this.openApp,
    this.isEditMode = false,
    this.currentPage = 0,
    this.iconLaunchRect,
  });

  final IosAppModel? openApp;
  final bool isEditMode;
  final int currentPage;
  final Rect? iconLaunchRect;

  bool get isAppOpen => openApp != null;

  LauncherState copyWith({
    IosAppModel? openApp,
    bool clearOpenApp = false,
    bool? isEditMode,
    int? currentPage,
    Rect? iconLaunchRect,
    bool clearIconLaunchRect = false,
  }) {
    return LauncherState(
      openApp: clearOpenApp ? null : (openApp ?? this.openApp),
      isEditMode: isEditMode ?? this.isEditMode,
      currentPage: currentPage ?? this.currentPage,
      iconLaunchRect: clearIconLaunchRect
          ? null
          : (iconLaunchRect ?? this.iconLaunchRect),
    );
  }
}

class LauncherNotifier extends Notifier<LauncherState> {
  @override
  LauncherState build() => const LauncherState();

  void setPage(int page) {
    if (page == state.currentPage) return;
    state = state.copyWith(currentPage: page);
  }

  void enterEditMode() {
    if (state.isEditMode) return;
    state = state.copyWith(isEditMode: true);
  }

  void exitEditMode() {
    if (!state.isEditMode) return;
    state = state.copyWith(isEditMode: false);
  }

  void openApp(IosAppModel app, {Rect? iconRect}) {
    state = state.copyWith(
      openApp: app,
      iconLaunchRect: iconRect,
      isEditMode: false,
    );
  }

  void closeApp() {
    state = state.copyWith(clearOpenApp: true, clearIconLaunchRect: true);
  }
}

final launcherProvider =
    NotifierProvider<LauncherNotifier, LauncherState>(LauncherNotifier.new);

final isEditModeProvider = Provider<bool>((ref) {
  return ref.watch(launcherProvider.select((s) => s.isEditMode));
});

final currentPageProvider = Provider<int>((ref) {
  return ref.watch(launcherProvider.select((s) => s.currentPage));
});

final openAppProvider = Provider<IosAppModel?>((ref) {
  return ref.watch(launcherProvider.select((s) => s.openApp));
});

final isAppOpenProvider = Provider<bool>((ref) {
  return ref.watch(launcherProvider.select((s) => s.isAppOpen));
});

final iconLaunchRectProvider = Provider<Rect?>((ref) {
  return ref.watch(launcherProvider.select((s) => s.iconLaunchRect));
});
