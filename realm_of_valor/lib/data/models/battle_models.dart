import 'package:equatable/equatable.dart';

enum BattlePhase {
  preparation,
  playerTurn,
  enemyTurn,
  resolution,
  completed,
}

enum EnemyActionType {
  attack,
  defend,
  special,
  heal,
  buff,
  debuff,
}

enum AnimationType {
  attack,
  defend,
  heal,
  buff,
  debuff,
  special,
  victory,
  defeat,
}

class EnemyDecision extends Equatable {
  final EnemyActionType actionType;
  final String target;
  final Map<String, dynamic> parameters;
  final double confidence;

  const EnemyDecision({
    required this.actionType,
    required this.target,
    required this.parameters,
    required this.confidence,
  });

  factory EnemyDecision.fromJson(Map<String, dynamic> json) {
    return EnemyDecision(
      actionType: EnemyActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
      ),
      target: json['target'],
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      confidence: json['confidence']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType.name,
      'target': target,
      'parameters': parameters,
      'confidence': confidence,
    };
  }

  @override
  List<Object?> get props => [actionType, target, parameters, confidence];
}

class AnimationEffect extends Equatable {
  final AnimationType type;
  final String target;
  final Map<String, dynamic> parameters;
  final int duration;

  const AnimationEffect({
    required this.type,
    required this.target,
    required this.parameters,
    required this.duration,
  });

  factory AnimationEffect.fromJson(Map<String, dynamic> json) {
    return AnimationEffect(
      type: AnimationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      target: json['target'],
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      duration: json['duration'] ?? 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'target': target,
      'parameters': parameters,
      'duration': duration,
    };
  }

  @override
  List<Object?> get props => [type, target, parameters, duration];
}

class BattleRewards extends Equatable {
  final int experience;
  final int gold;
  final List<String> cards;
  final List<String> items;
  final Map<String, dynamic> specialRewards;

  const BattleRewards({
    required this.experience,
    required this.gold,
    required this.cards,
    required this.items,
    required this.specialRewards,
  });

  factory BattleRewards.fromJson(Map<String, dynamic> json) {
    return BattleRewards(
      experience: json['experience'] ?? 0,
      gold: json['gold'] ?? 0,
      cards: List<String>.from(json['cards'] ?? []),
      items: List<String>.from(json['items'] ?? []),
      specialRewards: Map<String, dynamic>.from(json['specialRewards'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'experience': experience,
      'gold': gold,
      'cards': cards,
      'items': items,
      'specialRewards': specialRewards,
    };
  }

  @override
  List<Object?> get props => [experience, gold, cards, items, specialRewards];
}

class BattleAction extends Equatable {
  final String id;
  final String actor;
  final String target;
  final String actionType;
  final Map<String, dynamic> parameters;
  final int turnNumber;
  final DateTime timestamp;

  const BattleAction({
    required this.id,
    required this.actor,
    required this.target,
    required this.actionType,
    required this.parameters,
    required this.turnNumber,
    required this.timestamp,
  });

  factory BattleAction.fromJson(Map<String, dynamic> json) {
    return BattleAction(
      id: json['id'],
      actor: json['actor'],
      target: json['target'],
      actionType: json['actionType'],
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      turnNumber: json['turnNumber'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actor': actor,
      'target': target,
      'actionType': actionType,
      'parameters': parameters,
      'turnNumber': turnNumber,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id, 
    actor, 
    target, 
    actionType, 
    parameters, 
    turnNumber, 
    timestamp
  ];
}

class BattleStatistics extends Equatable {
  final int totalTurns;
  final int playerActions;
  final int enemyActions;
  final int damageDealt;
  final int damageReceived;
  final int healingDone;
  final int cardsPlayed;
  final int specialAbilitiesUsed;
  final Duration battleDuration;
  final String winner;

  const BattleStatistics({
    required this.totalTurns,
    required this.playerActions,
    required this.enemyActions,
    required this.damageDealt,
    required this.damageReceived,
    required this.healingDone,
    required this.cardsPlayed,
    required this.specialAbilitiesUsed,
    required this.battleDuration,
    required this.winner,
  });

  factory BattleStatistics.fromJson(Map<String, dynamic> json) {
    return BattleStatistics(
      totalTurns: json['totalTurns'] ?? 0,
      playerActions: json['playerActions'] ?? 0,
      enemyActions: json['enemyActions'] ?? 0,
      damageDealt: json['damageDealt'] ?? 0,
      damageReceived: json['damageReceived'] ?? 0,
      healingDone: json['healingDone'] ?? 0,
      cardsPlayed: json['cardsPlayed'] ?? 0,
      specialAbilitiesUsed: json['specialAbilitiesUsed'] ?? 0,
      battleDuration: Duration(milliseconds: json['battleDurationMs'] ?? 0),
      winner: json['winner'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTurns': totalTurns,
      'playerActions': playerActions,
      'enemyActions': enemyActions,
      'damageDealt': damageDealt,
      'damageReceived': damageReceived,
      'healingDone': healingDone,
      'cardsPlayed': cardsPlayed,
      'specialAbilitiesUsed': specialAbilitiesUsed,
      'battleDurationMs': battleDuration.inMilliseconds,
      'winner': winner,
    };
  }

  @override
  List<Object?> get props => [
    totalTurns,
    playerActions,
    enemyActions,
    damageDealt,
    damageReceived,
    healingDone,
    cardsPlayed,
    specialAbilitiesUsed,
    battleDuration,
    winner,
  ];
}
