import 'dart:math';
import '../../../data/models/quest_model.dart';
import '../../../data/models/character_model.dart';

class QuestSocialService {
  static final QuestSocialService _instance = QuestSocialService._internal();
  factory QuestSocialService() => _instance;
  QuestSocialService._internal();

  final Random _random = Random();

  /// Create a shared quest that multiple players can participate in
  SharedQuest createSharedQuest({
    required Quest baseQuest,
    required Character creator,
    required int maxParticipants,
    required SharedQuestType type,
  }) {
    return SharedQuest(
      id: 'shared_${baseQuest.id}_${DateTime.now().millisecondsSinceEpoch}',
      baseQuest: baseQuest,
      creator: creator,
      participants: [creator],
      maxParticipants: maxParticipants,
      type: type,
      status: SharedQuestStatus.recruiting,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      rewards: _calculateSharedRewards(baseQuest, maxParticipants),
    );
  }

  /// Join a shared quest
  bool joinSharedQuest(SharedQuest sharedQuest, Character player) {
    if (sharedQuest.participants.length >= sharedQuest.maxParticipants) {
      return false; // Quest is full
    }
    
    if (sharedQuest.participants.any((p) => p.id == player.id)) {
      return false; // Player already joined
    }
    
    if (sharedQuest.status != SharedQuestStatus.recruiting) {
      return false; // Quest is not recruiting
    }
    
    sharedQuest.participants.add(player);
    
    // Check if quest should start
    if (sharedQuest.participants.length >= sharedQuest.maxParticipants) {
      sharedQuest.status = SharedQuestStatus.inProgress;
    }
    
    return true;
  }

  /// Leave a shared quest
  bool leaveSharedQuest(SharedQuest sharedQuest, Character player) {
    final wasRemoved = sharedQuest.participants.removeWhere((p) => p.id == player.id) > 0;
    
    if (wasRemoved && sharedQuest.status == SharedQuestStatus.inProgress) {
      // If quest was in progress and someone left, check if we should pause it
      if (sharedQuest.participants.length < sharedQuest.maxParticipants) {
        sharedQuest.status = SharedQuestStatus.paused;
      }
    }
    
    return wasRemoved;
  }

  /// Update shared quest progress
  void updateSharedQuestProgress(SharedQuest sharedQuest, String playerId, int progress) {
    final participant = sharedQuest.participants.firstWhere((p) => p.id == playerId);
    final participantIndex = sharedQuest.participants.indexOf(participant);
    
    if (participantIndex >= 0) {
      sharedQuest.participantProgress[playerId] = progress;
      
      // Check if all participants have completed the quest
      final allCompleted = sharedQuest.participants.every((p) {
        final playerProgress = sharedQuest.participantProgress[p.id] ?? 0;
        return playerProgress >= sharedQuest.baseQuest.objectives.first.target;
      });
      
      if (allCompleted) {
        sharedQuest.status = SharedQuestStatus.completed;
        _distributeSharedRewards(sharedQuest);
      }
    }
  }

  /// Create a team quest that requires coordination
  TeamQuest createTeamQuest({
    required String title,
    required String description,
    required List<TeamRole> requiredRoles,
    required LatLng location,
    required int playerLevel,
  }) {
    final objectives = _generateTeamObjectives(requiredRoles);
    
    return TeamQuest(
      id: 'team_quest_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      requiredRoles: requiredRoles,
      objectives: objectives,
      location: location,
      status: TeamQuestStatus.recruiting,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
      rewards: _calculateTeamRewards(requiredRoles.length, playerLevel),
    );
  }

  /// Join a team quest with a specific role
  bool joinTeamQuest(TeamQuest teamQuest, Character player, TeamRole role) {
    if (teamQuest.status != TeamQuestStatus.recruiting) {
      return false; // Quest is not recruiting
    }
    
    // Check if role is still needed
    final roleCount = teamQuest.members.where((m) => m.role == role).length;
    final requiredCount = teamQuest.requiredRoles.where((r) => r == role).length;
    
    if (roleCount >= requiredCount) {
      return false; // Role is full
    }
    
    // Check if player already joined
    if (teamQuest.members.any((m) => m.character.id == player.id)) {
      return false; // Player already joined
    }
    
    teamQuest.members.add(TeamMember(character: player, role: role));
    
    // Check if all roles are filled
    final allRolesFilled = teamQuest.requiredRoles.every((role) {
      final roleCount = teamQuest.members.where((m) => m.role == role).length;
      final requiredCount = teamQuest.requiredRoles.where((r) => r == role).length;
      return roleCount >= requiredCount;
    });
    
    if (allRolesFilled) {
      teamQuest.status = TeamQuestStatus.inProgress;
    }
    
    return true;
  }

  /// Create a quest challenge
  QuestChallenge createQuestChallenge({
    required Quest quest,
    required Character challenger,
    required ChallengeType type,
    required int targetValue,
  }) {
    return QuestChallenge(
      id: 'challenge_${quest.id}_${DateTime.now().millisecondsSinceEpoch}',
      quest: quest,
      challenger: challenger,
      type: type,
      targetValue: targetValue,
      status: ChallengeStatus.active,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      participants: [challenger],
      leaderboard: [ChallengeEntry(challenger: challenger, value: 0)],
    );
  }

  /// Join a quest challenge
  bool joinQuestChallenge(QuestChallenge challenge, Character player) {
    if (challenge.status != ChallengeStatus.active) {
      return false; // Challenge is not active
    }
    
    if (challenge.participants.any((p) => p.id == player.id)) {
      return false; // Player already joined
    }
    
    challenge.participants.add(player);
    challenge.leaderboard.add(ChallengeEntry(challenger: player, value: 0));
    
    return true;
  }

  /// Update challenge progress
  void updateChallengeProgress(QuestChallenge challenge, Character player, int value) {
    final entry = challenge.leaderboard.firstWhere((e) => e.challenger.id == player.id);
    entry.value = value;
    
    // Sort leaderboard
    challenge.leaderboard.sort((a, b) => b.value.compareTo(a.value));
    
    // Check if challenge is completed
    final winner = challenge.leaderboard.first;
    if (winner.value >= challenge.targetValue) {
      challenge.status = ChallengeStatus.completed;
      challenge.winner = winner.challenger;
    }
  }

  /// Create a quest recommendation
  QuestRecommendation createQuestRecommendation({
    required Quest quest,
    required Character recommender,
    required String reason,
    required double rating,
  }) {
    return QuestRecommendation(
      id: 'recommendation_${quest.id}_${DateTime.now().millisecondsSinceEpoch}',
      quest: quest,
      recommender: recommender,
      reason: reason,
      rating: rating,
      createdAt: DateTime.now(),
      likes: 0,
      dislikes: 0,
    );
  }

  /// Like or dislike a recommendation
  void rateRecommendation(QuestRecommendation recommendation, Character player, bool isLike) {
    // Simple implementation - in a real app, you'd track who rated what
    if (isLike) {
      recommendation.likes++;
    } else {
      recommendation.dislikes++;
    }
  }

  /// Get quest recommendations for a player
  List<QuestRecommendation> getQuestRecommendations(Character player, List<Quest> availableQuests) {
    final recommendations = <QuestRecommendation>[];
    
    // Generate some sample recommendations
    for (final quest in availableQuests.take(5)) {
      final reason = _generateRecommendationReason(quest, player);
      final rating = 3.0 + (_random.nextDouble() * 2.0); // 3.0-5.0 rating
      
      recommendations.add(createQuestRecommendation(
        quest: quest,
        recommender: player,
        reason: reason,
        rating: rating,
      ));
    }
    
    return recommendations;
  }

  QuestRewards _calculateSharedRewards(Quest baseQuest, int participantCount) {
    final baseRewards = baseQuest.rewards;
    
    // Shared quests give bonus rewards based on participant count
    final participantBonus = participantCount * 0.2; // 20% bonus per participant
    
    return QuestRewards(
      xp: (baseRewards.xp * (1 + participantBonus)).round(),
      gold: (baseRewards.gold * (1 + participantBonus)).round(),
      gems: baseRewards.gems + participantCount,
      items: [...baseRewards.items, 'shared_quest_token'],
      skillPoints: baseRewards.skillPoints,
    );
  }

  void _distributeSharedRewards(SharedQuest sharedQuest) {
    // In a real implementation, you'd distribute rewards to all participants
    // For now, we'll just mark the quest as completed
    sharedQuest.status = SharedQuestStatus.completed;
  }

  List<QuestObjective> _generateTeamObjectives(List<TeamRole> roles) {
    final objectives = <QuestObjective>[];
    
    for (final role in roles) {
      objectives.add(QuestObjective(
        id: 'complete_${role.name}_task',
        description: 'Complete your role as ${role.displayName}',
        target: 1,
        progress: 0,
        type: 'team_role',
      ));
    }
    
    // Add team coordination objective
    objectives.add(QuestObjective(
      id: 'team_coordination',
      description: 'Coordinate with your team to complete the quest',
      target: roles.length,
      progress: 0,
      type: 'team_coordination',
    ));
    
    return objectives;
  }

  QuestRewards _calculateTeamRewards(int teamSize, int playerLevel) {
    final baseReward = 50 + (playerLevel * 10);
    final teamBonus = teamSize * 25;
    
    return QuestRewards(
      xp: baseReward + teamBonus,
      gold: (baseReward + teamBonus) ~/ 2,
      gems: teamSize * 3,
      items: ['team_quest_trophy', 'coordination_badge'],
      skillPoints: 2,
    );
  }

  String _generateRecommendationReason(Quest quest, Character player) {
    final reasons = [
      'Perfect for your current level!',
      'Great rewards for the effort required.',
      'Fun and engaging quest type.',
      'Located near your current area.',
      'Matches your playstyle perfectly.',
    ];
    
    return reasons[_random.nextInt(reasons.length)];
  }
}

class SharedQuest {
  final String id;
  final Quest baseQuest;
  final Character creator;
  final List<Character> participants;
  final int maxParticipants;
  final SharedQuestType type;
  SharedQuestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final QuestRewards rewards;
  final Map<String, int> participantProgress = {};

  SharedQuest({
    required this.id,
    required this.baseQuest,
    required this.creator,
    required this.participants,
    required this.maxParticipants,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.rewards,
  });
}

enum SharedQuestType {
  cooperative, // All participants work together
  competitive, // Participants compete for rewards
  parallel, // Participants complete similar quests independently
}

enum SharedQuestStatus {
  recruiting,
  inProgress,
  paused,
  completed,
  failed,
}

class TeamQuest {
  final String id;
  final String title;
  final String description;
  final List<TeamRole> requiredRoles;
  final List<QuestObjective> objectives;
  final LatLng location;
  TeamQuestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final QuestRewards rewards;
  final List<TeamMember> members = [];

  TeamQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredRoles,
    required this.objectives,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.rewards,
  });
}

enum TeamRole {
  leader,
  scout,
  healer,
  warrior,
  mage,
  support,
}

extension TeamRoleExtension on TeamRole {
  String get displayName {
    switch (this) {
      case TeamRole.leader:
        return 'Leader';
      case TeamRole.scout:
        return 'Scout';
      case TeamRole.healer:
        return 'Healer';
      case TeamRole.warrior:
        return 'Warrior';
      case TeamRole.mage:
        return 'Mage';
      case TeamRole.support:
        return 'Support';
    }
  }
}

enum TeamQuestStatus {
  recruiting,
  inProgress,
  completed,
  failed,
}

class TeamMember {
  final Character character;
  final TeamRole role;

  TeamMember({
    required this.character,
    required this.role,
  });
}

class QuestChallenge {
  final String id;
  final Quest quest;
  final Character challenger;
  final ChallengeType type;
  final int targetValue;
  ChallengeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<Character> participants;
  final List<ChallengeEntry> leaderboard;
  Character? winner;

  QuestChallenge({
    required this.id,
    required this.quest,
    required this.challenger,
    required this.type,
    required this.targetValue,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.participants,
    required this.leaderboard,
  });
}

enum ChallengeType {
  speed, // Complete quest fastest
  efficiency, // Complete with least resources
  score, // Achieve highest score
  creativity, // Most creative completion
}

enum ChallengeStatus {
  active,
  completed,
  expired,
}

class ChallengeEntry {
  final Character challenger;
  int value;

  ChallengeEntry({
    required this.challenger,
    required this.value,
  });
}

class QuestRecommendation {
  final String id;
  final Quest quest;
  final Character recommender;
  final String reason;
  final double rating;
  final DateTime createdAt;
  int likes;
  int dislikes;

  QuestRecommendation({
    required this.id,
    required this.quest,
    required this.recommender,
    required this.reason,
    required this.rating,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
  });

  double get score => likes - dislikes;
}
