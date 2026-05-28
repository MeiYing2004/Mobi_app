enum HmiIntentType {
  openSheet,
  expandSheet,
  collapseSheet,
  focusMap,
  activateNavigation,
  deactivateNavigation,
}

class HmiIntent {
  final HmiIntentType type;
  final double value;

  const HmiIntent(this.type, {this.value = 0});
}

class HmiSpatialState {
  final double mapFocusLevel;
  final double hudElevationState;
  final double sheetDepth;
  final bool navigationMode;

  const HmiSpatialState({
    required this.mapFocusLevel,
    required this.hudElevationState,
    required this.sheetDepth,
    required this.navigationMode,
  });

  HmiSpatialState copyWith({
    double? mapFocusLevel,
    double? hudElevationState,
    double? sheetDepth,
    bool? navigationMode,
  }) {
    return HmiSpatialState(
      mapFocusLevel: mapFocusLevel ?? this.mapFocusLevel,
      hudElevationState: hudElevationState ?? this.hudElevationState,
      sheetDepth: sheetDepth ?? this.sheetDepth,
      navigationMode: navigationMode ?? this.navigationMode,
    );
  }
}

