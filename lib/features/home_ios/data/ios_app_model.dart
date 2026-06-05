import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/home_ios/data/ios_widget_size.dart';

/// Loại mục trên màn hình Home iOS.
enum IosHomeItemType { app, widget }

/// Loại widget hệ thống trên Home Screen.
enum IosWidgetKind { fuel, weather, calendar }

/// Một ứng dụng hoặc widget trên Home Screen.
class IosAppModel {
  const IosAppModel({
    required this.id,
    required this.name,
    this.type = IosHomeItemType.app,
    this.category,
    this.icon,
    this.iconGradient,
    this.iconData,
    this.iconColor,
    this.isFuelTracker = false,
    this.widgetSize,
    this.widgetKind,
  });

  final String id;
  final String name;
  final IosHomeItemType type;
  final String? category;
  final Widget? icon;
  final List<Color>? iconGradient;
  final IconData? iconData;
  final Color? iconColor;
  final bool isFuelTracker;
  final IosWidgetSize? widgetSize;
  final IosWidgetKind? widgetKind;

  IosAppModel copyWith({
    String? id,
    String? name,
    IosHomeItemType? type,
    String? category,
    Widget? icon,
    List<Color>? iconGradient,
    IconData? iconData,
    Color? iconColor,
    bool? isFuelTracker,
    IosWidgetSize? widgetSize,
    IosWidgetKind? widgetKind,
  }) {
    return IosAppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      iconGradient: iconGradient ?? this.iconGradient,
      iconData: iconData ?? this.iconData,
      iconColor: iconColor ?? this.iconColor,
      isFuelTracker: isFuelTracker ?? this.isFuelTracker,
      widgetSize: widgetSize ?? this.widgetSize,
      widgetKind: widgetKind ?? this.widgetKind,
    );
  }
}
