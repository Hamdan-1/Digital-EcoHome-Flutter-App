import 'package:flutter/material.dart';

/// Animation utilities for consistent animations across the app
class AnimationUtils {
  /// Standard durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  /// Standard curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve reverseCurve = Curves.easeInCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeInOutQuart;

  /// Page transition builder for routes
  static Widget pageTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 0.05);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// Custom route that uses our page transition
  static Route<T> createRoute<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: medium,
      reverseTransitionDuration: medium,
      transitionsBuilder: pageTransition,
    );
  }

  /// Creates a pulse animation controller
  static AnimationController createPulseController(
    TickerProvider vsync, {
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return AnimationController(vsync: vsync, duration: duration)
      ..repeat(reverse: true);
  }

  /// Creates a pulse animation
  static Animation<double> createPulseAnimation(
    AnimationController controller,
  ) {
    return Tween<double>(
      begin: 0.97,
      end: 1.03,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  /// Staggered list item animation
  static Animation<double> createListItemAnimation(
    AnimationController controller,
    int index, {
    int itemCount = 20,
    Duration totalDuration = const Duration(milliseconds: 800),
  }) {
    // Calculate the delay for each item
    final double delay = index / itemCount;

    // Create the interval based on the delay
    final interval = Interval(delay, delay + 0.2, curve: Curves.easeOutCubic);

    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: interval));
  }
}

/// A reusable animated scale button for better tap feedback
class AnimatedTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleAmount;
  final Duration duration;
  final Color? splashColor;
  final BorderRadius? borderRadius;

  const AnimatedTapButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleAmount = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.splashColor,
    this.borderRadius,
  });

  @override
  State<AnimatedTapButton> createState() => _AnimatedTapButtonState();
}

class _AnimatedTapButtonState extends State<AnimatedTapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleAmount,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius =
        widget.borderRadius ?? BorderRadius.circular(12.0);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: widget.splashColor,
                  borderRadius: borderRadius,
                  onTap: () {}, // We handle taps manually with GestureDetector
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A widget that animates its size when the child changes
class AnimatedSizeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;

  const AnimatedSizeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.alignment = Alignment.center,
  });

  @override
  State<AnimatedSizeWidget> createState() => _AnimatedSizeWidgetState();
}

class _AnimatedSizeWidgetState extends State<AnimatedSizeWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: widget.duration,
      curve: widget.curve,
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}

/// A widget that shows a loading indicator with a subtle animation
class AnimatedProgressIndicator extends StatefulWidget {
  final double value;
  final Color color;
  final double height;
  final Duration duration;

  const AnimatedProgressIndicator({
    super.key,
    required this.value,
    required this.color,
    this.height = 6.0,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedProgressIndicator> createState() =>
      _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
            child: Row(
              children: [
                Flexible(
                  flex: (_animation.value * 100).toInt(),
                  child: Container(color: widget.color),
                ),
                Flexible(
                  flex: 100 - (_animation.value * 100).toInt(),
                  child: Container(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A widget that shows a pulsing highlight
class PulsingHighlight extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;

  const PulsingHighlight({
    super.key,
    required this.child,
    required this.color,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<PulsingHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _opacityAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: widget.color.withAlpha((_opacityAnimation.value * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          },
        ),
      ],
    );
  }
}
