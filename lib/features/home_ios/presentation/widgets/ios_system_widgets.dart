import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/fuel/data/services/fuel_service.dart';
import 'package:fuel_tracker_app/features/home_ios/core/ios_typography.dart';
import 'package:fuel_tracker_app/features/home_ios/core/ios_visual_tokens.dart';
import 'package:fuel_tracker_app/features/home_ios/data/ios_widget_size.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/wallpaper_widget.dart';

/// Widget thời tiết — bố cục iOS 18 Weather (small 2×2).
class IosWeatherWidget extends StatelessWidget {
  const IosWeatherWidget({
    super.key,
    required this.metrics,
    this.onTap,
  });

  final IosHomeMetrics metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final h = metrics.widgetHeight(IosWidgetSize.small);
    final pad = IosVisualTokens.widgetPadding * metrics.scale;
    final corner = BorderRadius.circular(metrics.widgetCornerRadius);
    final tempSize = metrics.iconSize * 0.736;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: h,
        child: IosGlassHighlight(
          borderRadius: corner,
          subtle: true,
          child: IosGlassPanel(
            borderRadius: corner,
            padding: EdgeInsets.fromLTRB(pad, pad * 0.92, pad, pad * 0.88),
            opacity: IosVisualTokens.glassOpacityWidget,
            blurSigma: IosVisualTokens.glassBlurMedium,
            saturate: true,
            shadows: IosVisualTokens.widgetShadow(metrics.scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hồ Chí Minh',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: IosTypography.widgetCaption(
                    metrics.labelFontSize * 1.02,
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
                SizedBox(height: pad * 0.15),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '28°',
                              style: IosTypography.widgetLargeNumber(tempSize),
                            ),
                            SizedBox(height: pad * 0.08),
                            Text(
                              'Mưa phùn',
                              style: IosTypography.widgetTitle(
                                metrics.labelFontSize * 1.08,
                              ),
                            ),
                            SizedBox(height: pad * 0.06),
                            Text(
                              'C:29°  T:26°',
                              style: IosTypography.widgetCaption(
                                metrics.labelFontSize * 0.98,
                                color: Colors.white.withValues(alpha: 0.58),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: pad * 0.05),
                        child: _WeatherConditionIcon(size: metrics.iconSize * 0.38),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherConditionIcon extends StatelessWidget {
  const _WeatherConditionIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DrizzlePainter(),
    );
  }
}

class _DrizzlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.95);

    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.1, size.width * 0.52, size.height * 0.34),
      cloud,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.32, size.height * 0.04, size.width * 0.5, size.height * 0.32),
      cloud,
    );

    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.26 + i * 0.17);
      canvas.drawLine(
        Offset(x, size.height * 0.52),
        Offset(x - size.width * 0.035, size.height * 0.72),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.82)
          ..strokeWidth = size.width * 0.04
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget lịch — bố cục iOS 18 Calendar (small 2×2).
class IosCalendarWidget extends StatelessWidget {
  const IosCalendarWidget({
    super.key,
    required this.metrics,
    this.onTap,
  });

  final IosHomeMetrics metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final h = metrics.widgetHeight(IosWidgetSize.small);
    final now = DateTime.now();
    const weekdays = [
      'CHỦ NHẬT',
      'THỨ HAI',
      'THỨ BA',
      'THỨ TƯ',
      'THỨ NĂM',
      'THỨ SÁU',
      'THỨ BẢY',
    ];
    final weekday = weekdays[now.weekday % 7];
    final pad = IosVisualTokens.widgetPadding * metrics.scale;
    final corner = BorderRadius.circular(metrics.widgetCornerRadius);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: corner,
            boxShadow: IosVisualTokens.widgetShadow(metrics.scale),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(pad, pad * 0.95, pad, pad * 0.9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: IosTypography.calendarWeekday(metrics.labelFontSize * 0.98),
                ),
                SizedBox(height: pad * 0.12),
                Text(
                  '${now.day}',
                  style: IosTypography.calendarDay(metrics.iconSize * 0.62),
                ),
                const Spacer(),
                Text(
                  'Không có sự kiện',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: IosTypography.calendarFooter(metrics.labelFontSize * 1.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget Fuel Tracker — glass, dữ liệu thật.
class IosFuelTrackerWidget extends StatelessWidget {
  const IosFuelTrackerWidget({
    super.key,
    required this.metrics,
    required this.size,
    this.onTap,
  });

  final IosHomeMetrics metrics;
  final IosWidgetSize size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fuel = context.watch<FuelService>();
    final percent = fuel.fuelPercent.clamp(0.0, 100.0);
    final km = fuel.safeRemainingDistanceKm;
    final isLow = fuel.isLowFuel;
    final accent = isLow ? VehicleUi.warningRed : const Color(0xFF0A84FF);
    final price = fuel.fuelPriceVndPerLiter;
    final priceLabel =
        '${(price / 1000).toStringAsFixed(1).replaceAll('.0', '')}k ₫/L';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: metrics.widgetHeight(size),
        child: IosGlassHighlight(
          subtle: true,
          child: IosGlassPanel(
            borderRadius: BorderRadius.circular(metrics.widgetCornerRadius),
            padding: EdgeInsets.all(IosVisualTokens.widgetPadding * metrics.scale),
            opacity: IosVisualTokens.glassOpacityWidget,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_gas_station_rounded,
                        color: accent, size: metrics.iconSize * 0.26),
                    SizedBox(width: metrics.iconSize * 0.08),
                    Text(
                      'Fuel Tracker',
                      style: IosTypography.widgetTitle(metrics.iconSize * 0.17),
                    ),
                  ],
                ),
                SizedBox(height: metrics.iconSize * 0.1),
                Expanded(
                  child: Row(
                    children: [
                      _FuelStat(
                        label: 'Nhiên liệu',
                        value: '${percent.round()}%',
                        accent: accent,
                        metrics: metrics,
                      ),
                      SizedBox(width: metrics.iconSize * 0.08),
                      _FuelStat(
                        label: 'Còn lại',
                        value: '${km.round()} km',
                        accent: const Color(0xFF30D158),
                        metrics: metrics,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _FuelStat(
                        label: 'Giá hôm nay',
                        value: priceLabel,
                        accent: const Color(0xFF0A84FF),
                        metrics: metrics,
                        compact: true,
                      ),
                    ),
                    SizedBox(width: metrics.iconSize * 0.08),
                    Expanded(
                      child: _FuelStat(
                        label: 'Đổ gần nhất',
                        value: fuel.lastFillUpLabel,
                        accent: Colors.white70,
                        metrics: metrics,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FuelStat extends StatelessWidget {
  const _FuelStat({
    required this.label,
    required this.value,
    required this.accent,
    required this.metrics,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color accent;
  final IosHomeMetrics metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.iconSize * (compact ? 0.09 : 0.1),
          vertical: metrics.iconSize * (compact ? 0.07 : 0.09),
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(metrics.iconSize * 0.12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: IosTypography.widgetBody(
                metrics.iconSize * (compact ? 0.095 : 0.105),
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: IosTypography.widgetTitle(
                metrics.iconSize * (compact ? 0.13 : 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hàng widget 2×2.
class IosSystemWidgetRow extends StatelessWidget {
  const IosSystemWidgetRow({
    super.key,
    required this.metrics,
    this.onWeatherTap,
    this.onCalendarTap,
  });

  final IosHomeMetrics metrics;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final gap = metrics.columnSpacing;
    final widgetW = metrics.iconSize * 2 + gap;

    return Padding(
      padding: EdgeInsets.only(bottom: metrics.widgetToIconGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: widgetW,
            child: IosWeatherWidget(metrics: metrics, onTap: onWeatherTap),
          ),
          SizedBox(width: gap),
          SizedBox(
            width: widgetW,
            child: IosCalendarWidget(metrics: metrics, onTap: onCalendarTap),
          ),
        ],
      ),
    );
  }
}
