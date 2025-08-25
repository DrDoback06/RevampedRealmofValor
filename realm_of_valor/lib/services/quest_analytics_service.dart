import 'dart:math';
import '../../../data/models/quest_model.dart';
import '../../../data/models/character_model.dart';

class QuestAnalyticsService {
  static final QuestAnalyticsService _instance = QuestAnalyticsService._internal();
  factory QuestAnalyticsService() => _instance;
  QuestAnalyticsService._internal();

  final Map<String, QuestAnalytics> _questAnalytics = {};
  final Map<String, PlayerAnalytics> _playerAnalytics = {};
  final List<QuestEvent> _questEvents = [];

  /// Track a quest event
  void trackQuestEvent(QuestEvent event) {
    _questEvents.add(event);
    
    // Update quest analytics
    _updateQuestAnalytics(event);
    
    // Update player analytics
    _updatePlayerAnalytics(event);
  }

  /// Get analytics for a specific quest
  QuestAnalytics getQuestAnalytics(String questId) {
    return _questAnalytics[questId] ?? QuestAnalytics(questId: questId);
  }

  /// Get analytics for a specific player
  PlayerAnalytics getPlayerAnalytics(String playerId) {
    return _playerAnalytics[playerId] ?? PlayerAnalytics(playerId: playerId);
  }

  /// Get overall game analytics
  GameAnalytics getGameAnalytics() {
    return GameAnalytics(
      totalQuests: _questAnalytics.length,
      totalPlayers: _playerAnalytics.length,
      totalEvents: _questEvents.length,
      averageCompletionRate: _calculateAverageCompletionRate(),
      popularQuestTypes: _getPopularQuestTypes(),
      playerRetentionRate: _calculatePlayerRetentionRate(),
      averageQuestDuration: _calculateAverageQuestDuration(),
      questDifficultyDistribution: _getQuestDifficultyDistribution(),
    );
  }

  /// Get quest recommendations based on analytics
  List<QuestRecommendation> getAnalyticsBasedRecommendations(Character player) {
    final playerAnalytics = getPlayerAnalytics(player.id);
    final recommendations = <QuestRecommendation>[];
    
    // Find quests similar to ones the player has completed successfully
    final successfulQuests = playerAnalytics.completedQuests
        .where((q) => q.completionTime != null && q.completionTime! < const Duration(minutes: 30))
        .toList();
    
    for (final successfulQuest in successfulQuests.take(3)) {
      final similarQuests = _findSimilarQuests(successfulQuest.quest);
      recommendations.addAll(similarQuests);
    }
    
    // Find quests that match player's preferred time patterns
    final timeBasedQuests = _findTimeBasedQuests(playerAnalytics);
    recommendations.addAll(timeBasedQuests);
    
    // Find quests that match player's preferred locations
    final locationBasedQuests = _findLocationBasedQuests(playerAnalytics);
    recommendations.addAll(locationBasedQuests);
    
    return recommendations.take(5).toList();
  }

  /// Get quest difficulty insights
  QuestDifficultyInsights getQuestDifficultyInsights() {
    final insights = <QuestType, DifficultyInsight>{};
    
    for (final questType in QuestType.values) {
      final typeQuests = _questAnalytics.values
          .where((analytics) => analytics.questType == questType)
          .toList();
      
      if (typeQuests.isNotEmpty) {
        insights[questType] = _calculateDifficultyInsight(typeQuests);
      }
    }
    
    return QuestDifficultyInsights(insights: insights);
  }

  /// Get player behavior patterns
  PlayerBehaviorPatterns getPlayerBehaviorPatterns(String playerId) {
    final playerAnalytics = getPlayerAnalytics(playerId);
    final events = _questEvents.where((e) => e.playerId == playerId).toList();
    
    return PlayerBehaviorPatterns(
      playerId: playerId,
      preferredQuestTypes: _getPreferredQuestTypes(events),
      preferredTimeSlots: _getPreferredTimeSlots(events),
      preferredLocations: _getPreferredLocations(events),
      averageSessionDuration: _calculateAverageSessionDuration(events),
      questCompletionRate: _calculatePlayerCompletionRate(playerAnalytics),
      socialInteractionLevel: _calculateSocialInteractionLevel(events),
    );
  }

  void _updateQuestAnalytics(QuestEvent event) {
    final questId = event.questId;
    final analytics = _questAnalytics.putIfAbsent(questId, () => QuestAnalytics(questId: questId));
    
    switch (event.type) {
      case QuestEventType.started:
        analytics.startedCount++;
        analytics.lastStarted = event.timestamp;
        break;
      case QuestEventType.completed:
        analytics.completedCount++;
        analytics.lastCompleted = event.timestamp;
        if (analytics.startedCount > 0) {
          analytics.completionRate = analytics.completedCount / analytics.startedCount;
        }
        break;
      case QuestEventType.failed:
        analytics.failedCount++;
        analytics.lastFailed = event.timestamp;
        break;
      case QuestEventType.abandoned:
        analytics.abandonedCount++;
        analytics.lastAbandoned = event.timestamp;
        break;
    }
    
    // Update average completion time
    if (event.completionTime != null) {
      analytics.completionTimes.add(event.completionTime!);
      analytics.averageCompletionTime = _calculateAverageDuration(analytics.completionTimes);
    }
  }

  void _updatePlayerAnalytics(QuestEvent event) {
    final playerId = event.playerId;
    final analytics = _playerAnalytics.putIfAbsent(playerId, () => PlayerAnalytics(playerId: playerId));
    
    switch (event.type) {
      case QuestEventType.started:
        analytics.startedQuests.add(PlayerQuestRecord(
          quest: event.quest,
          startTime: event.timestamp,
        ));
        break;
      case QuestEventType.completed:
        final startedQuest = analytics.startedQuests
            .firstWhere((q) => q.quest.id == event.questId);
        startedQuest.completionTime = event.completionTime;
        analytics.completedQuests.add(startedQuest);
        analytics.startedQuests.remove(startedQuest);
        break;
      case QuestEventType.failed:
        analytics.failedQuests.add(PlayerQuestRecord(
          quest: event.quest,
          startTime: event.timestamp,
          completionTime: event.completionTime,
        ));
        break;
    }
  }

  double _calculateAverageCompletionRate() {
    if (_questAnalytics.isEmpty) return 0.0;
    
    final totalCompletionRate = _questAnalytics.values
        .map((analytics) => analytics.completionRate)
        .reduce((a, b) => a + b);
    
    return totalCompletionRate / _questAnalytics.length;
  }

  Map<QuestType, int> _getPopularQuestTypes() {
    final popularity = <QuestType, int>{};
    
    for (final analytics in _questAnalytics.values) {
      final count = popularity[analytics.questType] ?? 0;
      popularity[analytics.questType] = count + analytics.startedCount;
    }
    
    return popularity;
  }

  double _calculatePlayerRetentionRate() {
    if (_playerAnalytics.isEmpty) return 0.0;
    
    final returningPlayers = _playerAnalytics.values
        .where((analytics) => analytics.completedQuests.length > 1)
        .length;
    
    return returningPlayers / _playerAnalytics.length;
  }

  Duration _calculateAverageQuestDuration() {
    final allCompletionTimes = <Duration>[];
    
    for (final analytics in _questAnalytics.values) {
      allCompletionTimes.addAll(analytics.completionTimes);
    }
    
    if (allCompletionTimes.isEmpty) return Duration.zero;
    
    return _calculateAverageDuration(allCompletionTimes);
  }

  Map<String, int> _getQuestDifficultyDistribution() {
    final distribution = <String, int>{};
    
    for (final analytics in _questAnalytics.values) {
      final difficulty = analytics.averageDifficulty.toString();
      final count = distribution[difficulty] ?? 0;
      distribution[difficulty] = count + 1;
    }
    
    return distribution;
  }

  List<Quest> _findSimilarQuests(Quest referenceQuest) {
    final similarQuests = <Quest>[];
    
    for (final analytics in _questAnalytics.values) {
      if (analytics.questType == referenceQuest.type &&
          analytics.averageDifficulty >= referenceQuest.level - 2 &&
          analytics.averageDifficulty <= referenceQuest.level + 2) {
        // This is a similar quest
        // In a real implementation, you'd return the actual quest object
        similarQuests.add(referenceQuest); // Placeholder
      }
    }
    
    return similarQuests;
  }

  List<Quest> _findTimeBasedQuests(PlayerAnalytics playerAnalytics) {
    // Find quests that are typically completed during player's active hours
    final activeHours = _getPlayerActiveHours(playerAnalytics);
    final timeBasedQuests = <Quest>[];
    
    // In a real implementation, you'd filter quests based on time patterns
    return timeBasedQuests;
  }

  List<Quest> _findLocationBasedQuests(PlayerAnalytics playerAnalytics) {
    // Find quests near locations the player frequently visits
    final preferredLocations = _getPreferredLocations(playerAnalytics);
    final locationBasedQuests = <Quest>[];
    
    // In a real implementation, you'd filter quests based on location patterns
    return locationBasedQuests;
  }

  DifficultyInsight _calculateDifficultyInsight(List<QuestAnalytics> typeQuests) {
    final totalStarted = typeQuests.fold(0, (sum, analytics) => sum + analytics.startedCount);
    final totalCompleted = typeQuests.fold(0, (sum, analytics) => sum + analytics.completedCount);
    
    final completionRate = totalStarted > 0 ? totalCompleted / totalStarted : 0.0;
    
    String difficultyAssessment;
    if (completionRate > 0.8) {
      difficultyAssessment = 'Too Easy';
    } else if (completionRate > 0.6) {
      difficultyAssessment = 'Balanced';
    } else if (completionRate > 0.4) {
      difficultyAssessment = 'Challenging';
    } else {
      difficultyAssessment = 'Too Hard';
    }
    
    return DifficultyInsight(
      completionRate: completionRate,
      difficultyAssessment: difficultyAssessment,
      recommendedAdjustment: _getRecommendedAdjustment(completionRate),
    );
  }

  String _getRecommendedAdjustment(double completionRate) {
    if (completionRate > 0.8) {
      return 'Consider increasing difficulty or reducing rewards';
    } else if (completionRate < 0.4) {
      return 'Consider decreasing difficulty or increasing rewards';
    } else {
      return 'Difficulty appears well-balanced';
    }
  }

  List<QuestType> _getPreferredQuestTypes(List<QuestEvent> events) {
    final typeCounts = <QuestType, int>{};
    
    for (final event in events) {
      final count = typeCounts[event.quest.type] ?? 0;
      typeCounts[event.quest.type] = count + 1;
    }
    
    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTypes.map((e) => e.key).toList();
  }

  List<int> _getPreferredTimeSlots(List<QuestEvent> events) {
    final hourCounts = <int, int>{};
    
    for (final event in events) {
      final hour = event.timestamp.hour;
      final count = hourCounts[hour] ?? 0;
      hourCounts[hour] = count + 1;
    }
    
    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedHours.map((e) => e.key).toList();
  }

  List<LatLng> _getPreferredLocations(List<QuestEvent> events) {
    // In a real implementation, you'd cluster locations and find preferred areas
    return [];
  }

  Duration _calculateAverageSessionDuration(List<QuestEvent> events) {
    // In a real implementation, you'd calculate actual session durations
    return const Duration(minutes: 30);
  }

  double _calculatePlayerCompletionRate(PlayerAnalytics analytics) {
    final totalStarted = analytics.completedQuests.length + analytics.failedQuests.length;
    if (totalStarted == 0) return 0.0;
    
    return analytics.completedQuests.length / totalStarted;
  }

  double _calculateSocialInteractionLevel(List<QuestEvent> events) {
    // In a real implementation, you'd analyze social events
    return 0.5;
  }

  List<int> _getPlayerActiveHours(PlayerAnalytics analytics) {
    // In a real implementation, you'd analyze player activity patterns
    return [9, 10, 11, 12, 13, 14, 15, 16, 17, 18];
  }

  List<LatLng> _getPreferredLocations(PlayerAnalytics analytics) {
    // In a real implementation, you'd analyze location patterns
    return [];
  }

  Duration _calculateAverageDuration(List<Duration> durations) {
    if (durations.isEmpty) return Duration.zero;
    
    final totalMicroseconds = durations.fold<int>(
      0, (sum, duration) => sum + duration.inMicroseconds);
    
    return Duration(microseconds: totalMicroseconds ~/ durations.length);
  }
}

class QuestAnalytics {
  final String questId;
  QuestType questType = QuestType.location;
  int startedCount = 0;
  int completedCount = 0;
  int failedCount = 0;
  int abandonedCount = 0;
  double completionRate = 0.0;
  DateTime? lastStarted;
  DateTime? lastCompleted;
  DateTime? lastFailed;
  DateTime? lastAbandoned;
  final List<Duration> completionTimes = [];
  Duration averageCompletionTime = Duration.zero;
  double averageDifficulty = 1.0;

  QuestAnalytics({required this.questId});
}

class PlayerAnalytics {
  final String playerId;
  final List<PlayerQuestRecord> startedQuests = [];
  final List<PlayerQuestRecord> completedQuests = [];
  final List<PlayerQuestRecord> failedQuests = [];

  PlayerAnalytics({required this.playerId});
}

class PlayerQuestRecord {
  final Quest quest;
  final DateTime startTime;
  Duration? completionTime;

  PlayerQuestRecord({
    required this.quest,
    required this.startTime,
    this.completionTime,
  });
}

class QuestEvent {
  final String questId;
  final String playerId;
  final Quest quest;
  final QuestEventType type;
  final DateTime timestamp;
  final Duration? completionTime;

  QuestEvent({
    required this.questId,
    required this.playerId,
    required this.quest,
    required this.type,
    required this.timestamp,
    this.completionTime,
  });
}

enum QuestEventType {
  started,
  completed,
  failed,
  abandoned,
}

class GameAnalytics {
  final int totalQuests;
  final int totalPlayers;
  final int totalEvents;
  final double averageCompletionRate;
  final Map<QuestType, int> popularQuestTypes;
  final double playerRetentionRate;
  final Duration averageQuestDuration;
  final Map<String, int> questDifficultyDistribution;

  GameAnalytics({
    required this.totalQuests,
    required this.totalPlayers,
    required this.totalEvents,
    required this.averageCompletionRate,
    required this.popularQuestTypes,
    required this.playerRetentionRate,
    required this.averageQuestDuration,
    required this.questDifficultyDistribution,
  });
}

class QuestRecommendation {
  final Quest quest;
  final String reason;
  final double confidence;

  QuestRecommendation({
    required this.quest,
    required this.reason,
    required this.confidence,
  });
}

class QuestDifficultyInsights {
  final Map<QuestType, DifficultyInsight> insights;

  QuestDifficultyInsights({required this.insights});
}

class DifficultyInsight {
  final double completionRate;
  final String difficultyAssessment;
  final String recommendedAdjustment;

  DifficultyInsight({
    required this.completionRate,
    required this.difficultyAssessment,
    required this.recommendedAdjustment,
  });
}

class PlayerBehaviorPatterns {
  final String playerId;
  final List<QuestType> preferredQuestTypes;
  final List<int> preferredTimeSlots;
  final List<LatLng> preferredLocations;
  final Duration averageSessionDuration;
  final double questCompletionRate;
  final double socialInteractionLevel;

  PlayerBehaviorPatterns({
    required this.playerId,
    required this.preferredQuestTypes,
    required this.preferredTimeSlots,
    required this.preferredLocations,
    required this.averageSessionDuration,
    required this.questCompletionRate,
    required this.socialInteractionLevel,
  });
}