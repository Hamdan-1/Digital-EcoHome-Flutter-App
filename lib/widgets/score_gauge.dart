import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A gauge widget that displays a sustainability score
class ScoreGauge extends StatelessWidget {
  final double score; // 0-100 score
  final String
  scoreLabel; // Text label for the score (e.g., "Good", "Excellent")
  final Color scoreColor; // Color associated with the score

  const ScoreGauge({
    Key? key,
    required this.score,
    required this.scoreLabel,
    required this.scoreColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          "Sustainability Score Gauge. Score: ${score.toStringAsFixed(0)} out of 100. Rating: $scoreLabel.",
      value: score.toStringAsFixed(0), // Provide numeric value
      child: SizedBox(
        height: 200,
        width: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gauge background
            CustomPaint(
              size: const Size(200, 200),
              painter: GaugePainter(score: score, scoreColor: scoreColor),
            ),

            // Score and label in the center
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the gauge arc
class GaugePainter extends CustomPainter {
  final double score;
  final Color scoreColor;

  GaugePainter({required this.score, required this.scoreColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw the gauge background (grey track)
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round;

    // Draw the gauge arc (colored progress)
    final progressPaint =
        Paint()
          ..color = scoreColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round;

    // Draw background track (270 degrees arc)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      math.pi * 0.75, // Start at 135 degrees (top-left)
      math.pi * 1.5, // 270 degrees arc
      false,
      backgroundPaint,
    );

    // Draw progress arc
    final progressAngle =
        (score / 100) * math.pi * 1.5; // Convert score to angle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      math.pi * 0.75, // Start at 135 degrees
      progressAngle, // Arc based on score
      false,
      progressPaint,
    );

    // Draw tick marks
    _drawTickMarks(canvas, center, radius);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final tickPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 10; i++) {
      // Calculate angle for each tick mark
      // We want ticks evenly distributed across the 270 degree arc
      final angle = math.pi * 0.75 + (math.pi * 1.5 * i / 10);

      // Calculate start and end points for tick marks
      final outerPoint = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 20) * math.cos(angle),
        center.dy + (radius - 20) * math.sin(angle),
      );

      // Draw longer ticks for 0, 50, 100
      if (i == 0 || i == 5 || i == 10) {
        final innerLongPoint = Offset(
          center.dx + (radius - 25) * math.cos(angle),
          center.dy + (radius - 25) * math.sin(angle),
        );
        canvas.drawLine(outerPoint, innerLongPoint, tickPaint..strokeWidth = 2);

        // Add labels for 0, 50, 100
        final textPainter = TextPainter(
          text: TextSpan(
            text: (i * 10).toString(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        final labelPoint = Offset(
          center.dx + (radius - 40) * math.cos(angle) - textPainter.width / 2,
          center.dy + (radius - 40) * math.sin(angle) - textPainter.height / 2,
        );

        textPainter.paint(canvas, labelPoint);
      } else {
        canvas.drawLine(outerPoint, innerPoint, tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.scoreColor != scoreColor;
  }
}
