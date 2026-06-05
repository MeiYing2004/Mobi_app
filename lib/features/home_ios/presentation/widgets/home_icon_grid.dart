import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:fuel_tracker_app/features/home_ios/data/ios_app_model.dart';

import 'package:fuel_tracker_app/features/home_ios/data/ios_home_data.dart';

import 'package:fuel_tracker_app/features/home_ios/data/ios_widget_size.dart';
import 'package:fuel_tracker_app/features/home_ios/presentation/providers/home_layout_provider.dart';

import 'package:fuel_tracker_app/features/home_ios/presentation/providers/launcher_state_provider.dart';

import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/app_icon.dart';

import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_system_widgets.dart';

import 'package:fuel_tracker_app/features/home_ios/presentation/widgets/ios_spring_widgets.dart';
/// Lưới icon 4 cột — widget hàng trên, icon căn trên như iOS Springboard.

class HomeIconGrid extends ConsumerWidget {

  const HomeIconGrid({

    super.key,

    required this.metrics,

    required this.pageIndex,

    required this.onAppTap,

    required this.onAppLongPress,

  });



  final IosHomeMetrics metrics;

  final int pageIndex;

  final void Function(IosAppModel app, BuildContext iconContext) onAppTap;

  final VoidCallback onAppLongPress;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final pageItems = ref.watch(homePageItemsProvider(pageIndex));

    final isEditMode = ref.watch(isEditModeProvider);



    if (pageItems.isEmpty) return const SizedBox.shrink();



    final apps =

        pageItems.where((e) => e.type == IosHomeItemType.app).toList();

    final widgets =

        pageItems.where((e) => e.type == IosHomeItemType.widget).toList();



    final hasWeather = widgets.any((w) => w.widgetKind == IosWidgetKind.weather);

    final hasCalendar =

        widgets.any((w) => w.widgetKind == IosWidgetKind.calendar);

    final fuelWidgets = widgets

        .where((w) => w.widgetKind == IosWidgetKind.fuel)

        .toList();



    void launchFuel(BuildContext ctx) {

      final fuelApp = IosHomeData.defaultDock().first;

      onAppTap(fuelApp, ctx);

    }



    return RepaintBoundary(

      child: Padding(

        padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          mainAxisSize: MainAxisSize.min,

          children: [

            if (hasWeather && hasCalendar)

              IosSystemWidgetRow(

                metrics: metrics,

                onWeatherTap: () => launchFuel(context),

                onCalendarTap: () => launchFuel(context),

              ),

            for (final fuelWidget in fuelWidgets)
              Padding(
                padding: EdgeInsets.only(bottom: metrics.widgetBottomSpacing),
                child: Builder(
                  builder: (widgetContext) => IosFuelTrackerWidget(
                    metrics: metrics,
                    size: fuelWidget.widgetSize ?? IosWidgetSize.medium,
                    onTap: () => launchFuel(widgetContext),
                  ),
                ),
              ),

            for (var row = 0; row < (apps.length / metrics.columns).ceil(); row++)

              _IconRow(

                key: ValueKey('page_${pageIndex}_row_$row'),

                apps: apps

                    .skip(row * metrics.columns)

                    .take(metrics.columns)

                    .toList(),

                metrics: metrics,

                pageIndex: pageIndex,

                startIndex: row * metrics.columns,

                isEditMode: isEditMode,

                onAppTap: onAppTap,

                onAppLongPress: onAppLongPress,

              ),

          ],

        ),

      ),

    );

  }

}



class _IconRow extends ConsumerWidget {

  const _IconRow({

    super.key,

    required this.apps,

    required this.metrics,

    required this.pageIndex,

    required this.startIndex,

    required this.isEditMode,

    required this.onAppTap,

    required this.onAppLongPress,

  });



  final List<IosAppModel> apps;

  final IosHomeMetrics metrics;

  final int pageIndex;

  final int startIndex;

  final bool isEditMode;

  final void Function(IosAppModel app, BuildContext iconContext) onAppTap;

  final VoidCallback onAppLongPress;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    return Padding(

      padding: EdgeInsets.only(bottom: metrics.rowSpacing),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: List.generate(metrics.columns, (col) {

          if (col >= apps.length) {

            return SizedBox(

              width: metrics.iconSize +

                  (col < metrics.columns - 1 ? metrics.columnSpacing : 0),

            );

          }



          final app = apps[col];

          final index = startIndex + col;



          Widget cell = SizedBox(

            width: metrics.iconSize,

            child: Builder(

              builder: (iconContext) {

                return AppIcon(

                  app: app,

                  metrics: metrics,

                  isEditMode: isEditMode,

                  jiggleIndex: index,

                  enableDrag: isEditMode,

                  showBadge: app.id == 'settings',

                  onLongPress: onAppLongPress,

                  onTap: () => onAppTap(app, iconContext),

                );

              },

            ),

          );



          if (isEditMode) {

            cell = DragTarget<int>(

              onWillAcceptWithDetails: (details) => details.data != index,

              onAcceptWithDetails: (details) {

                ref.read(homeLayoutProvider.notifier).reorderInPage(

                      pageIndex,

                      details.data,

                      index,

                    );

              },

              builder: (context, candidate, rejected) {

                return AnimatedContainer(

                  duration: const Duration(milliseconds: 180),

                  decoration: BoxDecoration(

                    borderRadius: BorderRadius.circular(18),

                    border: candidate.isNotEmpty

                        ? Border.all(

                            color: Colors.white.withValues(alpha: 0.45),

                            width: 1.5,

                          )

                        : null,

                  ),

                  child: cell,

                );

              },

            );

          }



          return Padding(

            padding: EdgeInsets.only(

              right: col < metrics.columns - 1 ? metrics.columnSpacing : 0,

            ),

            child: cell,

          );

        }),

      ),

    );

  }

}



/// Chấm chỉ báo trang Home — pill iOS 18.

class HomePageDots extends StatelessWidget {

  const HomePageDots({

    super.key,

    required this.count,

    required this.current,

    required this.metrics,

  });



  final int count;

  final int current;

  final IosHomeMetrics metrics;



  @override

  Widget build(BuildContext context) {

    return RepaintBoundary(
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (i) {
            final active = i == current;
            return IosSpringPageDot(
              active: active,
              inactiveWidth: metrics.pageDotSize,
              activeWidth: metrics.pageDotSize * 2.2,
              height: metrics.pageDotSize,
              margin: EdgeInsets.symmetric(horizontal: metrics.pageDotSize * 0.18),
            );
          }),
        ),
      ),
    );

  }

}

