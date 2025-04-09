import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Assuming fl_chart is used
import '../theme.dart';
import 'dart:math' as math;

class NeighborhoodRankingChart extends StatelessWidget {
  final double userScore;
  final List<double> neighborhoodScores;
  final double averageScore;

  const NeighborhoodRankingChart({
    Key? key,
    required this.userScore,
    required this.neighborhoodScores,
    required this.averageScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Removed the SingleChildScrollView wrapper from the previous step.
    // The parent SizedBox(height: 150) provides the height constraint.
    return Semantics( // Added Semantics for accessibility context
      label: "Neighborhood comparison chart. Your score is ${userScore.toStringAsFixed(0)}. The average score is ${averageScore.toStringAsFixed(0)}.",
      child: Column( // This Column must fit within the parent's height (e.g., 150px)
        mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
        children: [
          // Ensure the chart takes most, but not all, available height
          Expanded( // Use Expanded to allow the chart to fill available space
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0), // Add some padding around chart
              child: _buildChart(context), // Assuming a helper builds the chart
            ),
          ),
          // Text below the chart - ensure it doesn't cause overflow
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0), // Reduced bottom padding
            child: Text(
              'Your Score (Green) vs. Avg (Grey)', // More descriptive legend
              style: TextStyle(
                fontSize: 10, // Keep font size small
                color: AppTheme.getTextSecondaryColor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder for chart building logic (adapt to your actual implementation)
  Widget _buildChart(BuildContext context) {
    // Example using BarChart - replace with your actual chart code
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100, // Ensure maxY is appropriate
        barGroups: [
          // Example data points
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(
              toY: averageScore.clamp(0, 100), // Clamp values
              color: Colors.grey.shade400, // Lighter grey
              width: 20, // Adjust width as needed
              borderRadius: BorderRadius.circular(4)
            ),
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
              toY: userScore.clamp(0, 100), // Clamp values
              color: AppTheme.getPrimaryColor(context),
              width: 20, // Adjust width as needed
              borderRadius: BorderRadius.circular(4)
            ),
          ]),
        ],
        titlesData: FlTitlesData(show: false), // Hide titles to save space
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false), // Hide grid to save space
        barTouchData: BarTouchData(enabled: false), // Disable touch if not needed
      ),
      // swapAnimationDuration: Duration(milliseconds: 150), // Optional animation
    );
  }
}
