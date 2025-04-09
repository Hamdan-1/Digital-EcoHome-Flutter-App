import 'package:flutter/material.dart';
import '../models/gamification.dart';
import '../theme.dart';
import 'package:intl/intl.dart'; // For date formatting

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const ChallengeCard({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timeRemaining = challenge.expiryDate.difference(DateTime.now());
    final bool isExpired = timeRemaining.isNegative;
    final String timeStr = isExpired
        ? "Expired"
        : (timeRemaining.inHours > 0
            ? "${timeRemaining.inHours}h left"
            : "${timeRemaining.inMinutes}m left");

    Color progressColor = AppTheme.getPrimaryColor(context);
    if (challenge.status == ChallengeStatus.completed) {
      progressColor = Colors.green;
    } else if (challenge.status == ChallengeStatus.failed || isExpired) {
      progressColor = Colors.red;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppTheme.getCardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(challenge.icon, color: progressColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${challenge.pointsReward} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getPrimaryColor(context),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired ? Colors.red : AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (challenge.status == ChallengeStatus.active && !isExpired)
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: challenge.progress,
                      backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(challenge.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            if (challenge.status == ChallengeStatus.completed)
              Text(
                'Completed!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            if (challenge.status == ChallengeStatus.failed || (isExpired && challenge.status != ChallengeStatus.completed))
              Text(
                'Failed',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
