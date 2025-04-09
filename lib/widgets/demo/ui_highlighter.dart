import 'package:flutter/material.dart';

/// A widget that highlights a target UI element identified by a GlobalKey.
/// It typically draws a cutout or border around the element's bounds.
class UIHighlighter extends StatelessWidget {
  final GlobalKey targetKey;
  final EdgeInsets padding; // Optional padding around the highlight
  final Color overlayColor; // Color of the scrim/overlay
  final double borderRadius; // Optional border radius for the cutout

  const UIHighlighter({
    super.key,
    required this.targetKey,
    this.padding = const EdgeInsets.all(8.0), // Default padding
    this.overlayColor = Colors.black54, // Default overlay color
    this.borderRadius = 8.0, // Default border radius
  });

  @override
  Widget build(BuildContext context) {
    // Use a LayoutBuilder to get constraints and ensure the targetKey context is available
    return LayoutBuilder(
      builder: (context, constraints) {
        final RenderBox? renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.hasSize) {
          // Target element not rendered or sized yet, don't draw highlight
          return const SizedBox.shrink();
        }

        // Get the position and size of the target element relative to the overlay
        final Offset offset = renderBox.localToGlobal(Offset.zero, ancestor: Overlay.of(context).context.findRenderObject());
        final Size size = renderBox.size;

        // Calculate the highlight rectangle with padding
        final Rect targetRect = Rect.fromLTWH(
          offset.dx - padding.left,
          offset.dy - padding.top,
          size.width + padding.horizontal,
          size.height + padding.vertical,
        );

        // Use CustomPaint for flexible drawing (e.g., cutout effect)
        return CustomPaint(
          size: constraints.biggest, // Fill the available space
          painter: _HighlightPainter(
            targetRect: targetRect,
            overlayColor: overlayColor,
            borderRadius: borderRadius,
          ),
        );
      },
    );
  }
}

/// CustomPainter to draw the overlay with a cutout for the highlighted area.
class _HighlightPainter extends CustomPainter {
  final Rect targetRect;
  final Color overlayColor;
  final double borderRadius;

  _HighlightPainter({
    required this.targetRect,
    required this.overlayColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = overlayColor;
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height)); // Full overlay rectangle

    // Create the cutout path (rounded rectangle)
    final Path cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(targetRect, Radius.circular(borderRadius)));

    // Combine the paths using PathOperation.difference to create the cutout effect
    final Path finalPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      cutoutPath,
    );

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) {
    // Repaint if target rectangle, color, or radius changes
    return oldDelegate.targetRect != targetRect ||
           oldDelegate.overlayColor != overlayColor ||
           oldDelegate.borderRadius != borderRadius;
  }
}