import 'package:flutter/material.dart';
import 'dart:math' as math;

class DarkModeToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color lightColor;
  final Color darkColor;
  final Duration animationDuration;

  const DarkModeToggle({
    Key? key,
    required this.value,
    required this.onChanged,
    this.lightColor = const Color(0xFFFDB813), // Sun yellow
    this.darkColor = const Color(0xFF3F51B5), // Dark blue
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<DarkModeToggle> createState() => _DarkModeToggleState();
}

class _DarkModeToggleState extends State<DarkModeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: widget.value ? 1.0 : 0.0,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(DarkModeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: 80,
            height: 40,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  widget.lightColor,
                  const Color(0xFFFF9800), // Orange transition
                  const Color(0xFF7E57C2), // Purple transition
                  widget.darkColor,
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
                transform: GradientRotation(
                  _animationController.value * math.pi,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Track decorations - stars (only visible in dark mode)
                ...List.generate(5, (index) {
                  double offset = index * 15.0;
                  return Positioned(
                    left: 10 + offset,
                    top: index % 2 == 0 ? 8 : 22,
                    child: Opacity(
                      opacity: _animationController.value,
                      child: Container(
                        width: 2,
                        height: 2,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),

                // Thumb
                AnimatedPositioned(
                  duration: widget.animationDuration,
                  curve: Curves.easeInOut,
                  left: widget.value ? 40 : 0,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * math.pi * 2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child:
                            widget.value
                                // Moon icon in dark mode
                                ? const Center(
                                  child: Icon(
                                    Icons.nightlight_round,
                                    size: 18,
                                    color: Color(0xFF3F51B5),
                                  ),
                                )
                                // Sun icon in light mode
                                : const Center(
                                  child: Icon(
                                    Icons.wb_sunny,
                                    size: 18,
                                    color: Color(0xFFFDB813),
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
