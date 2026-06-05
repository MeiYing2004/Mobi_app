import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/core/refuel_debug_tools.dart';

import 'package:fuel_tracker_app/core/ios_design_tokens.dart';
import 'package:fuel_tracker_app/core/micro_motion_spec.dart';
import 'package:fuel_tracker_app/core/motion_director.dart';
import 'package:fuel_tracker_app/core/vehicle_ui_tokens.dart';
import 'package:fuel_tracker_app/features/navigation/data/models/navigation_route.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/refuel_flow_phase.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/route_fuel_analysis.dart';
import 'package:fuel_tracker_app/features/fuel/data/models/trip_fuel_status.dart';

/// Cinematic Navigation HUD — quiet hierarchy, spatial depth above map.
class NavigationHud extends StatefulWidget {
  final NavigationRoute route;
  final VoidCallback onClose;
  final RefuelFlowPhase? refuelPhase;
  final VoidCallback? onNavigateToNearestStation;
  final VoidCallback? onContinueTrip;
  final VoidCallback? onDemoRefuel;
  final MotionDirector? motionDirector;
  final bool initiallyCollapsed;

  const NavigationHud({
    super.key,
    required this.route,
    required this.onClose,
    this.refuelPhase,
    this.onNavigateToNearestStation,
    this.onContinueTrip,
    this.onDemoRefuel,
    this.motionDirector,
    this.initiallyCollapsed = true,
  });

  @override
  State<NavigationHud> createState() => _NavigationHudState();
}

class _NavigationHudState extends State<NavigationHud> {
  late bool _collapsed = widget.initiallyCollapsed;

  NavigationRoute get route => widget.route;

  @override
  void didUpdateWidget(covariant NavigationHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.destination.id != widget.route.destination.id) {
      _collapsed = widget.initiallyCollapsed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fuel = route.fuelAnalysis;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final b = Theme.of(context).brightness;

    Widget buildBody(double motionFactor) {
      final opacity = (1.0 - motionFactor * 0.55).clamp(0.0, 1.0);
      final lift = 8.0 * motionFactor;

      return Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, lift),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, bottom + 12),
            child: AnimatedSwitcher(
              duration: MicroMotionSpec.slow,
              switchInCurve: MicroMotionSpec.fadeCurve,
              switchOutCurve: MicroMotionSpec.fadeCurve,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
                    alignment: _collapsed
                        ? Alignment.bottomCenter
                        : Alignment.bottomCenter,
                    child: child,
                  ),
                );
              },
              child: _collapsed
                  ? _CollapsedHudChip(
                      key: const ValueKey('hud_collapsed'),
                      route: route,
                      onExpand: () => setState(() => _collapsed = false),
                      brightness: b,
                    )
                  : _ExpandedHudCard(
                      key: const ValueKey('hud_expanded'),
                      route: route,
                      fuel: fuel,
                      brightness: b,
                      onClose: widget.onClose,
                      onMinimize: () => setState(() => _collapsed = true),
                      refuelPhase: widget.refuelPhase,
                      onNavigateToNearestStation:
                          widget.onNavigateToNearestStation,
                      onContinueTrip: widget.onContinueTrip,
                      onDemoRefuel: widget.onDemoRefuel,
                    ),
            ),
          ),
        ),
      );
    }

    if (widget.motionDirector == null) {
      return buildBody(0);
    }

    return AnimatedBuilder(
      animation: widget.motionDirector!,
      builder: (context, _) => buildBody(widget.motionDirector!.hudRetreat),
    );
  }
}

class _ExpandedHudCard extends StatelessWidget {
  final NavigationRoute route;
  final RouteFuelAnalysis fuel;
  final Brightness brightness;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final RefuelFlowPhase? refuelPhase;
  final VoidCallback? onNavigateToNearestStation;
  final VoidCallback? onContinueTrip;
  final VoidCallback? onDemoRefuel;

  const _ExpandedHudCard({
    super.key,
    required this.route,
    required this.fuel,
    required this.brightness,
    required this.onClose,
    required this.onMinimize,
    this.refuelPhase,
    this.onNavigateToNearestStation,
    this.onContinueTrip,
    this.onDemoRefuel,
  });

  @override
  Widget build(BuildContext context) {
    final b = brightness;
    return ClipRRect(
      borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: VehicleUi.cardFor(b).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 26,
                spreadRadius: -14,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: VehicleUi.accentBlueGlow.withValues(alpha: 0.26),
                blurRadius: 56,
                spreadRadius: -40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(VehicleUi.radiusLg),
                    border: Border.all(
                      color: VehicleUi.accentBlue.withValues(alpha: 0.10),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _HudIconButton(
                          onTap: onClose,
                          icon: Icons.close_rounded,
                          tooltip: 'Kết thúc chỉ đường',
                        ),
                        const SizedBox(width: 8),
                        _HudIconButton(
                          onTap: onMinimize,
                          icon: Icons.keyboard_arrow_down_rounded,
                          tooltip: 'Thu gọn',
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đi đến',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                  color: VehicleUi.textMuted.withValues(alpha: 0.92),
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                route.destination.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                  height: 1.05,
                                ),
                              ),
                              if (route.destination.brand.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  route.destination.brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: VehicleUi.textMuted.withValues(alpha: 0.92),
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _PrimaryMetric(
                          label: 'ETA',
                          value: route.etaLabel,
                          accent: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryMetric(
                            label: 'Khoảng cách',
                            value: route.distanceLabel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PrimaryMetric(
                            label: 'Thời gian',
                            value: route.durationLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniFuelStat(
                            label: 'Xăng hiện tại',
                            value:
                                '${fuel.currentFuelLiters.toStringAsFixed(1)} L',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniFuelStat(
                            label: 'Có thể đi',
                            value: fuel.rangeLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dự kiến còn ${fuel.fuelAfterArrivalLabel} khi tới nơi • '
                      '${fuel.stationsOnRouteCount} cây xăng trên tuyến',
                      style: TextStyle(
                        fontSize: 11,
                        color: VehicleUi.textMuted.withValues(alpha: 0.9),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fuel.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fuel.status.circleFill,
                      ),
                    ),
                    if (_refuelCardVisible(fuel, refuelPhase)) ...[
                      const SizedBox(height: 12),
                      _RefuelFlowCard(
                        phase: refuelPhase ?? RefuelFlowPhase.needRefuel,
                        onNavigateToNearestStation: onNavigateToNearestStation,
                        onContinueTrip: onContinueTrip,
                        onDemoRefuel: onDemoRefuel,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'OSRM • OpenStreetMap',
                      style: TextStyle(
                        fontSize: 10,
                        color: VehicleUi.textMuted.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _refuelCardVisible(RouteFuelAnalysis fuel, RefuelFlowPhase? phase) {
    if (phase == RefuelFlowPhase.arrivedGasStation) return true;
    if (phase == RefuelFlowPhase.readyToContinueTrip) return true;
    if (phase == RefuelFlowPhase.goToGasStation) return true;
    if (phase == RefuelFlowPhase.continueTrip) return false;
    return fuel.insufficientFuel;
  }
}

class _CollapsedHudChip extends StatelessWidget {
  final NavigationRoute route;
  final VoidCallback onExpand;
  final Brightness brightness;

  const _CollapsedHudChip({
    super.key,
    required this.route,
    required this.onExpand,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final b = brightness;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 28,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onExpand,
            borderRadius: BorderRadius.circular(999),
            splashColor: VehicleUi.accentBlue.withValues(alpha: 0.18),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: VehicleUi.cardFor(b).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: VehicleUi.floatingShadowNearFor(b),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: VehicleUi.accentBlue.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.navigation_rounded,
                      size: 18,
                      color: VehicleUi.accentBlue.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          route.destination.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          '${route.distanceLabel} • ETA ${route.etaLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: VehicleUi.textMuted.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HudIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String? tooltip;

  const _HudIconButton({
    required this.onTap,
    required this.icon,
    this.tooltip,
  });

  @override
  State<_HudIconButton> createState() => _HudIconButtonState();
}

class _HudIconButtonState extends State<_HudIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? MicroMotionSpec.pressedScale : 1.0,
        duration: MicroMotionSpec.fast,
        curve: MicroMotionSpec.emphasisCurve,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(widget.icon, size: 18, color: Colors.white.withValues(alpha: 0.92)),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}

class _PrimaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _PrimaryMetric({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ? VehicleUi.accentBlue : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: VehicleUi.textMuted.withValues(alpha: 0.9),
            height: 1.1,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.05,
            color: c.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

class _MiniFuelStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniFuelStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: VehicleUi.textMuted.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefuelFlowCard extends StatelessWidget {
  final RefuelFlowPhase phase;
  final VoidCallback? onNavigateToNearestStation;
  final VoidCallback? onContinueTrip;
  final VoidCallback? onDemoRefuel;

  const _RefuelFlowCard({
    required this.phase,
    this.onNavigateToNearestStation,
    this.onContinueTrip,
    this.onDemoRefuel,
  });

  bool get _showDebugDemoButton =>
      refuelDebugToolsEnabled &&
      phase.showsRefuelDebugDemoButton &&
      onDemoRefuel != null;

  @override
  Widget build(BuildContext context) {
    final content = switch (phase) {
      RefuelFlowPhase.needRefuel => _RefuelCardContent(
          key: const ValueKey('refuel_need'),
          accent: IosDesign.warningRed,
          icon: Icons.warning_amber_rounded,
          title: '⚠️ Xăng không đủ để tới điểm đến',
          description:
              'Ứng dụng đề xuất ghé trạm xăng gần nhất trước khi tiếp tục hành trình.',
          actionLabel: 'Tới trạm xăng gần nhất',
          onAction: onNavigateToNearestStation,
        ),
      RefuelFlowPhase.goToGasStation => _RefuelCardContent(
          key: const ValueKey('refuel_enroute'),
          accent: VehicleUi.accentBlue,
          icon: Icons.local_gas_station_rounded,
          title: '⛽ Đang tới trạm xăng',
          description: 'Đang dẫn đường tới trạm xăng gần nhất trên tuyến.',
          showAction: false,
          debugDemoAction: _showDebugDemoButton ? onDemoRefuel : null,
        ),
      RefuelFlowPhase.arrivedGasStation => _RefuelCardContent(
          key: const ValueKey('refuel_arrived'),
          accent: VehicleUi.accentBlue,
          icon: Icons.local_gas_station_rounded,
          title: '⛽ Đã tới trạm xăng',
          description:
              'Sau khi nạp nhiên liệu, bạn có thể tiếp tục hành trình tới điểm đến ban đầu.',
          actionLabel: 'Tiếp tục hành trình',
          onAction: onContinueTrip,
          debugDemoAction: _showDebugDemoButton ? onDemoRefuel : null,
        ),
      RefuelFlowPhase.readyToContinueTrip => _RefuelCardContent(
          key: const ValueKey('refuel_filled'),
          accent: VehicleUi.accentBlue,
          icon: Icons.local_gas_station_rounded,
          title: '⛽ Đã nạp nhiên liệu',
          description:
              'Bạn có thể tiếp tục hành trình tới điểm đến ban đầu.',
          actionLabel: 'Tiếp tục hành trình',
          onAction: onContinueTrip,
        ),
      RefuelFlowPhase.continueTrip => const _RefuelCardContent(
          key: ValueKey('refuel_resume'),
          accent: VehicleUi.accentBlue,
          icon: Icons.navigation_rounded,
          title: 'Tiếp tục hành trình',
          description: 'Đang tính lại lộ trình tới điểm đến ban đầu…',
          showAction: false,
        ),
    };

    return AnimatedSwitcher(
      duration: MicroMotionSpec.slow,
      switchInCurve: MicroMotionSpec.fadeCurve,
      switchOutCurve: MicroMotionSpec.fadeCurve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: content,
    );
  }
}

class _RefuelCardContent extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showAction;
  final VoidCallback? debugDemoAction;

  const _RefuelCardContent({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.showAction = true,
    this.debugDemoAction,
  });

  @override
  Widget build(BuildContext context) {
    final showButton =
        showAction && actionLabel != null && onAction != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: accent,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showButton) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: VehicleUi.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              if (debugDemoAction != null) ...[
                const SizedBox(height: 8),
                _RefuelDebugDemoButton(onPressed: debugDemoAction!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút phụ mô phỏng đổ xăng — chỉ gọi từ HUD khi [refuelDebugToolsEnabled].
class _RefuelDebugDemoButton extends StatelessWidget {
  const _RefuelDebugDemoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.82),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_gas_station_rounded,
            size: 15,
            color: VehicleUi.accentBlue.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          const Text(
            'Demo đã đổ xăng',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
            ),
            child: const Text(
              'DEBUG',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Color(0xFFFFB454),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
