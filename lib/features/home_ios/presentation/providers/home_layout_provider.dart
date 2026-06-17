import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_visual_tokens.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_home_data.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_layout_repository.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_widget_size.dart';

/// Bố cục icon trên các trang Home.
class HomeLayoutState {
  const HomeLayoutState({
    required this.pages,
    required this.dock,
  });

  final List<List<IosAppModel>> pages;
  final List<IosAppModel> dock;

  HomeLayoutState copyWith({
    List<List<IosAppModel>>? pages,
    List<IosAppModel>? dock,
  }) {
    return HomeLayoutState(
      pages: pages ?? this.pages,
      dock: dock ?? this.dock,
    );
  }
}

final layoutRepositoryProvider = Provider((ref) => IosLayoutRepository());

class HomeLayoutNotifier extends Notifier<HomeLayoutState> {
  IosLayoutRepository get _repo => ref.read(layoutRepositoryProvider);
  bool _loaded = false;

  @override
  HomeLayoutState build() {
    Future.microtask(_loadPersisted);
    return HomeLayoutState(
      pages: IosHomeData.defaultPages(),
      dock: IosHomeData.defaultDock(),
    );
  }

  Future<void> _loadPersisted() async {
    if (_loaded) return;
    _loaded = true;
    final saved = await _repo.load();
    if (saved != null) state = saved;
  }

  void _persist() {
    Future.microtask(() => _repo.save(state));
  }

  void reorderInPage(int pageIndex, int from, int to) {
    if (pageIndex < 0 || pageIndex >= state.pages.length) return;
    final page = List<IosAppModel>.from(state.pages[pageIndex]);
    final apps =
        page.where((item) => item.type == IosHomeItemType.app).toList();
    if (from < 0 || from >= apps.length || to < 0 || to >= apps.length) return;
    if (from == to) return;

    final moved = apps.removeAt(from);
    apps.insert(to, moved);

    var appCursor = 0;
    final rebuilt = page.map((item) {
      if (item.type == IosHomeItemType.widget) return item;
      return apps[appCursor++];
    }).toList();

    final pages = List<List<IosAppModel>>.from(state.pages);
    pages[pageIndex] = rebuilt;
    state = state.copyWith(pages: pages);
    _persist();
  }

  void reorderDock(int from, int to) {
    final dock = List<IosAppModel>.from(state.dock);
    if (from < 0 || from >= dock.length || to < 0 || to >= dock.length) return;
    if (from == to) return;

    final item = dock.removeAt(from);
    dock.insert(to, item);
    state = state.copyWith(dock: dock);
    _persist();
  }
}

final homeLayoutProvider =
    NotifierProvider<HomeLayoutNotifier, HomeLayoutState>(
  HomeLayoutNotifier.new,
);

final homeDockProvider = Provider<List<IosAppModel>>((ref) {
  return ref.watch(homeLayoutProvider.select((layout) => layout.dock));
});

final homePageCountProvider = Provider<int>((ref) {
  return ref.watch(homeLayoutProvider.select((layout) => layout.pages.length));
});

final homePageItemsProvider =
    Provider.family<List<IosAppModel>, int>((ref, pageIndex) {
  return ref.watch(
    homeLayoutProvider.select(
      (layout) =>
          pageIndex < layout.pages.length ? layout.pages[pageIndex] : const [],
    ),
  );
});

/// Kích thước responsive — scale từ iPhone 17 Pro Max 430×932 pt.
class IosHomeMetrics {
  const IosHomeMetrics({
    required this.screenWidth,
    required this.screenHeight,
    required this.scale,
    required this.topPadding,
    required this.bottomPadding,
    required this.iconSize,
    required this.iconLabelGap,
    required this.labelFontSize,
    required this.labelLineHeight,
    required this.columnSpacing,
    required this.rowSpacing,
    required this.horizontalPadding,
    required this.dockHeight,
    required this.dockCornerRadius,
    required this.widgetCornerRadius,
    required this.dockIconSize,
    required this.dockHorizontalInset,
    required this.dockBottomPadding,
    required this.pageDotSize,
    required this.statusBarHeight,
    required this.islandWidth,
    required this.islandHeight,
    required this.statusBarTotalHeight,
    required this.statusBarSideInset,
    required this.statusBarContentTop,
    required this.islandTopOffset,
    required this.columns,
    required this.widgetBottomSpacing,
    required this.widgetToIconGap,
    required this.homeIndicatorWidth,
    required this.homeIndicatorHeight,
    required this.pageDotsBottomOffset,
    required this.homeIndicatorBottomInset,
    required this.shellTopInset,
    required this.shellBottomInset,
    required this.pageScrollBottomPadding,
  });

  final double screenWidth;
  final double screenHeight;
  final double scale;
  final double topPadding;
  final double bottomPadding;
  final double iconSize;
  final double iconLabelGap;
  final double labelFontSize;
  final double labelLineHeight;
  final double columnSpacing;
  final double rowSpacing;
  final double horizontalPadding;
  final double dockHeight;
  final double dockCornerRadius;
  final double widgetCornerRadius;
  final double dockIconSize;
  final double dockHorizontalInset;
  final double dockBottomPadding;
  final double pageDotSize;
  final double statusBarHeight;
  final double islandWidth;
  final double islandHeight;
  final double statusBarTotalHeight;
  final double statusBarSideInset;
  final double statusBarContentTop;
  final double islandTopOffset;
  final int columns;
  final double widgetBottomSpacing;
  final double widgetToIconGap;
  final double homeIndicatorWidth;
  final double homeIndicatorHeight;
  final double pageDotsBottomOffset;
  final double homeIndicatorBottomInset;
  final double shellTopInset;
  final double shellBottomInset;
  final double pageScrollBottomPadding;

  /// Alias cho columnSpacing (tương thích code cũ).
  double get gridSpacing => columnSpacing;

  double get iconCellWidth => iconSize;

  double get iconCellHeight => iconSize + iconLabelGap + labelLineHeight;

  /// Vùng cố định phía dưới — Dock + khoảng cách tới Home Indicator.
  double get dockZoneHeight => dockBottomPadding + dockHeight;

  /// Khoảng cách nội dung cuộn tới mép trên Dock (gồm page dots).
  double get contentBottomClearance =>
      dockZoneHeight + IosVisualTokens.pageDotsAboveDock * scale + 24 * scale;

  double widgetHeight(IosWidgetSize size) =>
      iconCellHeight * size.rowSpan + rowSpacing * (size.rowSpan - 1);

  static IosHomeMetrics of(BuildContext context) {
    final media = MediaQuery.of(context);
    return forScreen(
      screenWidth: media.size.width,
      screenHeight: media.size.height,
      topPadding: media.padding.top,
      bottomPadding: media.padding.bottom,
    );
  }

  /// Metrics từ kích thước màn hình — dùng trong frame preview hoặc khi không có MediaQuery.
  static IosHomeMetrics forScreen({
    required double screenWidth,
    required double screenHeight,
    double topPadding = 0,
    double bottomPadding = 0,
  }) {
    const columns = 4;
    final s = IosVisualTokens.scaleW(screenWidth);

    final iconSize = IosVisualTokens.iconSize * s;
    final columnSpacing = IosVisualTokens.columnSpacing * s;
    final labelGap = IosVisualTokens.labelGap * s;
    final labelLineH = IosVisualTokens.labelLineHeight * s;
    final labelFont = IosVisualTokens.labelFontSize * s;
    final iconCellH = iconSize + labelGap + labelLineH;
    final rowSpacing =
        IosVisualTokens.rowPitch * s - iconCellH;
    final horizontalPadding = IosVisualTokens.horizontalPadding * s;

    final islandW = IosVisualTokens.islandWidth * s;
    final islandH = IosVisualTokens.islandHeight * s;
    final islandTop = topPadding + IosVisualTokens.islandTop * s;
    final statusBarTotal = islandTop + islandH + 4 * s;
    final statusSideInset = 16 * s;
    final statusContentTop = islandTop + islandH * 0.48 - 8.5 * s;

    // Mock (topPadding=0): chừa đủ chỗ cho chrome giả.
    // Thiết bị thật: chỉ cộng thêm khoảng thở — safe area hệ thống đã gồm island.
    final shellTop = topPadding > 0
        ? topPadding + IosVisualTokens.shellBreathingSpace * s
        : statusBarTotal + IosVisualTokens.shellBreathingSpace * s;

    final homeIndicatorW = IosVisualTokens.homeIndicatorWidth * s;
    final homeIndicatorH = IosVisualTokens.homeIndicatorHeight * s;
    final homeIndicatorBottom = IosVisualTokens.homeIndicatorBottom * s;

    final dockH = IosVisualTokens.dockHeight * s;
    final dockBottom = IosVisualTokens.dockBottomFromScreen * s;
    final dockCornerR = IosVisualTokens.dockCornerRadius * s;
    final widgetCornerR = IosVisualTokens.widgetCornerRadius * s;

    final pageDotsBottom = dockBottom + dockH + IosVisualTokens.pageDotsAboveDock * s;
    final dockZone = dockBottom + dockH;
    final contentBottomClearance =
        dockZone + IosVisualTokens.pageDotsAboveDock * s + 24 * s;

    return IosHomeMetrics(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      scale: s,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      iconSize: iconSize,
      iconLabelGap: labelGap,
      labelFontSize: labelFont,
      labelLineHeight: labelLineH,
      columnSpacing: columnSpacing,
      rowSpacing: rowSpacing,
      horizontalPadding: horizontalPadding,
      dockHeight: dockH,
      dockCornerRadius: dockCornerR,
      widgetCornerRadius: widgetCornerR,
      dockIconSize: IosVisualTokens.dockIconSize * s,
      dockHorizontalInset: IosVisualTokens.dockHorizontalInset * s,
      dockBottomPadding: dockBottom,
      pageDotSize: 7 * s,
      statusBarHeight: 22 * s,
      islandWidth: islandW,
      islandHeight: islandH,
      statusBarTotalHeight: statusBarTotal,
      statusBarSideInset: statusSideInset,
      statusBarContentTop: statusContentTop,
      islandTopOffset: islandTop,
      columns: columns,
      widgetBottomSpacing: rowSpacing,
      widgetToIconGap: IosVisualTokens.widgetToIconGap * s,
      homeIndicatorWidth: homeIndicatorW,
      homeIndicatorHeight: homeIndicatorH,
      pageDotsBottomOffset: pageDotsBottom,
      homeIndicatorBottomInset: homeIndicatorBottom,
      shellTopInset: shellTop,
      shellBottomInset: bottomPadding > 0
          ? bottomPadding + 12 * s
          : homeIndicatorBottom + homeIndicatorH + 28 * s,
      pageScrollBottomPadding: contentBottomClearance,
    );
  }
}
