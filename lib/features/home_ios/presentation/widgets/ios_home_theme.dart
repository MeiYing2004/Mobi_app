import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_typography.dart';

/// Theme Home Screen — SF Pro, không gạch chân, cách ly khỏi MaterialApp theme.
class IosHomeTheme extends StatelessWidget {
  const IosHomeTheme({super.key, required this.child});

  final Widget child;

  static TextStyle _baseStyle(double size) => IosTypography.homeLabel(size);

  @override
  Widget build(BuildContext context) {
    const labelSize = 11.0;
    final baseLabel = _baseStyle(labelSize);

    TextTheme buildTextTheme() {
      TextStyle every(TextStyle s) => s.copyWith(
            inherit: false,
            textBaseline: TextBaseline.alphabetic,
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
            color: Colors.white,
          );

      return TextTheme(
        displayLarge: every(IosTypography.widgetLargeNumber(34)),
        displayMedium: every(IosTypography.statusTime(17)),
        displaySmall: every(IosTypography.widgetTitle(15)),
        headlineLarge: every(IosTypography.widgetTitle(17)),
        headlineMedium: every(IosTypography.widgetTitle(15)),
        headlineSmall: every(IosTypography.widgetTitle(13)),
        titleLarge: every(IosTypography.widgetTitle(17)),
        titleMedium: every(IosTypography.widgetTitle(15)),
        titleSmall: every(IosTypography.widgetTitle(13)),
        bodyLarge: every(baseLabel),
        bodyMedium: every(baseLabel),
        bodySmall: every(baseLabel),
        labelLarge: every(baseLabel),
        labelMedium: every(baseLabel),
        labelSmall: every(baseLabel),
      );
    }

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: IosTypography.textFamily,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          surface: Colors.transparent,
          error: Color(0xFFFF3B30),
        ),
        textTheme: buildTextTheme(),
        primaryTextTheme: buildTextTheme(),
      ),
      child: DefaultTextStyle(
        style: baseLabel,
        child: IconTheme(
          data: const IconThemeData(color: Colors.white, size: 24),
          child: child,
        ),
      ),
    );
  }
}
