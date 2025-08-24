class AchievementDefinition {
  AchievementDefinition({required this.id, required this.title, required this.eventType, required this.threshold, this.rewardXp = 0});

  final String id;
  final String title;
  final String eventType; // e.g., 'battle_ended', 'fitness_goal_reached'
  final int threshold; // count or value to reach
  final int rewardXp;
}

class AchievementProgress {
  AchievementProgress({required this.defId, this.count = 0, this.unlocked = false});

  final String defId;
  int count;
  bool unlocked;
}