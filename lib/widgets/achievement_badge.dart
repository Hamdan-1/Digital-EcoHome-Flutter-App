import 'package:flutter/material.dart';
import '../models/gamification.dart';
import '../theme.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool showName;

  const AchievementBadge({
    Key? key,
    required this.achievement,
    this.showName = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = achievement.earned
        ? AppTheme.getPrimaryColor(context)
        : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400);
    final bgColor = achievement.earned
        ? color.withOpacity(0.15)
        : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200);

    Widget badgeContent = Container(
      width: showName ? null : 50,
      height: showName ? null : 50,
      padding: EdgeInsets.all(showName ? 12 : 8),
      decoration: BoxDecoration(
        color: bgColor,
        shape: showName ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: showName ? BorderRadius.circular(12) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            color: color,
            size: showName ? 24 : 28,
          ),
          if (showName) ...[
            const SizedBox(height: 8),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ]
        ],
      ),
    );

    return Tooltip(
      message: achievement.earned
          ? "${achievement.name}\n${achievement.description}\n(+${achievement.pointsReward} pts)"
          : "${achievement.name}\n(Locked)",
      preferBelow: false,
      child: badgeContent,
    );
  }
}
