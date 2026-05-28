import 'package:flutter/foundation.dart';

import 'hmi_intents.dart';
import 'motion_director.dart';

/// Interaction meaning layer for HMI architecture.
///
/// Interprets raw user input into semantic intents and maintains
/// global spatial state consistency.
class InteractionController extends ChangeNotifier {
  final MotionDirector _motionDirector;

  InteractionController({required MotionDirector motionDirector})
      : _motionDirector = motionDirector;

  HmiSpatialState _state = const HmiSpatialState(
    mapFocusLevel: 0,
    hudElevationState: 0,
    sheetDepth: 0,
    navigationMode: false,
  );

  HmiIntent? _lastIntent;

  HmiSpatialState get state => _state;
  HmiIntent? get lastIntent => _lastIntent;

  void openSheet() {
    _state = _state.copyWith(
      mapFocusLevel: 1,
      hudElevationState: 1,
    );
    _emit(const HmiIntent(HmiIntentType.openSheet));
  }

  void expandSheet(double depth) {
    _state = _state.copyWith(
      sheetDepth: depth.clamp(0, 1),
      mapFocusLevel: depth.clamp(0, 1),
      hudElevationState: depth.clamp(0, 1),
    );
    _emit(HmiIntent(HmiIntentType.expandSheet, value: depth.clamp(0, 1)));
  }

  void collapseSheet() {
    _state = _state.copyWith(
      mapFocusLevel: 0,
      hudElevationState: 0,
      sheetDepth: 0,
    );
    _emit(const HmiIntent(HmiIntentType.collapseSheet));
  }

  void focusMap() {
    _state = _state.copyWith(
      mapFocusLevel: 0,
      hudElevationState: 0,
      sheetDepth: 0,
    );
    _emit(const HmiIntent(HmiIntentType.focusMap));
  }

  void activateNavigation() {
    _state = _state.copyWith(
      navigationMode: true,
      mapFocusLevel: 0,
      sheetDepth: 0,
    );
    _emit(const HmiIntent(HmiIntentType.activateNavigation));
  }

  void deactivateNavigation() {
    _state = _state.copyWith(
      navigationMode: false,
      mapFocusLevel: 0,
      hudElevationState: 0,
      sheetDepth: 0,
    );
    _emit(const HmiIntent(HmiIntentType.deactivateNavigation));
  }

  void _emit(HmiIntent intent) {
    _lastIntent = intent;
    _motionDirector.applyIntent(intent: intent, spatialState: _state);
    notifyListeners();
  }
}

