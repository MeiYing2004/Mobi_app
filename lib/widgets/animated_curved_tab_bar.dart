import 'package:flutter/material.dart';

/// Một mục trên thanh tab cong (icon + nhãn).
class CurvedTabItem {
  final IconData icon;
  final String label;

  const CurvedTabItem({required this.icon, required this.label});
}

/// Thanh tab đen, mép trên cong ôm bubble tab đang chọn — giống TabBarAnimation iOS.
class AnimatedCurvedTabBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CurvedTabItem> items;
  final Color barColor;
  final Color bubbleColor;
  final Color inactiveColor;

  const AnimatedCurvedTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.barColor = Colors.black,
    this.bubbleColor = const Color(0xFFE8E8E8),
    this.inactiveColor = Colors.white,
  });

  /// Chiều cao phần tab (không gồm safe area) — dùng layout map/sheet.
  static const double barHeight = 64;
  static const double bubbleLift = 28;

  @override
  State<AnimatedCurvedTabBar> createState() => _AnimatedCurvedTabBarState();
}

class _AnimatedCurvedTabBarState extends State<AnimatedCurvedTabBar>
    with SingleTickerProviderStateMixin {
  static const double _bubbleRadius = 34;
  static const double _curveTop = 18;

  late AnimationController _controller;
  int _fromIndex = 0;
  int _toIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _toIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..value = 1;
  }

  @override
  void didUpdateWidget(covariant AnimatedCurvedTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateTo(widget.currentIndex);
    }
  }

  void _animateTo(int index) {
    _fromIndex = _toIndex;
    _toIndex = index;
    _controller.forward(from: 0);
  }

  double _centerX(double width, int index) {
    final count = widget.items.length;
    if (count == 0) return width / 2;
    final slot = width / count;
    return slot * index + slot / 2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final totalH = AnimatedCurvedTabBar.barHeight + bottom + AnimatedCurvedTabBar.bubbleLift;

    return SizedBox(
      height: totalH,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final begin = _centerX(w, _fromIndex);
          final end = _centerX(w, _toIndex);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeInOutCubic.transform(_controller.value);
              final cx = begin + (end - begin) * t;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottom,
                    height: AnimatedCurvedTabBar.barHeight + AnimatedCurvedTabBar.bubbleLift,
                    child: CustomPaint(
                      painter: _CurvedBarPainter(
                        centerX: cx,
                        bubbleRadius: _bubbleRadius,
                        curveTop: _curveTop,
                        color: widget.barColor,
                      ),
                      child: SizedBox(
                        height: AnimatedCurvedTabBar.barHeight + AnimatedCurvedTabBar.bubbleLift,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: AnimatedCurvedTabBar.bubbleLift,
                            bottom: 4,
                          ),
                          child: Row(
                            children: List.generate(widget.items.length, (i) {
                              final item = widget.items[i];
                              final selected = i == widget.currentIndex;
                              return Expanded(
                                child: _TabTapTarget(
                                  icon: item.icon,
                                  label: item.label,
                                  selected: selected,
                                  inactiveColor: widget.inactiveColor,
                                  onTap: () => widget.onTap(i),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: cx - _bubbleRadius,
                    bottom: bottom + AnimatedCurvedTabBar.barHeight - _bubbleRadius + 6,
                    child: IgnorePointer(
                      child: Container(
                        width: _bubbleRadius * 2,
                        height: _bubbleRadius * 2,
                        decoration: BoxDecoration(
                          color: widget.bubbleColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.items[widget.currentIndex].icon,
                          color: Colors.black87,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TabTapTarget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _TabTapTarget({
    required this.icon,
    required this.label,
    required this.selected,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? Colors.transparent : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: inactiveColor.withValues(alpha: selected ? 0.45 : 1),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _CurvedBarPainter extends CustomPainter {
  final double centerX;
  final double bubbleRadius;
  final double curveTop;
  final Color color;

  _CurvedBarPainter({
    required this.centerX,
    required this.bubbleRadius,
    required this.curveTop,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    canvas.drawPath(path, Paint()..color = color);
  }

  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final r = bubbleRadius;
    final top = curveTop;

    final path = Path()..moveTo(0, top);

    final left = centerX - r * 2;
    final right = centerX + r * 2;

    if (left > 0) {
      path.lineTo(left, top);
    }

    path.quadraticBezierTo(centerX - r, top, centerX - r, top - r * 0.15);

    path.arcToPoint(
      Offset(centerX + r, top - r * 0.15),
      radius: Radius.circular(r),
      clockwise: false,
    );

    path.quadraticBezierTo(centerX + r, top, right, top);

    if (right < w) {
      path.lineTo(w, top);
    }

    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _CurvedBarPainter old) {
    return old.centerX != centerX || old.color != color;
  }
}
