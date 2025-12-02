import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _rippleControllers;
  late List<Animation<double>> _rippleAnimations;
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();

    // Initialize ripple animations
    _rippleControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _rippleAnimations = _rippleControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    // Initialize scale animations
    _scaleControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _scaleAnimations = _scaleControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Set initial scale for selected item
    if (widget.currentIndex < _scaleControllers.length) {
      _scaleControllers[widget.currentIndex].value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Animate scale for new selection
      if (oldWidget.currentIndex < _scaleControllers.length) {
        _scaleControllers[oldWidget.currentIndex].reverse();
      }
      if (widget.currentIndex < _scaleControllers.length) {
        _scaleControllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _rippleControllers) {
      controller.dispose();
    }
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    // Trigger ripple animation
    _rippleControllers[index].forward(from: 0.0);
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.purple.withOpacity(0.3)
                : Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1A1F3A).withOpacity(0.9),
                        const Color(0xFF0A0E27).withOpacity(0.95),
                      ]
                    : [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.9),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.purple.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.items.length, (index) {
                return _buildNavItem(index, isDark);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final isSelected = widget.currentIndex == index;
    final item = widget.items[index];

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTap(index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect
            AnimatedBuilder(
              animation: _rippleAnimations[index],
              builder: (context, child) {
                return CustomPaint(
                  painter: RipplePainter(
                    progress: _rippleAnimations[index].value,
                    color: isDark
                        ? Colors.purple.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.2),
                  ),
                  child: const SizedBox(width: 80, height: 80),
                );
              },
            ),
            // Icon and label
            AnimatedBuilder(
              animation: _scaleAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? _scaleAnimations[index].value : 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: isDark
                                          ? [
                                              Colors.purple.withOpacity(0.3),
                                              Colors.blue.withOpacity(0.3),
                                            ]
                                          : [
                                              Colors.blue.withOpacity(0.2),
                                              Colors.purple.withOpacity(0.2),
                                            ],
                                    )
                                  : null,
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected
                                  ? (isDark
                                      ? Colors.purple[300]
                                      : Colors.blue[700])
                                  : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                              size: 26,
                            ),
                          ),
                          // Badge
                          if (item.badge != null)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: item.badge!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Label
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: isSelected ? 12 : 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.purple[300] : Colors.blue[700])
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final radius = maxRadius * progress;
    final opacity = (1 - progress) * 0.5;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);

    // Draw outer ring
    final ringPaint = Paint()
      ..color = color.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget? badge;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });
}
