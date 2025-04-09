import 'package:flutter/material.dart';
import '../models/sustainability_score.dart';
import '../theme.dart';

/// A widget to display a single sustainability factor with its impact on score
class FactorListItem extends StatelessWidget {
  final SustainabilityFactor factor;

  const FactorListItem({Key? key, required this.factor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scoreColor = factor.isPositive
        ? AppTheme.getPrimaryColor(context)
        : Colors.orange; // Or use a specific negative color

    // Wrap the content in a Card
    return Card(
      elevation: 1, // Subtle elevation
      margin: EdgeInsets.zero, // Let the parent handle margin/padding
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.getCardColor(context),
      child: Semantics(
        label: "${factor.name}, Score impact: ${factor.score > 0 ? '+' : ''}${factor.score.toStringAsFixed(0)}. Description: ${factor.description}",
        child: Padding(
          // Add internal padding to the card
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
            children: [
              // Icon with background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  factor.icon,
                  semanticLabel: "${factor.name} icon",
                  color: scoreColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16), // Increased spacing
              // Factor details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      factor.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15, // Slightly larger font
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      factor.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Score impact
              Text(
                "${factor.score > 0 ? '+' : ''}${factor.score.toStringAsFixed(0)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Larger score font
                  color: scoreColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
