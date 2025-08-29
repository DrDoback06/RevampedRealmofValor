import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/battle_models.dart';

class BattleReplay {
  final String id;
  final String battleId;
  final DateTime timestamp;
  final String playerName;
  final String enemyName;
  final List<BattleAction> actions;
  final BattleStatistics statistics;
  final BattleRewards rewards;
  final Map<String, dynamic> metadata;
  final int duration;
  final String winner;
  final List<ReplayEvent> events;

  BattleReplay({
    required this.id,
    required this.battleId,
    required this.timestamp,
    required this.playerName,
    required this.enemyName,
    required this.actions,
    required this.statistics,
    required this.rewards,
    required this.metadata,
    required this.duration,
    required this.winner,
    required this.events,
  });

  factory BattleReplay.fromJson(Map<String, dynamic> json) {
    return BattleReplay(
      id: json['id'],
      battleId: json['battleId'],
      timestamp: DateTime.parse(json['timestamp']),
      playerName: json['playerName'],
      enemyName: json['enemyName'],
      actions: (json['actions'] as List)
          .map((a) => BattleAction.fromJson(a))
          .toList(),
      statistics: BattleStatistics.fromJson(json['statistics']),
      rewards: BattleRewards.fromJson(json['rewards']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      duration: json['duration'],
      winner: json['winner'],
      events: (json['events'] as List)
          .map((e) => ReplayEvent.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'battleId': battleId,
      'timestamp': timestamp.toIso8601String(),
      'playerName': playerName,
      'enemyName': enemyName,
      'actions': actions.map((a) => a.toJson()).toList(),
      'statistics': statistics.toJson(),
      'rewards': rewards.toJson(),
      'metadata': metadata,
      'duration': duration,
      'winner': winner,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  String toReplayString() {
    return jsonEncode(toJson());
  }

  static BattleReplay fromReplayString(String replayString) {
    return BattleReplay.fromJson(jsonDecode(replayString));
  }
}

class ReplayEvent {
  final String id;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String description;

  ReplayEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
    required this.description,
  });

  factory ReplayEvent.fromJson(Map<String, dynamic> json) {
    return ReplayEvent(
      id: json['id'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'description': description,
    };
  }
}

class BattleAnalysis {
  final String replayId;
  final List<AnalysisMetric> metrics;
  final List<AnalysisInsight> insights;
  final Map<String, dynamic> recommendations;
  final double performanceScore;
  final String grade;

  BattleAnalysis({
    required this.replayId,
    required this.metrics,
    required this.insights,
    required this.recommendations,
    required this.performanceScore,
    required this.grade,
  });

  factory BattleAnalysis.fromJson(Map<String, dynamic> json) {
    return BattleAnalysis(
      replayId: json['replayId'],
      metrics: (json['metrics'] as List)
          .map((m) => AnalysisMetric.fromJson(m))
          .toList(),
      insights: (json['insights'] as List)
          .map((i) => AnalysisInsight.fromJson(i))
          .toList(),
      recommendations: Map<String, dynamic>.from(json['recommendations'] ?? {}),
      performanceScore: json['performanceScore']?.toDouble() ?? 0.0,
      grade: json['grade'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'replayId': replayId,
      'metrics': metrics.map((m) => m.toJson()).toList(),
      'insights': insights.map((i) => i.toJson()).toList(),
      'recommendations': recommendations,
      'performanceScore': performanceScore,
      'grade': grade,
    };
  }
}

class AnalysisMetric {
  final String name;
  final String category;
  final double value;
  final double benchmark;
  final String unit;
  final bool isPositive;

  AnalysisMetric({
    required this.name,
    required this.category,
    required this.value,
    required this.benchmark,
    required this.unit,
    required this.isPositive,
  });

  factory AnalysisMetric.fromJson(Map<String, dynamic> json) {
    return AnalysisMetric(
      name: json['name'],
      category: json['category'],
      value: json['value']?.toDouble() ?? 0.0,
      benchmark: json['benchmark']?.toDouble() ?? 0.0,
      unit: json['unit'],
      isPositive: json['isPositive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'value': value,
      'benchmark': benchmark,
      'unit': unit,
      'isPositive': isPositive,
    };
  }

  double get efficiency => benchmark > 0 ? value / benchmark : 0.0;
}

class AnalysisInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final double confidence;
  final List<String> tags;
  final Map<String, dynamic> data;

  AnalysisInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.confidence,
    required this.tags,
    required this.data,
  });

  factory AnalysisInsight.fromJson(Map<String, dynamic> json) {
    return AnalysisInsight(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: InsightType.values.firstWhere((e) => e.name == json['type']),
      confidence: json['confidence']?.toDouble() ?? 0.0,
      tags: List<String>.from(json['tags'] ?? []),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'confidence': confidence,
      'tags': tags,
      'data': data,
    };
  }
}

enum InsightType {
  performance,
  strategy,
  efficiency,
  mistake,
  opportunity,
  pattern,
}

class BattleReplayService {
  static final Map<String, BattleReplay> _replays = {};
  static final Map<String, BattleAnalysis> _analyses = {};

  static void recordBattleAction(String battleId, BattleAction action) {
    // This would typically be called during battle to record actions
    // For now, we'll store them in memory
  }

  static void saveReplay(BattleReplay replay) {
    _replays[replay.id] = replay;
  }

  static BattleReplay? getReplay(String replayId) {
    return _replays[replayId];
  }

  static List<BattleReplay> getAllReplays() {
    return _replays.values.toList();
  }

  static List<BattleReplay> getReplaysByPlayer(String playerName) {
    return _replays.values
        .where((replay) => replay.playerName == playerName)
        .toList();
  }

  static List<BattleReplay> getReplaysByEnemy(String enemyName) {
    return _replays.values
        .where((replay) => replay.enemyName == enemyName)
        .toList();
  }

  static BattleAnalysis analyzeReplay(String replayId) {
    BattleReplay? replay = getReplay(replayId);
    if (replay == null) {
      throw Exception('Replay not found: $replayId');
    }

    // Calculate metrics
    List<AnalysisMetric> metrics = _calculateMetrics(replay);
    
    // Generate insights
    List<AnalysisInsight> insights = _generateInsights(replay, metrics);
    
    // Generate recommendations
    Map<String, dynamic> recommendations = _generateRecommendations(replay, insights);
    
    // Calculate performance score
    double performanceScore = _calculatePerformanceScore(metrics);
    
    // Determine grade
    String grade = _determineGrade(performanceScore);

    BattleAnalysis analysis = BattleAnalysis(
      replayId: replayId,
      metrics: metrics,
      insights: insights,
      recommendations: recommendations,
      performanceScore: performanceScore,
      grade: grade,
    );

    _analyses[replayId] = analysis;
    return analysis;
  }

  static List<AnalysisMetric> _calculateMetrics(BattleReplay replay) {
    List<AnalysisMetric> metrics = [];

    // Turn efficiency
    double turnEfficiency = replay.statistics.totalTurns > 0 
        ? replay.statistics.damageDealt / replay.statistics.totalTurns 
        : 0.0;
    metrics.add(AnalysisMetric(
      name: 'Damage per Turn',
      category: 'Efficiency',
      value: turnEfficiency,
      benchmark: 25.0, // Average damage per turn
      unit: 'damage/turn',
      isPositive: true,
    ));

    // Card efficiency
    double cardEfficiency = replay.statistics.cardsPlayed > 0 
        ? replay.statistics.damageDealt / replay.statistics.cardsPlayed 
        : 0.0;
    metrics.add(AnalysisMetric(
      name: 'Damage per Card',
      category: 'Efficiency',
      value: cardEfficiency,
      benchmark: 15.0, // Average damage per card
      unit: 'damage/card',
      isPositive: true,
    ));

    // Damage taken efficiency
    double damageTakenEfficiency = replay.statistics.damageReceived > 0 
        ? replay.statistics.damageDealt / replay.statistics.damageReceived 
        : 0.0;
    metrics.add(AnalysisMetric(
      name: 'Damage Ratio',
      category: 'Efficiency',
      value: damageTakenEfficiency,
      benchmark: 2.0, // 2:1 damage ratio
      unit: 'ratio',
      isPositive: true,
    ));

    // Battle duration
    metrics.add(AnalysisMetric(
      name: 'Battle Duration',
      category: 'Performance',
      value: replay.duration.toDouble(),
      benchmark: 180.0, // 3 minutes average
      unit: 'seconds',
      isPositive: false, // Shorter is better
    ));

    // Healing efficiency
    if (replay.statistics.healingDone > 0) {
      double healingEfficiency = replay.statistics.healingDone / replay.statistics.damageReceived;
      metrics.add(AnalysisMetric(
        name: 'Healing Efficiency',
        category: 'Support',
        value: healingEfficiency,
        benchmark: 0.8, // 80% healing efficiency
        unit: 'ratio',
        isPositive: true,
      ));
    }

    return metrics;
  }

  static List<AnalysisInsight> _generateInsights(
    BattleReplay replay, 
    List<AnalysisMetric> metrics
  ) {
    List<AnalysisInsight> insights = [];

    // Quick victory insight
    if (replay.statistics.totalTurns < 8) {
      insights.add(AnalysisInsight(
        id: 'quick_victory',
        title: 'Quick Victory',
        description: 'You achieved victory in ${replay.statistics.totalTurns} turns, showing excellent efficiency.',
        type: InsightType.performance,
        confidence: 0.9,
        tags: ['efficiency', 'speed'],
        data: {'turns': replay.statistics.totalTurns},
      ));
    }

    // High damage insight
    if (replay.statistics.damageDealt > 200) {
      insights.add(AnalysisInsight(
        id: 'high_damage',
        title: 'High Damage Output',
        description: 'You dealt ${replay.statistics.damageDealt} damage, demonstrating strong offensive capabilities.',
        type: InsightType.performance,
        confidence: 0.8,
        tags: ['damage', 'offense'],
        data: {'damage': replay.statistics.damageDealt},
      ));
    }

    // Low damage taken insight
    if (replay.statistics.damageReceived < 30) {
      insights.add(AnalysisInsight(
        id: 'low_damage_taken',
        title: 'Excellent Defense',
        description: 'You only took ${replay.statistics.damageReceived} damage, showing great defensive play.',
        type: InsightType.performance,
        confidence: 0.85,
        tags: ['defense', 'efficiency'],
        data: {'damage_taken': replay.statistics.damageReceived},
      ));
    }

    // Card usage pattern
    if (replay.statistics.cardsPlayed > 12) {
      insights.add(AnalysisInsight(
        id: 'high_card_usage',
        title: 'High Card Usage',
        description: 'You played ${replay.statistics.cardsPlayed} cards. Consider being more selective with card usage.',
        type: InsightType.efficiency,
        confidence: 0.7,
        tags: ['cards', 'efficiency'],
        data: {'cards_played': replay.statistics.cardsPlayed},
      ));
    }

    // Special ability usage
    if (replay.statistics.specialAbilitiesUsed > 0) {
      insights.add(AnalysisInsight(
        id: 'special_abilities',
        title: 'Special Abilities Used',
        description: 'You used ${replay.statistics.specialAbilitiesUsed} special abilities effectively.',
        type: InsightType.strategy,
        confidence: 0.75,
        tags: ['special', 'strategy'],
        data: {'special_abilities': replay.statistics.specialAbilitiesUsed},
      ));
    }

    // Find best performing metric
    AnalysisMetric? bestMetric = metrics
        .where((m) => m.isPositive)
        .reduce((a, b) => a.efficiency > b.efficiency ? a : b);
    
    if (bestMetric != null && bestMetric.efficiency > 1.2) {
      insights.add(AnalysisInsight(
        id: 'excellent_${bestMetric.name.toLowerCase().replaceAll(' ', '_')}',
        title: 'Excellent ${bestMetric.name}',
        description: 'Your ${bestMetric.name.toLowerCase()} was ${(bestMetric.efficiency * 100).round()}% of the benchmark.',
        type: InsightType.performance,
        confidence: 0.9,
        tags: ['excellence', bestMetric.category.toLowerCase()],
        data: {'metric': bestMetric.name, 'efficiency': bestMetric.efficiency},
      ));
    }

    return insights;
  }

  static Map<String, dynamic> _generateRecommendations(
    BattleReplay replay, 
    List<AnalysisInsight> insights
  ) {
    Map<String, dynamic> recommendations = {};

    // Check for areas of improvement
    if (replay.statistics.damageReceived > 100) {
      recommendations['defense'] = {
        'priority': 'high',
        'title': 'Improve Defense',
        'description': 'Focus on defensive cards and positioning to reduce damage taken.',
        'suggestions': [
          'Use more defensive cards',
          'Position strategically',
          'Consider healing cards',
        ],
      };
    }

    if (replay.statistics.cardsPlayed > 15) {
      recommendations['efficiency'] = {
        'priority': 'medium',
        'title': 'Improve Card Efficiency',
        'description': 'Be more selective with card usage to improve efficiency.',
        'suggestions': [
          'Plan your turns better',
          'Save powerful cards for key moments',
          'Avoid unnecessary card plays',
        ],
      };
    }

    if (replay.duration > 300) { // 5 minutes
      recommendations['speed'] = {
        'priority': 'medium',
        'title': 'Improve Battle Speed',
        'description': 'Try to complete battles faster for better rewards.',
        'suggestions': [
          'Make decisions faster',
          'Use more aggressive strategies',
          'Focus on high-damage cards',
        ],
      };
    }

    // Positive reinforcement
    if (replay.statistics.damageDealt > 150 && replay.statistics.damageReceived < 50) {
      recommendations['strength'] = {
        'priority': 'low',
        'title': 'Maintain Strong Performance',
        'description': 'Your offensive and defensive play was excellent. Keep it up!',
        'suggestions': [
          'Continue using effective strategies',
          'Share your tactics with others',
          'Try more challenging battles',
        ],
      };
    }

    return recommendations;
  }

  static double _calculatePerformanceScore(List<AnalysisMetric> metrics) {
    double totalScore = 0.0;
    int metricCount = 0;

    for (var metric in metrics) {
      double score = 0.0;
      
      if (metric.isPositive) {
        score = metric.efficiency.clamp(0.0, 2.0) / 2.0; // Cap at 200% efficiency
      } else {
        score = (2.0 - metric.efficiency.clamp(0.0, 2.0)) / 2.0; // Inverse for negative metrics
      }
      
      totalScore += score;
      metricCount++;
    }

    return metricCount > 0 ? totalScore / metricCount : 0.0;
  }

  static String _determineGrade(double performanceScore) {
    if (performanceScore >= 0.9) return 'S';
    if (performanceScore >= 0.8) return 'A';
    if (performanceScore >= 0.7) return 'B';
    if (performanceScore >= 0.6) return 'C';
    if (performanceScore >= 0.5) return 'D';
    return 'F';
  }

  static BattleAnalysis? getAnalysis(String replayId) {
    return _analyses[replayId];
  }

  static List<BattleAnalysis> getAllAnalyses() {
    return _analyses.values.toList();
  }

  static void deleteReplay(String replayId) {
    _replays.remove(replayId);
    _analyses.remove(replayId);
  }

  static String exportReplay(String replayId) {
    BattleReplay? replay = getReplay(replayId);
    if (replay == null) {
      throw Exception('Replay not found: $replayId');
    }
    return replay.toReplayString();
  }

  static BattleReplay importReplay(String replayString) {
    BattleReplay replay = BattleReplay.fromReplayString(replayString);
    saveReplay(replay);
    return replay;
  }
}

// Riverpod providers
final battleReplayServiceProvider = Provider<BattleReplayService>((ref) {
  return BattleReplayService();
});

final savedReplaysProvider = StateProvider<List<BattleReplay>>((ref) {
  return BattleReplayService.getAllReplays();
});

final battleAnalysisProvider = StateProvider<Map<String, BattleAnalysis>>((ref) {
  return {};
});
