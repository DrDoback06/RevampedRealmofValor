import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'character_classes.dart';
import 'skill_synergy.dart';

enum AnalyticsPeriod {
  daily,
  weekly,
  monthly,
  yearly,
  allTime,
}

enum SkillUsageType {
  battle,
  quest,
  exploration,
  training,
  social,
  other,
}

enum InsightType {
  performance,
  efficiency,
  optimization,
  recommendation,
  warning,
  achievement,
}

class SkillUsageEvent extends Equatable {
  final String id;
  final String skillId;
  final String skillName;
  final SkillUsageType usageType;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final bool wasSuccessful;
  final double effectiveness;
  final int damageDealt;
  final int damageTaken;
  final int healingDone;
  final int manaUsed;
  final Duration castTime;
  final Duration cooldown;

  const SkillUsageEvent({
    required this.id,
    required this.skillId,
    required this.skillName,
    required this.usageType,
    required this.timestamp,
    required this.context,
    required this.wasSuccessful,
    required this.effectiveness,
    required this.damageDealt,
    required this.damageTaken,
    required this.healingDone,
    required this.manaUsed,
    required this.castTime,
    required this.cooldown,
  });

  @override
  List<Object?> get props => [
    id,
    skillId,
    skillName,
    usageType,
    timestamp,
    context,
    wasSuccessful,
    effectiveness,
    damageDealt,
    damageTaken,
    healingDone,
    manaUsed,
    castTime,
    cooldown,
  ];
}

class SkillAnalytics extends Equatable {
  final String skillId;
  final String skillName;
  final int totalUses;
  final int successfulUses;
  final int failedUses;
  final double successRate;
  final double averageEffectiveness;
  final int totalDamageDealt;
  final int totalDamageTaken;
  final int totalHealingDone;
  final int totalManaUsed;
  final Duration totalCastTime;
  final Duration totalCooldown;
  final DateTime firstUse;
  final DateTime lastUse;
  final Map<SkillUsageType, int> usageByType;
  final Map<String, int> usageByContext;
  final List<SkillUsageEvent> recentEvents;

  const SkillAnalytics({
    required this.skillId,
    required this.skillName,
    required this.totalUses,
    required this.successfulUses,
    required this.failedUses,
    required this.successRate,
    required this.averageEffectiveness,
    required this.totalDamageDealt,
    required this.totalDamageTaken,
    required this.totalHealingDone,
    required this.totalManaUsed,
    required this.totalCastTime,
    required this.totalCooldown,
    required this.firstUse,
    required this.lastUse,
    required this.usageByType,
    required this.usageByContext,
    required this.recentEvents,
  });

  double get averageDamageDealt => totalUses > 0 ? totalDamageDealt / totalUses : 0;
  double get averageDamageTaken => totalUses > 0 ? totalDamageTaken / totalUses : 0;
  double get averageHealingDone => totalUses > 0 ? totalHealingDone / totalUses : 0;
  double get averageManaUsed => totalUses > 0 ? totalManaUsed / totalUses : 0;
  Duration get averageCastTime => totalUses > 0 ? Duration(milliseconds: totalCastTime.inMilliseconds ~/ totalUses) : Duration.zero;
  Duration get averageCooldown => totalUses > 0 ? Duration(milliseconds: totalCooldown.inMilliseconds ~/ totalUses) : Duration.zero;

  @override
  List<Object?> get props => [
    skillId,
    skillName,
    totalUses,
    successfulUses,
    failedUses,
    successRate,
    averageEffectiveness,
    totalDamageDealt,
    totalDamageTaken,
    totalHealingDone,
    totalManaUsed,
    totalCastTime,
    totalCooldown,
    firstUse,
    lastUse,
    usageByType,
    usageByContext,
    recentEvents,
  ];
}

class SkillInsight extends Equatable {
  final String id;
  final String skillId;
  final String title;
  final String description;
  final InsightType type;
  final double confidence;
  final Map<String, dynamic> data;
  final DateTime generatedAt;
  final bool isActionable;
  final String? actionDescription;
  final String? actionUrl;

  const SkillInsight({
    required this.id,
    required this.skillId,
    required this.title,
    required this.description,
    required this.type,
    required this.confidence,
    required this.data,
    required this.generatedAt,
    required this.isActionable,
    this.actionDescription,
    this.actionUrl,
  });

  @override
  List<Object?> get props => [
    id,
    skillId,
    title,
    description,
    type,
    confidence,
    data,
    generatedAt,
    isActionable,
    actionDescription,
    actionUrl,
  ];
}

class SkillPerformanceReport extends Equatable {
  final String characterId;
  final DateTime reportDate;
  final AnalyticsPeriod period;
  final Map<String, SkillAnalytics> skillAnalytics;
  final List<SkillInsight> insights;
  final Map<String, dynamic> summary;
  final Map<String, double> recommendations;

  const SkillPerformanceReport({
    required this.characterId,
    required this.reportDate,
    required this.period,
    required this.skillAnalytics,
    required this.insights,
    required this.summary,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [
    characterId,
    reportDate,
    period,
    skillAnalytics,
    insights,
    summary,
    recommendations,
  ];
}

class SkillAnalyticsService {
  static SkillAnalytics calculateAnalytics(String skillId, String skillName, List<SkillUsageEvent> events) {
    if (events.isEmpty) {
      return SkillAnalytics(
        skillId: skillId,
        skillName: skillName,
        totalUses: 0,
        successfulUses: 0,
        failedUses: 0,
        successRate: 0.0,
        averageEffectiveness: 0.0,
        totalDamageDealt: 0,
        totalDamageTaken: 0,
        totalHealingDone: 0,
        totalManaUsed: 0,
        totalCastTime: Duration.zero,
        totalCooldown: Duration.zero,
        firstUse: DateTime.now(),
        lastUse: DateTime.now(),
        usageByType: {},
        usageByContext: {},
        recentEvents: [],
      );
    }

    final successfulUses = events.where((e) => e.wasSuccessful).length;
    final failedUses = events.where((e) => !e.wasSuccessful).length;
    final successRate = events.length > 0 ? successfulUses / events.length : 0.0;
    
    final totalDamageDealt = events.fold(0, (sum, e) => sum + e.damageDealt);
    final totalDamageTaken = events.fold(0, (sum, e) => sum + e.damageTaken);
    final totalHealingDone = events.fold(0, (sum, e) => sum + e.healingDone);
    final totalManaUsed = events.fold(0, (sum, e) => sum + e.manaUsed);
    
    final totalCastTime = Duration(milliseconds: events.fold(0, (sum, e) => sum + e.castTime.inMilliseconds));
    final totalCooldown = Duration(milliseconds: events.fold(0, (sum, e) => sum + e.cooldown.inMilliseconds));
    
    final averageEffectiveness = events.fold(0.0, (sum, e) => sum + e.effectiveness) / events.length;
    
    final usageByType = <SkillUsageType, int>{};
    for (final event in events) {
      usageByType[event.usageType] = (usageByType[event.usageType] ?? 0) + 1;
    }
    
    final usageByContext = <String, int>{};
    for (final event in events) {
      for (final entry in event.context.entries) {
        final key = '${entry.key}:${entry.value}';
        usageByContext[key] = (usageByContext[key] ?? 0) + 1;
      }
    }
    
    final sortedEvents = List<SkillUsageEvent>.from(events)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentEvents = sortedEvents.take(10).toList();
    
    return SkillAnalytics(
      skillId: skillId,
      skillName: skillName,
      totalUses: events.length,
      successfulUses: successfulUses,
      failedUses: failedUses,
      successRate: successRate,
      averageEffectiveness: averageEffectiveness,
      totalDamageDealt: totalDamageDealt,
      totalDamageTaken: totalDamageTaken,
      totalHealingDone: totalHealingDone,
      totalManaUsed: totalManaUsed,
      totalCastTime: totalCastTime,
      totalCooldown: totalCooldown,
      firstUse: events.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
      lastUse: events.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
      usageByType: usageByType,
      usageByContext: usageByContext,
      recentEvents: recentEvents,
    );
  }

  static List<SkillInsight> generateInsights(Map<String, SkillAnalytics> skillAnalytics, CharacterClass characterClass) {
    final insights = <SkillInsight>[];
    
    for (final analytics in skillAnalytics.values) {
      // Performance insights
      if (analytics.successRate < 0.5) {
        insights.add(SkillInsight(
          id: 'insight_${analytics.skillId}_low_success',
          skillId: analytics.skillId,
          title: 'Low Success Rate',
          description: '${analytics.skillName} has a low success rate of ${(analytics.successRate * 100).toStringAsFixed(1)}%. Consider improving your timing or positioning.',
          type: InsightType.warning,
          confidence: 0.8,
          data: {'success_rate': analytics.successRate},
          generatedAt: DateTime.now(),
          isActionable: true,
          actionDescription: 'Practice using ${analytics.skillName} in training mode',
        ));
      }
      
      if (analytics.averageEffectiveness < 0.3) {
        insights.add(SkillInsight(
          id: 'insight_${analytics.skillId}_low_effectiveness',
          skillId: analytics.skillId,
          title: 'Low Effectiveness',
          description: '${analytics.skillName} is not being used effectively. Consider upgrading the skill or improving your strategy.',
          type: InsightType.optimization,
          confidence: 0.7,
          data: {'effectiveness': analytics.averageEffectiveness},
          generatedAt: DateTime.now(),
          isActionable: true,
          actionDescription: 'Upgrade ${analytics.skillName} or review your strategy',
        ));
      }
      
      // Usage insights
      if (analytics.totalUses < 10) {
        insights.add(SkillInsight(
          id: 'insight_${analytics.skillId}_underused',
          skillId: analytics.skillId,
          title: 'Underutilized Skill',
          description: '${analytics.skillName} is rarely used. Consider incorporating it into your rotation for better performance.',
          type: InsightType.recommendation,
          confidence: 0.6,
          data: {'total_uses': analytics.totalUses},
          generatedAt: DateTime.now(),
          isActionable: true,
          actionDescription: 'Practice using ${analytics.skillName} more frequently',
        ));
      }
      
      // Efficiency insights
      if (analytics.averageManaUsed > 100 && analytics.averageDamageDealt < 50) {
        insights.add(SkillInsight(
          id: 'insight_${analytics.skillId}_inefficient',
          skillId: analytics.skillId,
          title: 'Mana Inefficient',
          description: '${analytics.skillName} uses a lot of mana for little damage. Consider using it more strategically.',
          type: InsightType.efficiency,
          confidence: 0.75,
          data: {
            'mana_used': analytics.averageManaUsed,
            'damage_dealt': analytics.averageDamageDealt,
          },
          generatedAt: DateTime.now(),
          isActionable: true,
          actionDescription: 'Use ${analytics.skillName} only when it will be most effective',
        ));
      }
      
      // Achievement insights
      if (analytics.totalUses >= 100 && analytics.successRate >= 0.8) {
        insights.add(SkillInsight(
          id: 'insight_${analytics.skillId}_mastery',
          skillId: analytics.skillId,
          title: 'Skill Mastery',
          description: 'You have mastered ${analytics.skillName} with ${analytics.totalUses} uses and ${(analytics.successRate * 100).toStringAsFixed(1)}% success rate!',
          type: InsightType.achievement,
          confidence: 0.9,
          data: {
            'total_uses': analytics.totalUses,
            'success_rate': analytics.successRate,
          },
          generatedAt: DateTime.now(),
          isActionable: false,
        ));
      }
    }
    
    // Class-specific insights
    final classInsights = _generateClassSpecificInsights(skillAnalytics, characterClass);
    insights.addAll(classInsights);
    
    // Synergy insights
    final synergyInsights = _generateSynergyInsights(skillAnalytics);
    insights.addAll(synergyInsights);
    
    return insights;
  }

  static List<SkillInsight> _generateClassSpecificInsights(Map<String, SkillAnalytics> skillAnalytics, CharacterClass characterClass) {
    final insights = <SkillInsight>[];
    
    switch (characterClass) {
      case CharacterClass.warrior:
        final meleeSkills = skillAnalytics.values.where((a) => 
          a.skillName.toLowerCase().contains('attack') || 
          a.skillName.toLowerCase().contains('strike') ||
          a.skillName.toLowerCase().contains('slash')
        ).toList();
        
        if (meleeSkills.isNotEmpty) {
          final totalDamage = meleeSkills.fold(0, (sum, a) => sum + a.totalDamageDealt);
          if (totalDamage < 1000) {
            insights.add(SkillInsight(
              id: 'insight_warrior_low_damage',
              skillId: 'warrior_melee',
              title: 'Low Melee Damage',
              description: 'Your melee skills are dealing low damage. Consider upgrading your weapon or improving your combat skills.',
              type: InsightType.performance,
              confidence: 0.7,
              data: {'total_damage': totalDamage},
              generatedAt: DateTime.now(),
              isActionable: true,
              actionDescription: 'Upgrade your weapon or practice combat skills',
            ));
          }
        }
        break;
        
      case CharacterClass.mage:
        final spellSkills = skillAnalytics.values.where((a) => 
          a.skillName.toLowerCase().contains('spell') || 
          a.skillName.toLowerCase().contains('magic') ||
          a.skillName.toLowerCase().contains('fire') ||
          a.skillName.toLowerCase().contains('ice')
        ).toList();
        
        if (spellSkills.isNotEmpty) {
          final totalManaUsed = spellSkills.fold(0, (sum, a) => sum + a.totalManaUsed);
          final totalDamage = spellSkills.fold(0, (sum, a) => sum + a.totalDamageDealt);
          
          if (totalManaUsed > 0 && totalDamage / totalManaUsed < 2.0) {
            insights.add(SkillInsight(
              id: 'insight_mage_mana_efficiency',
              skillId: 'mage_spells',
              title: 'Mana Efficiency',
              description: 'Your spells are not mana efficient. Consider using lower cost spells or improving your mana management.',
              type: InsightType.efficiency,
              confidence: 0.8,
              data: {
                'total_mana': totalManaUsed,
                'total_damage': totalDamage,
                'efficiency': totalDamage / totalManaUsed,
              },
              generatedAt: DateTime.now(),
              isActionable: true,
              actionDescription: 'Practice mana management and use more efficient spells',
            ));
          }
        }
        break;
        
      case CharacterClass.rogue:
        final stealthSkills = skillAnalytics.values.where((a) => 
          a.skillName.toLowerCase().contains('stealth') || 
          a.skillName.toLowerCase().contains('shadow') ||
          a.skillName.toLowerCase().contains('backstab')
        ).toList();
        
        if (stealthSkills.isNotEmpty) {
          final successRate = stealthSkills.fold(0.0, (sum, a) => sum + a.successRate) / stealthSkills.length;
          
          if (successRate < 0.6) {
            insights.add(SkillInsight(
              id: 'insight_rogue_stealth',
              skillId: 'rogue_stealth',
              title: 'Stealth Issues',
              description: 'Your stealth skills are not very successful. Practice timing and positioning for better stealth attacks.',
              type: InsightType.performance,
              confidence: 0.75,
              data: {'success_rate': successRate},
              generatedAt: DateTime.now(),
              isActionable: true,
              actionDescription: 'Practice stealth timing and positioning',
            ));
          }
        }
        break;
      case CharacterClass.cleric:
        final healingSkills = skillAnalytics.values.where((a) => 
          a.skillName.toLowerCase().contains('heal') || 
          a.skillName.toLowerCase().contains('bless') ||
          a.skillName.toLowerCase().contains('divine')
        ).toList();
        
        if (healingSkills.isNotEmpty) {
          final totalHealing = healingSkills.fold(0, (sum, a) => sum + a.totalHealingDone);
          if (totalHealing < 500) {
            insights.add(SkillInsight(
              id: 'insight_cleric_low_healing',
              skillId: 'cleric_healing',
              title: 'Low Healing Output',
              description: 'Your healing skills are not very effective. Consider upgrading your healing abilities or improving your timing.',
              type: InsightType.performance,
              confidence: 0.7,
              data: {'total_healing': totalHealing},
              generatedAt: DateTime.now(),
              isActionable: true,
              actionDescription: 'Upgrade healing skills or improve timing',
            ));
          }
        }
        break;
      case CharacterClass.ranger:
      case CharacterClass.paladin:
      case CharacterClass.warlock:
      case CharacterClass.monk:
        // Add specific insights for other classes as needed
        break;
    }
    
    return insights;
  }

  static List<SkillInsight> _generateSynergyInsights(Map<String, SkillAnalytics> skillAnalytics) {
    final insights = <SkillInsight>[];
    
    // Check for potential synergies
    final fireSkills = skillAnalytics.values.where((a) => 
      a.skillName.toLowerCase().contains('fire')
    ).toList();
    
    final iceSkills = skillAnalytics.values.where((a) => 
      a.skillName.toLowerCase().contains('ice')
    ).toList();
    
    final lightningSkills = skillAnalytics.values.where((a) => 
      a.skillName.toLowerCase().contains('lightning') || 
      a.skillName.toLowerCase().contains('thunder')
    ).toList();
    
    // Elemental synergy recommendations
    if (fireSkills.length >= 2 && iceSkills.length >= 2) {
      insights.add(SkillInsight(
        id: 'insight_elemental_synergy',
        skillId: 'elemental_mastery',
        title: 'Elemental Synergy Opportunity',
        description: 'You have multiple fire and ice skills. Consider unlocking elemental synergies for increased damage.',
        type: InsightType.recommendation,
        confidence: 0.8,
        data: {
          'fire_skills': fireSkills.length,
          'ice_skills': iceSkills.length,
        },
        generatedAt: DateTime.now(),
        isActionable: true,
        actionDescription: 'Unlock elemental synergy skills',
      ));
    }
    
    if (fireSkills.length >= 3) {
      insights.add(SkillInsight(
        id: 'insight_fire_mastery',
        skillId: 'fire_mastery',
        title: 'Fire Mastery Potential',
        description: 'You have many fire skills. Consider specializing in fire magic for powerful synergies.',
        type: InsightType.optimization,
        confidence: 0.7,
        data: {'fire_skills': fireSkills.length},
        generatedAt: DateTime.now(),
        isActionable: true,
        actionDescription: 'Focus on fire magic specialization',
      ));
    }
    
    return insights;
  }

  static SkillPerformanceReport generateReport({
    required String characterId,
    required Map<String, SkillAnalytics> skillAnalytics,
    required List<SkillInsight> insights,
    required AnalyticsPeriod period,
    required CharacterClass characterClass,
  }) {
    final summary = <String, dynamic>{};
    final recommendations = <String, double>{};
    
    // Calculate summary statistics
    final totalSkills = skillAnalytics.length;
    final totalUses = skillAnalytics.values.fold(0, (sum, a) => sum + a.totalUses);
    final averageSuccessRate = skillAnalytics.values.fold(0.0, (sum, a) => sum + a.successRate) / totalSkills;
    final totalDamage = skillAnalytics.values.fold(0, (sum, a) => sum + a.totalDamageDealt);
    final totalHealing = skillAnalytics.values.fold(0, (sum, a) => sum + a.totalHealingDone);
    
    summary['total_skills'] = totalSkills;
    summary['total_uses'] = totalUses;
    summary['average_success_rate'] = averageSuccessRate;
    summary['total_damage'] = totalDamage;
    summary['total_healing'] = totalHealing;
    summary['period'] = period.name;
    
    // Generate recommendations
    final lowSuccessSkills = skillAnalytics.values.where((a) => a.successRate < 0.5).toList();
    if (lowSuccessSkills.isNotEmpty) {
      recommendations['practice_low_success_skills'] = 0.8;
    }
    
    final underusedSkills = skillAnalytics.values.where((a) => a.totalUses < 10).toList();
    if (underusedSkills.isNotEmpty) {
      recommendations['use_underutilized_skills'] = 0.6;
    }
    
    final inefficientSkills = skillAnalytics.values.where((a) => 
      a.averageManaUsed > 100 && a.averageDamageDealt < 50
    ).toList();
    if (inefficientSkills.isNotEmpty) {
      recommendations['optimize_mana_usage'] = 0.75;
    }
    
    // Class-specific recommendations
    switch (characterClass) {
      case CharacterClass.warrior:
        if (totalDamage < 5000) {
          recommendations['upgrade_weapon'] = 0.7;
        }
        break;
      case CharacterClass.mage:
        if (totalDamage / (skillAnalytics.values.fold(0, (sum, a) => sum + a.totalManaUsed) + 1) < 2.0) {
          recommendations['improve_mana_efficiency'] = 0.8;
        }
        break;
      case CharacterClass.rogue:
        final stealthSuccessRate = skillAnalytics.values
            .where((a) => a.skillName.toLowerCase().contains('stealth'))
            .fold(0.0, (sum, a) => sum + a.successRate) / 
            (skillAnalytics.values.where((a) => a.skillName.toLowerCase().contains('stealth')).length + 1);
        if (stealthSuccessRate < 0.6) {
          recommendations['practice_stealth'] = 0.75;
        }
        break;
      case CharacterClass.cleric:
        if (totalHealing < 1000) {
          recommendations['improve_healing'] = 0.7;
        }
        break;
      case CharacterClass.ranger:
      case CharacterClass.paladin:
      case CharacterClass.warlock:
      case CharacterClass.monk:
        // Add specific recommendations for other classes as needed
        break;
    }
    
    return SkillPerformanceReport(
      characterId: characterId,
      reportDate: DateTime.now(),
      period: period,
      skillAnalytics: skillAnalytics,
      insights: insights,
      summary: summary,
      recommendations: recommendations,
    );
  }

  static List<SkillUsageEvent> filterEventsByPeriod(List<SkillUsageEvent> events, AnalyticsPeriod period) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (period) {
      case AnalyticsPeriod.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case AnalyticsPeriod.weekly:
        startDate = now.subtract(Duration(days: 7));
        break;
      case AnalyticsPeriod.monthly:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case AnalyticsPeriod.yearly:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case AnalyticsPeriod.allTime:
        return events;
    }
    
    return events.where((event) => event.timestamp.isAfter(startDate)).toList();
  }

  static Map<String, List<SkillUsageEvent>> groupEventsBySkill(List<SkillUsageEvent> events) {
    final grouped = <String, List<SkillUsageEvent>>{};
    
    for (final event in events) {
      if (!grouped.containsKey(event.skillId)) {
        grouped[event.skillId] = [];
      }
      grouped[event.skillId]!.add(event);
    }
    
    return grouped;
  }

  static List<SkillUsageEvent> createSampleEvents() {
    return [
      SkillUsageEvent(
        id: 'event_1',
        skillId: 'fire_bolt',
        skillName: 'Fire Bolt',
        usageType: SkillUsageType.battle,
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        context: {'enemy_type': 'goblin', 'battle_type': 'quest'},
        wasSuccessful: true,
        effectiveness: 0.8,
        damageDealt: 45,
        damageTaken: 0,
        healingDone: 0,
        manaUsed: 25,
        castTime: Duration(milliseconds: 1500),
        cooldown: Duration(seconds: 3),
      ),
      SkillUsageEvent(
        id: 'event_2',
        skillId: 'ice_shield',
        skillName: 'Ice Shield',
        usageType: SkillUsageType.battle,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        context: {'enemy_type': 'troll', 'battle_type': 'boss'},
        wasSuccessful: true,
        effectiveness: 0.9,
        damageDealt: 0,
        damageTaken: 15,
        healingDone: 0,
        manaUsed: 40,
        castTime: Duration(milliseconds: 2000),
        cooldown: Duration(seconds: 8),
      ),
      SkillUsageEvent(
        id: 'event_3',
        skillId: 'heal',
        skillName: 'Heal',
        usageType: SkillUsageType.battle,
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
        context: {'ally_health': 'low', 'battle_type': 'group'},
        wasSuccessful: true,
        effectiveness: 0.95,
        damageDealt: 0,
        damageTaken: 0,
        healingDone: 80,
        manaUsed: 60,
        castTime: Duration(milliseconds: 2500),
        cooldown: Duration(seconds: 10),
      ),
    ];
  }
}
