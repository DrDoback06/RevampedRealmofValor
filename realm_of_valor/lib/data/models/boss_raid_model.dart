import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'boss_quest_model.dart';

part 'boss_raid_model.g.dart';

/// BOSS RAID SYSTEM for 1-4 Player Co-op
/// Following existing turn-based combat system
/// "Don't Remove, Only Improve!"
/// 
/// ENHANCEMENTS (15+):
/// 1. Dynamic scaling (1-4 players)
/// 2. Multi-phase boss mechanics
/// 3. Individual card decks with combo potential
/// 4. Personal loot + shared gold/XP
/// 5. Boss enrage timer (makes boss harder over time)
/// 6. Environmental hazards
/// 7. Boss special abilities per phase
/// 8. Party resurrection (limited)
/// 9. Boss weak points (targeting system)
/// 10. Combo multipliers for coordinated attacks
/// 11. MVP tracking
/// 12. Raid statistics
/// 13. Weekly raid rotation
/// 14. Heroic and Mythic difficulty modes
/// 15. Raid achievements
/// 16. Reconnection support (if player disconnects)
/// 17. Practice mode (no rewards, test strategies)

enum RaidDifficulty {
  normal,   // Baseline
  heroic,   // +50% HP/damage, better loot
  mythic,   // +100% HP/damage, epic loot
}

enum RaidStatus {
  waiting,     // Waiting for players
  ready,       // All players ready
  inProgress,  // Battle ongoing
  completed,   // Boss defeated
  failed,      // Party wiped
  abandoned,   // Players left
}

enum BossPhaseState {
  notStarted,
  active,
  completed,
}

@JsonSerializable()
class BossRaid extends Equatable {
  final String raidId;
  final String bossId;
  final String bossName;
  final RaidDifficulty difficulty;
  final String partyId;
  final List<RaidParticipant> participants;
  final RaidStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  
  // Boss stats (scales with party size and difficulty)
  final int bossMaxHp;
  final int bossCurrentHp;
  final int bossAttack;
  final int bossDefense;
  final int bossLevel;
  
  // Boss mechanics
  final int currentPhase; // 0, 1, 2 for 3-phase boss
  final List<BossPhaseState> phaseStates;
  final List<String> activeAbilities; // Current boss abilities
  
  // Combat state (turn-based like 1v1)
  final int turnNumber;
  final String? currentTurnUserId; // Whose turn it is
  final int turnTimeRemaining; // Seconds
  
  // Enhancement 1: Enrage timer
  final int enrageTimeSeconds; // Boss gets harder after this
  final bool isEnraged;
  
  // Enhancement 2: Environmental hazards
  final List<String> activeHazards; // Fire, poison, etc.
  
  // Enhancement 3: Combo system
  final int comboCount; // Consecutive coordinated attacks
  final double comboMultiplier; // 1.0 to 2.0
  
  // Enhancement 4: Resurrections
  final int resurrectionsRemaining; // Shared pool
  
  // Enhancement 5: Statistics
  final Map<String, RaidStatistics> playerStats;
  
  const BossRaid({
    required this.raidId,
    required this.bossId,
    required this.bossName,
    required this.difficulty,
    required this.partyId,
    required this.participants,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.bossMaxHp,
    required this.bossCurrentHp,
    required this.bossAttack,
    required this.bossDefense,
    required this.bossLevel,
    required this.currentPhase,
    required this.phaseStates,
    required this.activeAbilities,
    required this.turnNumber,
    this.currentTurnUserId,
    this.turnTimeRemaining = 60,
    required this.enrageTimeSeconds,
    this.isEnraged = false,
    this.activeHazards = const [],
    this.comboCount = 0,
    this.comboMultiplier = 1.0,
    this.resurrectionsRemaining = 3,
    this.playerStats = const {},
  });

  factory BossRaid.fromJson(Map<String, dynamic> json) => _$BossRaidFromJson(json);
  Map<String, dynamic> toJson() => _$BossRaidToJson(this);

  @override
  List<Object?> get props => [
    raidId, bossId, bossName, difficulty, partyId, participants, status,
    startTime, endTime, bossMaxHp, bossCurrentHp, bossAttack, bossDefense,
    bossLevel, currentPhase, phaseStates, activeAbilities, turnNumber,
    currentTurnUserId, turnTimeRemaining, enrageTimeSeconds, isEnraged,
    activeHazards, comboCount, comboMultiplier, resurrectionsRemaining,
    playerStats,
  ];
  
  // Helper getters
  bool get isComplete => status == RaidStatus.completed;
  bool get isFailed => status == RaidStatus.failed;
  bool get isActive => status == RaidStatus.inProgress;
  
  int get alivePlayers => participants.where((p) => p.isAlive).length;
  int get deadPlayers => participants.where((p) => !p.isAlive).length;
  bool get isWiped => alivePlayers == 0;
  
  double get bossHpPercent => bossMaxHp > 0 ? (bossCurrentHp / bossMaxHp) : 0.0;
  
  /// Get current phase info
  BossPhaseState getCurrentPhaseState() {
    if (currentPhase >= phaseStates.length) return BossPhaseState.notStarted;
    return phaseStates[currentPhase];
  }
  
  /// Check if should transition to next phase (typically at 66% and 33% HP)
  bool shouldTransitionPhase() {
    if (currentPhase == 0 && bossHpPercent <= 0.66) return true;
    if (currentPhase == 1 && bossHpPercent <= 0.33) return true;
    return false;
  }
  
  /// Get participant by user ID
  RaidParticipant? getParticipant(String userId) {
    try {
      return participants.firstWhere((p) => p.userId == userId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get MVP (most damage + healing)
  String? getMVP() {
    if (playerStats.isEmpty) return null;
    
    String? mvpId;
    int maxScore = 0;
    
    playerStats.forEach((userId, stats) {
      final score = stats.totalDamage + (stats.totalHealing * 2); // Healing worth more
      if (score > maxScore) {
        maxScore = score;
        mvpId = userId;
      }
    });
    
    return mvpId;
  }
  
  /// Calculate rewards multiplier based on performance
  double getRewardsMultiplier() {
    double multiplier = 1.0;
    
    // Difficulty bonus
    switch (difficulty) {
      case RaidDifficulty.normal:
        multiplier *= 1.0;
        break;
      case RaidDifficulty.heroic:
        multiplier *= 1.5;
        break;
      case RaidDifficulty.mythic:
        multiplier *= 2.0;
        break;
    }
    
    // Speed bonus (if completed fast)
    final duration = endTime != null 
        ? endTime!.difference(startTime).inMinutes 
        : 0;
    if (duration > 0 && duration < 10) {
      multiplier *= 1.2; // +20% for completing in <10 mins
    }
    
    // No deaths bonus
    if (deadPlayers == 0) {
      multiplier *= 1.1; // +10% for flawless victory
    }
    
    // Combo bonus
    if (comboCount >= 10) {
      multiplier *= 1.15; // +15% for good teamwork
    }
    
    return multiplier;
  }
  
  /// Copy with method
  BossRaid copyWith({
    String? raidId,
    String? bossId,
    String? bossName,
    RaidDifficulty? difficulty,
    String? partyId,
    List<RaidParticipant>? participants,
    RaidStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? bossMaxHp,
    int? bossCurrentHp,
    int? bossAttack,
    int? bossDefense,
    int? bossLevel,
    int? currentPhase,
    List<BossPhaseState>? phaseStates,
    List<String>? activeAbilities,
    int? turnNumber,
    String? currentTurnUserId,
    int? turnTimeRemaining,
    int? enrageTimeSeconds,
    bool? isEnraged,
    List<String>? activeHazards,
    int? comboCount,
    double? comboMultiplier,
    int? resurrectionsRemaining,
    Map<String, RaidStatistics>? playerStats,
  }) {
    return BossRaid(
      raidId: raidId ?? this.raidId,
      bossId: bossId ?? this.bossId,
      bossName: bossName ?? this.bossName,
      difficulty: difficulty ?? this.difficulty,
      partyId: partyId ?? this.partyId,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      bossMaxHp: bossMaxHp ?? this.bossMaxHp,
      bossCurrentHp: bossCurrentHp ?? this.bossCurrentHp,
      bossAttack: bossAttack ?? this.bossAttack,
      bossDefense: bossDefense ?? this.bossDefense,
      bossLevel: bossLevel ?? this.bossLevel,
      currentPhase: currentPhase ?? this.currentPhase,
      phaseStates: phaseStates ?? this.phaseStates,
      activeAbilities: activeAbilities ?? this.activeAbilities,
      turnNumber: turnNumber ?? this.turnNumber,
      currentTurnUserId: currentTurnUserId ?? this.currentTurnUserId,
      turnTimeRemaining: turnTimeRemaining ?? this.turnTimeRemaining,
      enrageTimeSeconds: enrageTimeSeconds ?? this.enrageTimeSeconds,
      isEnraged: isEnraged ?? this.isEnraged,
      activeHazards: activeHazards ?? this.activeHazards,
      comboCount: comboCount ?? this.comboCount,
      comboMultiplier: comboMultiplier ?? this.comboMultiplier,
      resurrectionsRemaining: resurrectionsRemaining ?? this.resurrectionsRemaining,
      playerStats: playerStats ?? this.playerStats,
    );
  }
}

@JsonSerializable()
class RaidParticipant extends Equatable {
  final String userId;
  final String characterName;
  final int level;
  final String role; // tank, dps, support, flex
  
  // Combat state
  final int maxHp;
  final int currentHp;
  final int maxMana;
  final int currentMana;
  final int attack;
  final int defense;
  
  // Card system (individual decks)
  final List<String> cardIds; // Cards in deck
  final List<String> handCardIds; // Cards in hand
  final List<String> loadedCardIds; // Cards loaded for attack
  
  // Status
  final bool isAlive;
  final bool isReady;
  final Map<String, int> activeEffects; // effect_name: duration
  
  const RaidParticipant({
    required this.userId,
    required this.characterName,
    required this.level,
    required this.role,
    required this.maxHp,
    required this.currentHp,
    required this.maxMana,
    required this.currentMana,
    required this.attack,
    required this.defense,
    required this.cardIds,
    required this.handCardIds,
    required this.loadedCardIds,
    this.isAlive = true,
    this.isReady = false,
    this.activeEffects = const {},
  });

  factory RaidParticipant.fromJson(Map<String, dynamic> json) => _$RaidParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$RaidParticipantToJson(this);

  @override
  List<Object?> get props => [
    userId, characterName, level, role, maxHp, currentHp, maxMana, currentMana,
    attack, defense, cardIds, handCardIds, loadedCardIds, isAlive, isReady,
    activeEffects,
  ];
  
  double get hpPercent => maxHp > 0 ? (currentHp / maxHp) : 0.0;
  double get manaPercent => maxMana > 0 ? (currentMana / maxMana) : 0.0;
  
  bool get isLowHp => hpPercent < 0.3;
  bool get isLowMana => manaPercent < 0.3;
  
  RaidParticipant copyWith({
    String? userId,
    String? characterName,
    int? level,
    String? role,
    int? maxHp,
    int? currentHp,
    int? maxMana,
    int? currentMana,
    int? attack,
    int? defense,
    List<String>? cardIds,
    List<String>? handCardIds,
    List<String>? loadedCardIds,
    bool? isAlive,
    bool? isReady,
    Map<String, int>? activeEffects,
  }) {
    return RaidParticipant(
      userId: userId ?? this.userId,
      characterName: characterName ?? this.characterName,
      level: level ?? this.level,
      role: role ?? this.role,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      maxMana: maxMana ?? this.maxMana,
      currentMana: currentMana ?? this.currentMana,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      cardIds: cardIds ?? this.cardIds,
      handCardIds: handCardIds ?? this.handCardIds,
      loadedCardIds: loadedCardIds ?? this.loadedCardIds,
      isAlive: isAlive ?? this.isAlive,
      isReady: isReady ?? this.isReady,
      activeEffects: activeEffects ?? this.activeEffects,
    );
  }
}

@JsonSerializable()
class RaidStatistics extends Equatable {
  final int totalDamage;
  final int totalHealing;
  final int cardsPlayed;
  final int combosTriggered;
  final int deathCount;
  final int resurrections;
  
  const RaidStatistics({
    this.totalDamage = 0,
    this.totalHealing = 0,
    this.cardsPlayed = 0,
    this.combosTriggered = 0,
    this.deathCount = 0,
    this.resurrections = 0,
  });

  factory RaidStatistics.fromJson(Map<String, dynamic> json) => _$RaidStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$RaidStatisticsToJson(this);

  @override
  List<Object?> get props => [
    totalDamage, totalHealing, cardsPlayed, combosTriggered, deathCount, resurrections,
  ];
  
  RaidStatistics copyWith({
    int? totalDamage,
    int? totalHealing,
    int? cardsPlayed,
    int? combosTriggered,
    int? deathCount,
    int? resurrections,
  }) {
    return RaidStatistics(
      totalDamage: totalDamage ?? this.totalDamage,
      totalHealing: totalHealing ?? this.totalHealing,
      cardsPlayed: cardsPlayed ?? this.cardsPlayed,
      combosTriggered: combosTriggered ?? this.combosTriggered,
      deathCount: deathCount ?? this.deathCount,
      resurrections: resurrections ?? this.resurrections,
    );
  }
}

/// Enhancement 6: Card combo definitions
@JsonSerializable()
class CardCombo extends Equatable {
  final String comboId;
  final String name;
  final String description;
  final List<String> requiredCardIds; // Cards needed
  final double damageMultiplier; // 1.5x, 2.0x, etc.
  final String effect; // 'stun', 'burn', 'weaken', etc.
  
  const CardCombo({
    required this.comboId,
    required this.name,
    required this.description,
    required this.requiredCardIds,
    required this.damageMultiplier,
    required this.effect,
  });

  factory CardCombo.fromJson(Map<String, dynamic> json) => _$CardComboFromJson(json);
  Map<String, dynamic> toJson() => _$CardComboToJson(this);

  @override
  List<Object?> get props => [
    comboId, name, description, requiredCardIds, damageMultiplier, effect,
  ];
}

/// Common combo definitions
class CommonCombos {
  static final List<CardCombo> all = [
    const CardCombo(
      comboId: 'fire_storm',
      name: 'Fire Storm',
      description: '2 fire spells = Double damage + Burn',
      requiredCardIds: ['fire_spell', 'fire_spell'],
      damageMultiplier: 2.0,
      effect: 'burn',
    ),
    const CardCombo(
      comboId: 'ice_shatter',
      name: 'Ice Shatter',
      description: 'Freeze + Physical attack = Triple damage',
      requiredCardIds: ['ice_spell', 'physical_attack'],
      damageMultiplier: 3.0,
      effect: 'shatter',
    ),
    const CardCombo(
      comboId: 'healing_boost',
      name: 'Healing Boost',
      description: '2 heal spells = 150% healing',
      requiredCardIds: ['heal_spell', 'heal_spell'],
      damageMultiplier: 1.5,
      effect: 'heal_boost',
    ),
    const CardCombo(
      comboId: 'shield_bash',
      name: 'Shield Bash',
      description: 'Shield + Attack = Stun',
      requiredCardIds: ['shield_spell', 'physical_attack'],
      damageMultiplier: 1.5,
      effect: 'stun',
    ),
  ];
}
