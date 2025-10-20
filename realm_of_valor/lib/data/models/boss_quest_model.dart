import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'quest_model.dart';

/// Boss Quest System for Epic Locations
/// 
/// ENHANCEMENTS:
/// 1. Multi-phase boss battles (3-5 phases)
/// 2. Location-based boss spawns (summit = dragon, waterfall = hydra)
/// 3. Boss mechanics (enrage, summons, special abilities)
/// 4. Epic loot tables (guaranteed legendary+ drops)
/// 5. Boss health scales with party size (1-4 players)
/// 6. Weekly boss rotation
/// 7. Boss leaderboards (fastest kills, highest damage)
/// 8. Unique boss achievements
/// 9. Boss difficulty tiers (Normal, Heroic, Mythic)
/// 10. Environmental hazards during boss fights

enum BossDifficulty { normal, heroic, mythic }

enum BossPhase { phase1, phase2, phase3, phase4, phase5 }

enum BossType {
  dragon,         // Mountain summits
  hydra,          // Waterfalls
  kraken,         // Lakes
  giant,          // Coastal cliffs
  treant,         // Ancient forests
  wraith,         // Historic ruins
}

class BossQuest {
  final String id;
  final String bossName;
  final BossType bossType;
  final BossDifficulty difficulty;
  final LatLng location;
  final String locationName; // e.g., "Summit of Snowdon"
  final int baseHealth;
  final int baseDamage;
  final List<BossPhase> phases;
  final Map<BossPhase, BossAbility> phaseAbilities;
  final QuestRewards normalRewards;
  final QuestRewards heroicRewards;
  final QuestRewards mythicRewards;
  final int recommendedLevel;
  final int recommendedPlayers;
  final Duration enrageTimer;
  final List<String> mechanics; // ["Summon adds at 50% HP", "AoE at 25%", etc.]
  final String lore; // Boss backstory
  final bool isWeeklyBoss;
  
  const BossQuest({
    required this.id,
    required this.bossName,
    required this.bossType,
    required this.difficulty,
    required this.location,
    required this.locationName,
    required this.baseHealth,
    required this.baseDamage,
    required this.phases,
    required this.phaseAbilities,
    required this.normalRewards,
    required this.heroicRewards,
    required this.mythicRewards,
    required this.recommendedLevel,
    required this.recommendedPlayers,
    required this.enrageTimer,
    required this.mechanics,
    required this.lore,
    this.isWeeklyBoss = false,
  });

  /// Get rewards for current difficulty
  QuestRewards getRewards() {
    switch (difficulty) {
      case BossDifficulty.normal:
        return normalRewards;
      case BossDifficulty.heroic:
        return heroicRewards;
      case BossDifficulty.mythic:
        return mythicRewards;
    }
  }

  /// Scale health for party size
  int getScaledHealth(int partySize) {
    return (baseHealth * (1.0 + (partySize - 1) * 0.5)).round();
  }

  /// Get appropriate icon for boss type
  String get bossIcon {
    switch (bossType) {
      case BossType.dragon:
        return '🐉';
      case BossType.hydra:
        return '🐍';
      case BossType.kraken:
        return '🐙';
      case BossType.giant:
        return '🗿';
      case BossType.treant:
        return '🌳';
      case BossType.wraith:
        return '👻';
    }
  }

  /// Get difficulty color
  Color get difficultyColor {
    switch (difficulty) {
      case BossDifficulty.normal:
        return const Color(0xFF4CAF50);
      case BossDifficulty.heroic:
        return const Color(0xFFFFA726);
      case BossDifficulty.mythic:
        return const Color(0xFFE91E63);
    }
  }
}

class BossAbility {
  final String name;
  final String description;
  final int damage;
  final String effect;
  final int cooldown;
  
  const BossAbility({
    required this.name,
    required this.description,
    required this.damage,
    required this.effect,
    required this.cooldown,
  });
}

/// Factory for creating boss quests at epic locations
class BossQuestFactory {
  /// Create boss quest for Snowdon (Wales' highest peak)
  static BossQuest createSnowdonDragon() {
    return BossQuest(
      id: 'boss_snowdon_dragon',
      bossName: 'Ddraig Eryri - The Snowdon Drake',
      bossType: BossType.dragon,
      difficulty: BossDifficulty.normal,
      location: const LatLng(53.0685, -4.0764), // Snowdon summit
      locationName: 'Summit of Snowdon',
      baseHealth: 5000,
      baseDamage: 150,
      phases: [BossPhase.phase1, BossPhase.phase2, BossPhase.phase3],
      phaseAbilities: {
        BossPhase.phase1: const BossAbility(
          name: 'Mountain Roar',
          description: 'AoE damage to all players',
          damage: 100,
          effect: 'All players take 100 damage',
          cooldown: 30,
        ),
        BossPhase.phase2: const BossAbility(
          name: 'Flame Breath',
          description: 'Cone of fire damage',
          damage: 200,
          effect: 'Frontal cone 200 damage',
          cooldown: 25,
        ),
        BossPhase.phase3: const BossAbility(
          name: 'Sky Fury',
          description: 'Enraged strikes and adds summon',
          damage: 150,
          effect: 'Summons 2 wyrmlings, attacks faster',
          cooldown: 20,
        ),
      },
      normalRewards: const QuestRewards(
        xp: 1000,
        gold: 500,
        items: ['legendary_dragon_scale', 'epic_mountain_gear'],
      ),
      heroicRewards: const QuestRewards(
        xp: 2000,
        gold: 1000,
        items: ['mythic_dragon_claw', 'legendary_mountain_gear', 'snowdon_conqueror_title'],
      ),
      mythicRewards: const QuestRewards(
        xp: 5000,
        gold: 2500,
        items: ['mythic_dragon_heart', 'mythic_drake_mount', 'snowdon_legend_title'],
      ),
      recommendedLevel: 15,
      recommendedPlayers: 3,
      enrageTimer: const Duration(minutes: 15),
      mechanics: [
        'At 100% HP: Basic attacks',
        'At 66% HP: Summons mountain winds (knockback)',
        'At 33% HP: Flame breath every 25s',
        'At 10% HP: Berserk mode (double attack speed)',
      ],
      lore: 'Ddraig Eryri, the ancient drake of Snowdon, has slumbered for centuries. '
            'Legends say it awakens only when brave warriors reach the summit. '
            'Defeat it to claim the title of Snowdon Conqueror!',
      isWeeklyBoss: true,
    );
  }

  /// Create boss quest for Ben Nevis (UK's highest peak)
  static BossQuest createBenNevisTitan() {
    return BossQuest(
      id: 'boss_ben_nevis_titan',
      bossName: 'Nevis the Mountain Titan',
      bossType: BossType.giant,
      difficulty: BossDifficulty.normal,
      location: const LatLng(56.7965, -5.0037), // Ben Nevis summit
      locationName: 'Summit of Ben Nevis',
      baseHealth: 7500,
      baseDamage: 200,
      phases: [BossPhase.phase1, BossPhase.phase2, BossPhase.phase3, BossPhase.phase4],
      phaseAbilities: {
        BossPhase.phase1: const BossAbility(
          name: 'Boulder Throw',
          description: 'Hurls massive boulders',
          damage: 150,
          effect: 'Random target takes 150 damage',
          cooldown: 20,
        ),
        BossPhase.phase2: const BossAbility(
          name: 'Earthquake Stomp',
          description: 'Ground tremor hits all',
          damage: 100,
          effect: 'All players take 100 damage and stunned 2s',
          cooldown: 30,
        ),
        BossPhase.phase3: const BossAbility(
          name: 'Avalanche Summon',
          description: 'Summons ice elementals',
          damage: 0,
          effect: 'Summons 3 ice elementals',
          cooldown: 45,
        ),
        BossPhase.phase4: const BossAbility(
          name: 'Titan\'s Rage',
          description: 'Berserk multi-target attacks',
          damage: 250,
          effect: 'Attacks 3 random targets for 250 each',
          cooldown: 15,
        ),
      },
      normalRewards: const QuestRewards(
        xp: 1500,
        gold: 750,
        items: ['legendary_titan_stone', 'epic_highland_armor'],
      ),
      heroicRewards: const QuestRewards(
        xp: 3000,
        gold: 1500,
        items: ['mythic_titan_hammer', 'legendary_summit_crown', 'ben_nevis_champion_title'],
      ),
      mythicRewards: const QuestRewards(
        xp: 7500,
        gold: 3750,
        items: ['mythic_mountain_heart', 'mythic_titan_companion', 'uk_summit_master_title'],
      ),
      recommendedLevel: 20,
      recommendedPlayers: 4,
      enrageTimer: const Duration(minutes: 20),
      mechanics: [
        'At 100% HP: Boulder throws',
        'At 75% HP: Earthquake stomps knock back',
        'At 50% HP: Summons ice elementals',
        'At 25% HP: Titan\'s Rage (enraged)',
        'Enrage at 20 min: Boss damage x2',
      ],
      lore: 'Nevis, the ancient titan, guards the highest peak in Britain. '
            'Born from the mountain itself, this colossus tests only the strongest adventurers. '
            'Only those who conquer the titan earn the right to call themselves UK Summit Master!',
      isWeeklyBoss: true,
    );
  }

  /// Get all boss quests
  static List<BossQuest> getAllBosses() {
    return [
      createSnowdonDragon(),
      createBenNevisTitan(),
      // More bosses would be added here
    ];
  }
}
