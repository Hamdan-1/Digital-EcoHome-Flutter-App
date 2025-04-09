import 'package:flutter/material.dart';
import '../models/sustainability_score.dart';
import '../theme.dart';

class ImprovementTipCard extends StatelessWidget {
  final SustainabilityTip tip;
  final VoidCallback? onTap; // Added onTap callback

  const ImprovementTipCard({
    super.key,
    required this.tip,
    this.onTap, // Accept onTap
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Wrap the Card with Semantics and InkWell for tap interaction
    return Semantics(
      label:
          "Improvement Tip: ${tip.title}. Impact: ${tip.impact}. Tap to learn more.",
      button: true, // Indicate it's interactive
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppTheme.getCardColor(context),
        margin: EdgeInsets.zero,
        clipBehavior:
            Clip.antiAlias, // Ensures InkWell ripple stays within bounds
        child: InkWell(
          onTap: onTap, // Use the provided onTap callback
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align top
              children: [
                // Icon with background circle
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tip.getImpactColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tip.icon,
                    color: tip.getImpactColor(),
                    semanticLabel: "${tip.title} icon",
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: TextStyle(
                          fontSize: 16, // Slightly larger title
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Impact Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tip.getImpactColor().withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tip.impact,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: tip.getImpactColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Add a subtle indicator for tappability if desired
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppTheme.getTextSecondaryColor(
                        context,
                      ).withOpacity(0.6),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
