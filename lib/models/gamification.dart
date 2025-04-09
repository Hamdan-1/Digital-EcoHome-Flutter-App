import 'package:flutter/material.dart';

enum ChallengeType { daily, weekly }

enum ChallengeStatus { active, completed, failed }

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int pointsReward;
  final IconData icon;
  final DateTime expiryDate;
  ChallengeStatus status;
  double progress; // 0.0 to 1.0
  final double targetValue; // e.g., target kWh reduction
  final String unit; // e.g., 'kWh', '%'

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.pointsReward,
    required this.icon,
    required this.expiryDate,
    this.status = ChallengeStatus.active,
    this.progress = 0.0,
    required this.targetValue,
    required this.unit,
  });
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int pointsReward;
  final bool earned;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.pointsReward,
    this.earned = false,
  });

  Achievement copyWith({bool? earned}) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      icon: icon,
      pointsReward: pointsReward,
      earned: earned ?? this.earned,
    );
  }
}

class GamificationState {
  final int points;
  final int level;
  final int streakDays;
  final List<Challenge> activeChallenges;
  final List<Achievement> earnedAchievements;
  final DateTime? lastStreakUpdate;

  GamificationState({
    this.points = 0,
    this.level = 1,
    this.streakDays = 0,
    this.activeChallenges = const [],
    this.earnedAchievements = const [],
    this.lastStreakUpdate,
  });

  // Example: Calculate level based on points
  int calculateLevel() {
    return (points / 500).floor() + 1; // Example: New level every 500 points
  }

  GamificationState copyWith({
    int? points,
    int? level,
    int? streakDays,
    List<Challenge>? activeChallenges,
    List<Achievement>? earnedAchievements,
    DateTime? lastStreakUpdate,
  }) {
    return GamificationState(
      points: points ?? this.points,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      activeChallenges: activeChallenges ?? this.activeChallenges,
      earnedAchievements: earnedAchievements ?? this.earnedAchievements,
      lastStreakUpdate: lastStreakUpdate ?? this.lastStreakUpdate,
    );
  }
}
