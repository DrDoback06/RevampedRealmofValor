import '../../../data/models/card_model.dart';

enum BattlePhase {
  draw,
  action,
  end,
}

enum EnemyActionType {
  attack,
  defend,
  heal,
  special,
}

class EnemyDecision {
  final EnemyActionType type;
  final GameCard? card;
  final int priority;

  const EnemyDecision({
    required this.type,
    this.card,
    required this.priority,
  });
}

enum AnimationType {
  damageNumber,
  effectText,
  cardPlay,
  turnTransition,
}

class AnimationEffect {
  final AnimationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const AnimationEffect({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class BattleRewards {
  final int experience;
  final int gold;
  final List<GameCard> cards;

  const BattleRewards({
    required this.experience,
    required this.gold,
    required this.cards,
  });
}

class BattleAction {
  final int turnNumber;
  final bool isPlayerAction;
  final String actionType;
  final String description;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const BattleAction({
    required this.turnNumber,
    required this.isPlayerAction,
    required this.actionType,
    required this.description,
    required this.data,
    required this.timestamp,
  });
}

class BattleStatistics {
  final int turnsPlayed;
  final int cardsPlayed;
  final int damageDealt;
  final int damageTaken;
  final int healingDone;
  final int manaSpent;
  final List<String> specialEffectsUsed;
  final DateTime battleStartTime;
  final DateTime? battleEndTime;

  const BattleStatistics({
    required this.turnsPlayed,
    required this.cardsPlayed,
    required this.damageDealt,
    required this.damageTaken,
    required this.healingDone,
    required this.manaSpent,
    required this.specialEffectsUsed,
    required this.battleStartTime,
    this.battleEndTime,
  });

  Duration get battleDuration {
    final endTime = battleEndTime ?? DateTime.now();
    return endTime.difference(battleStartTime);
  }

  double get efficiency {
    if (turnsPlayed == 0) return 0.0;
    return (damageDealt + healingDone) / turnsPlayed;
  }

  BattleStatistics copyWith({
    int? turnsPlayed,
    int? cardsPlayed,
    int? damageDealt,
    int? damageTaken,
    int? healingDone,
    int? manaSpent,
    List<String>? specialEffectsUsed,
    DateTime? battleStartTime,
    DateTime? battleEndTime,
  }) {
    return BattleStatistics(
      turnsPlayed: turnsPlayed ?? this.turnsPlayed,
      cardsPlayed: cardsPlayed ?? this.cardsPlayed,
      damageDealt: damageDealt ?? this.damageDealt,
      damageTaken: damageTaken ?? this.damageTaken,
      healingDone: healingDone ?? this.healingDone,
      manaSpent: manaSpent ?? this.manaSpent,
      specialEffectsUsed: specialEffectsUsed ?? this.specialEffectsUsed,
      battleStartTime: battleStartTime ?? this.battleStartTime,
      battleEndTime: battleEndTime ?? this.battleEndTime,
    );
  }
}