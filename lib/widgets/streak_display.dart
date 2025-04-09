import 'package:flutter/material.dart';
import '../theme.dart';

class StreakDisplay extends StatelessWidget {
  final int streakDays;

  const StreakDisplay({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final bool hasStreak = streakDays > 0;
    final Color color =
        hasStreak ? Colors.orange : AppTheme.getTextSecondaryColor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasStreak ? Icons.local_fire_department : Icons.whatshot_outlined,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          '$streakDays Day Streak',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
