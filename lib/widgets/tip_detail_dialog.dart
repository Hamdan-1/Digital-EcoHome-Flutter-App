import 'package:flutter/material.dart';
import '../models/sustainability_score.dart'; // Assuming SustainabilityTip is here
import '../theme.dart'; // For consistent styling

class TipDetailDialog extends StatelessWidget {
  final SustainabilityTip tip;

  const TipDetailDialog({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Rounded corners
      ),
      backgroundColor: Theme.of(context).cardColor, // Use theme card color
      title: Row(
        children: [
          Icon(tip.icon, color: tip.getImpactColor(), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip.title,
              style: TextStyle(
                fontSize: 18, // Slightly smaller for dialog title
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView( // Ensure content scrolls if too long
        child: Column(
          mainAxisSize: MainAxisSize.min, // Take minimum space needed
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tip.impact,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tip.getImpactColor(),
                fontSize: 14,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            Text(
              tip.detailedDescription,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.getTextSecondaryColor(context),
                height: 1.4, // Improve readability
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'Close',
            style: TextStyle(color: AppTheme.getPrimaryColor(context)),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }
}