import 'package:flutter/material.dart';

/// A widget that shows a tooltip pointing to a specific UI element
class TargetedTooltip extends StatelessWidget {
  /// The global key of the widget to target
  final GlobalKey targetKey;
  
  /// The tooltip message to display
  final String message;
  
  /// Optional icon to display in the tooltip
  final IconData? icon;
  
  /// Background color of the tooltip (defaults to primaryColor)
  final Color? backgroundColor;
  
  /// Text color of the tooltip (defaults to white)
  final Color textColor;
  
  /// Tooltip position relative to target (auto-calculated if null)
  final TargetedTooltipPosition? preferredPosition;
  
  /// Callback when tooltip is dismissed
  final VoidCallback? onDismiss;

  const TargetedTooltip({
    Key? key,
    required this.targetKey,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.preferredPosition,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor;
    
    return Positioned.fill(
      child: Stack(
        children: [
          // Semi-transparent overlay to dim the background
          GestureDetector(
            onTap: onDismiss,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          
          // The actual tooltip (positioned in overlay)
          _buildPositionedTooltip(context, bgColor),
        ],
      ),
    );
  }
  
  Widget _buildPositionedTooltip(BuildContext context, Color bgColor) {
    // Try to find target widget position
    final RenderBox? targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox == null) {
      // If target not found, show tooltip in center
      return Center(
        child: _buildTooltipContent(context, bgColor),
      );
    }
    
    // Get target widget position in overlay
    final targetPosition = targetBox.localToGlobal(Offset.zero);
    final targetSize = targetBox.size;
    
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate best position for tooltip
    final position = _calculateTooltipPosition(
      targetPosition: targetPosition,
      targetSize: targetSize,
      screenSize: screenSize,
      tooltipHeight: 120, // Approximate height
      tooltipWidth: 280, // Fixed width
    );
    
    // Draw an arrow to point at the target
    return Stack(
      children: [
        // Cutout for the target widget (to highlight it)
        Positioned(
          left: targetPosition.dx - 8,
          top: targetPosition.dy - 8,
          width: targetSize.width + 16,
          height: targetSize.height + 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: bgColor, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // Tooltip content
        Positioned(
          left: position.dx,
          top: position.dy,
          child: _buildTooltipContent(context, bgColor),
        ),
        
        // Connection line from tooltip to target
        CustomPaint(
          painter: _ArrowPainter(
            start: Offset(
              position.dx + 140, // Center of tooltip
              position.dy + (position.dy > targetPosition.dy ? 0 : 120) // Top or bottom based on position
            ),
            end: Offset(
              targetPosition.dx + targetSize.width / 2, // Center of target
              targetPosition.dy + targetSize.height / 2, // Center of target
            ),
            color: bgColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTooltipContent(BuildContext context, Color bgColor) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 8),
          ],
          Text(
            message,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              child: Text(
                'GOT IT',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Offset _calculateTooltipPosition({
    required Offset targetPosition,
    required Size targetSize,
    required Size screenSize,
    required double tooltipHeight,
    required double tooltipWidth,
  }) {
    // Default to centered above target
    TargetedTooltipPosition position = preferredPosition ?? TargetedTooltipPosition.above;
    
    // Calculate target center
    final targetCenterX = targetPosition.dx + targetSize.width / 2;
    
    // Check if there's room above
    if (position == TargetedTooltipPosition.above && targetPosition.dy < tooltipHeight + 20) {
      position = TargetedTooltipPosition.below;
    }
    
    // Check if there's room below
    if (position == TargetedTooltipPosition.below && 
        targetPosition.dy + targetSize.height + tooltipHeight + 20 > screenSize.height) {
      position = TargetedTooltipPosition.above;
    }
    
    // If still no good position, try left or right
    if ((position == TargetedTooltipPosition.above && targetPosition.dy < tooltipHeight + 20) ||
        (position == TargetedTooltipPosition.below && 
         targetPosition.dy + targetSize.height + tooltipHeight + 20 > screenSize.height)) {
      // Try left
      if (targetCenterX > screenSize.width / 2) {
        position = TargetedTooltipPosition.left;
      } else {
        position = TargetedTooltipPosition.right;
      }
    }
    
    // Calculate position based on chosen direction
    switch (position) {
      case TargetedTooltipPosition.above:
        return Offset(
          targetCenterX - (tooltipWidth / 2).clamp(0, screenSize.width - tooltipWidth),
          targetPosition.dy - tooltipHeight - 20,
        );
      case TargetedTooltipPosition.below:
        return Offset(
          targetCenterX - (tooltipWidth / 2).clamp(0, screenSize.width - tooltipWidth),
          targetPosition.dy + targetSize.height + 20,
        );
      case TargetedTooltipPosition.left:
        return Offset(
          targetPosition.dx - tooltipWidth - 20,
          targetPosition.dy + (targetSize.height / 2) - (tooltipHeight / 2),
        );
      case TargetedTooltipPosition.right:
        return Offset(
          targetPosition.dx + targetSize.width + 20,
          targetPosition.dy + (targetSize.height / 2) - (tooltipHeight / 2),
        );
    }
  }
}

/// Enum for tooltip position relative to target
enum TargetedTooltipPosition {
  above,
  below,
  left,
  right,
}

/// Custom painter to draw an arrow from tooltip to target
class _ArrowPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  
  _ArrowPainter({
    required this.start,
    required this.end,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw a curved line
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2,
        start.dy,
        end.dx,
        end.dy,
      );
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) {
    return start != oldDelegate.start ||
           end != oldDelegate.end ||
           color != oldDelegate.color;
  }
}
