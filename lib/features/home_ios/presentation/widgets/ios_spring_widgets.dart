import 'package:flutter/material.dart';

import 'package:fuel_tracker_app/features/home_ios/core/ios_spring.dart';

/// Scale spring — nhấn instant 0.96, thả spring về 1.0.
class IosSpringPressable extends StatefulWidget {
  const IosSpringPressable({
    super.key,
    required this.child,
    this.pressedScale = 0.96,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  final Widget child;
  final double pressedScale;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;

  @override
  State<IosSpringPressable> createState() => _IosSpringPressableState();
}

class _IosSpringPressableState extends State<IosSpringPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      value: 1,
      duration: IosSpring.nominalDuration,
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _down(TapDownDetails d) {
    widget.onTapDown?.call(d);
    if (!widget.enabled) return;
    _scale.value = widget.pressedScale;
  }

  void _up(TapUpDetails d) {
    widget.onTapUp?.call(d);
    _release();
  }

  void _cancel() {
    widget.onTapCancel?.call();
    _release();
  }

  void _release() {
    if (!widget.enabled) return;
    IosSpring.animate(
      _scale,
      target: 1,
      spring: IosSpring.pressRelease,
      velocity: _scale.velocity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

/// Animate width/height bằng spring khi thay đổi (Dynamic Island).
class IosSpringSizeBox extends StatefulWidget {
  const IosSpringSizeBox({
    super.key,
    required this.width,
    required this.height,
    required this.builder,
    this.spring = IosSpring.island,
  });

  final double width;
  final double height;
  final SpringDescription spring;
  final Widget Function(BuildContext context, double width, double height) builder;

  @override
  State<IosSpringSizeBox> createState() => _IosSpringSizeBoxState();
}

class _IosSpringSizeBoxState extends State<IosSpringSizeBox>
    with TickerProviderStateMixin {
  late AnimationController _w;
  late AnimationController _h;

  @override
  void initState() {
    super.initState();
    _w = AnimationController.unbounded(
      vsync: this,
      value: widget.width,
    );
    _h = AnimationController.unbounded(
      vsync: this,
      value: widget.height,
    );
  }

  @override
  void didUpdateWidget(IosSpringSizeBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width) {
      IosSpring.animate(
        _w,
        target: widget.width,
        spring: widget.spring,
        velocity: _w.velocity,
      );
    }
    if (oldWidget.height != widget.height) {
      IosSpring.animate(
        _h,
        target: widget.height,
        spring: widget.spring,
        velocity: _h.velocity,
      );
    }
  }

  @override
  void dispose() {
    _w.dispose();
    _h.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_w, _h]),
      builder: (context, _) => widget.builder(context, _w.value, _h.value),
    );
  }
}

/// Page dot — width spring khi đổi trang (thay AnimatedContainer).
class IosSpringPageDot extends StatefulWidget {
  const IosSpringPageDot({
    super.key,
    required this.active,
    required this.inactiveWidth,
    required this.activeWidth,
    required this.height,
    this.margin,
  });

  final bool active;
  final double inactiveWidth;
  final double activeWidth;
  final double height;
  final EdgeInsetsGeometry? margin;

  @override
  State<IosSpringPageDot> createState() => _IosSpringPageDotState();
}

class _IosSpringPageDotState extends State<IosSpringPageDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _width;

  @override
  void initState() {
    super.initState();
    _width = AnimationController.unbounded(
      vsync: this,
      value: widget.active ? widget.activeWidth : widget.inactiveWidth,
    );
  }

  @override
  void didUpdateWidget(IosSpringPageDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      IosSpring.animate(
        _width,
        target: widget.active ? widget.activeWidth : widget.inactiveWidth,
        spring: IosSpring.snappy,
        velocity: _width.velocity,
      );
    }
  }

  @override
  void dispose() {
    _width.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _width,
      builder: (context, _) {
        return Container(
          width: _width.value,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(widget.height),
          ),
        );
      },
    );
  }
}

/// Panel trượt từ trên — spring UIKit (~300ms), thay Curves.easeOutCubic.
class IosSpringSlidePanel extends StatefulWidget {
  const IosSpringSlidePanel({
    super.key,
    required this.child,
    this.spring = IosSpring.openApp,
  });

  final Widget child;
  final SpringDescription spring;

  @override
  State<IosSpringSlidePanel> createState() => _IosSpringSlidePanelState();
}

class _IosSpringSlidePanelState extends State<IosSpringSlidePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _slide;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, value: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        IosSpring.animate(_slide, target: 1, spring: widget.spring);
      }
    });
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slide,
      builder: (context, child) {
        return FractionalTranslation(
          translation: Offset(0, -1 + _slide.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
