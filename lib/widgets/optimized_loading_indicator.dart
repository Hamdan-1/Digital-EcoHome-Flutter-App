import 'package:flutter/material.dart';
import '../theme.dart';

/// A consistent loading indicator for use throughout the app
class OptimizedLoadingIndicator extends StatelessWidget {
  /// The size of the loading indicator
  final double size;

  /// Optional message to show below the indicator
  final String? message;

  /// Primary color for the loader (defaults to app primary color)
  final Color? color;

  /// Whether to show the indicator on a semi-transparent backdrop
  final bool useBackdrop;

  /// Duration for the animation in milliseconds
  final int animationDurationMs;

  const OptimizedLoadingIndicator({
    Key? key,
    this.size = 40.0,
    this.message,
    this.color,
    this.useBackdrop = false,
    this.animationDurationMs = 1200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final loaderColor = color ?? primaryColor;

    final Widget loadingContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loaderColor.withOpacity(0.2),
                  ),
                ),
              ),

              // Animated progress circle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: animationDurationMs),
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    strokeWidth: 3,
                    value: value,
                    valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
                  );
                },
              ),

              // Optional pulse effect
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: animationDurationMs ~/ 2),
                builder: (context, value, child) {
                  return AnimatedOpacity(
                    opacity: (1 - value).clamp(0.0, 0.5),
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: size * 0.5,
                      height: size * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: loaderColor.withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Optional message
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (useBackdrop) {
      return Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: loadingContent,
            ),
          ),
        ),
      );
    }

    return Center(child: loadingContent);
  }
}

/// Overlay loading indicator that displays on top of existing UI
class OverlayLoadingIndicator extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const OverlayLoadingIndicator({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,

        // Loading overlay (conditionally shown)
        if (isLoading)
          Positioned.fill(
            child: OptimizedLoadingIndicator(
              useBackdrop: true,
              message: message,
            ),
          ),
      ],
    );
  }
}
