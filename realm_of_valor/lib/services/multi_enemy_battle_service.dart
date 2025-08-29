import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/battle_models.dart';

class BattlePosition {
  final int x;
  final int y;
  final String? occupantId;
  final PositionType type;

  BattlePosition({
    required this.x,
    required this.y,
    this.occupantId,
    required this.type,
  });

  factory BattlePosition.fromJson(Map<String, dynamic> json) {
    return BattlePosition(
      x: json['x'],
      y: json['y'],
      occupantId: json['occupantId'],
      type: PositionType.values.firstWhere((e) => e.name == json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'occupantId': occupantId,
      'type': type.name,
    };
  }

  double distanceTo(BattlePosition other) {
    return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2));
  }

  bool isAdjacent(BattlePosition other) {
    return distanceTo(other) <= 1.5;
  }
}

enum PositionType {
  player,
  enemy,
  empty,
  obstacle,
  hazard,
}

class BattleEntity {
  final String id;
  final String name;
  final EntityType type;
  final BattlePosition position;
  final int maxHealth;
  final int currentHealth;
  final int attack;
  final int defense;
  final int speed;
  final List<String> abilities;
  final Map<String, dynamic> stats;
  final bool isAlive;
  final List<String> statusEffects;
  final int initiative;

  BattleEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.maxHealth,
    required this.currentHealth,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.abilities,
    required this.stats,
    required this.isAlive,
    required this.statusEffects,
    required this.initiative,
  });

  factory BattleEntity.fromJson(Map<String, dynamic> json) {
    return BattleEntity(
      id: json['id'],
      name: json['name'],
      type: EntityType.values.firstWhere((e) => e.name == json['type']),
      position: BattlePosition.fromJson(json['position']),
      maxHealth: json['maxHealth'],
      currentHealth: json['currentHealth'],
      attack: json['attack'],
      defense: json['defense'],
      speed: json['speed'],
      abilities: List<String>.from(json['abilities']),
      stats: Map<String, dynamic>.from(json['stats']),
      isAlive: json['isAlive'],
      statusEffects: List<String>.from(json['statusEffects']),
      initiative: json['initiative'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'position': position.toJson(),
      'maxHealth': maxHealth,
      'currentHealth': currentHealth,
      'attack': attack,
      'defense': defense,
      'speed': speed,
      'abilities': abilities,
      'stats': stats,
      'isAlive': isAlive,
      'statusEffects': statusEffects,
      'initiative': initiative,
    };
  }

  BattleEntity copyWith({
    String? id,
    String? name,
    EntityType? type,
    BattlePosition? position,
    int? maxHealth,
    int? currentHealth,
    int? attack,
    int? defense,
    int? speed,
    List<String>? abilities,
    Map<String, dynamic>? stats,
    bool? isAlive,
    List<String>? statusEffects,
    int? initiative,
  }) {
    return BattleEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      speed: speed ?? this.speed,
      abilities: abilities ?? this.abilities,
      stats: stats ?? this.stats,
      isAlive: isAlive ?? this.isAlive,
      statusEffects: statusEffects ?? this.statusEffects,
      initiative: initiative ?? this.initiative,
    );
  }

  double get healthPercentage => maxHealth > 0 ? currentHealth / maxHealth : 0.0;
  bool get isLowHealth => healthPercentage < 0.3;
  bool get isCriticalHealth => healthPercentage < 0.1;
}

enum EntityType {
  player,
  enemy,
  ally,
  boss,
  minion,
  summon,
}

class BattleField {
  final int width;
  final int height;
  final List<List<BattlePosition>> grid;
  final List<BattleEntity> entities;
  final List<BattlePosition> obstacles;
  final List<BattlePosition> hazards;

  BattleField({
    required this.width,
    required this.height,
    required this.grid,
    required this.entities,
    required this.obstacles,
    required this.hazards,
  });

  factory BattleField.fromJson(Map<String, dynamic> json) {
    return BattleField(
      width: json['width'],
      height: json['height'],
      grid: (json['grid'] as List)
          .map((row) => (row as List)
              .map((pos) => BattlePosition.fromJson(pos))
              .toList())
          .toList(),
      entities: (json['entities'] as List)
          .map((e) => BattleEntity.fromJson(e))
          .toList(),
      obstacles: (json['obstacles'] as List)
          .map((o) => BattlePosition.fromJson(o))
          .toList(),
      hazards: (json['hazards'] as List)
          .map((h) => BattlePosition.fromJson(h))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'grid': grid.map((row) => row.map((pos) => pos.toJson()).toList()).toList(),
      'entities': entities.map((e) => e.toJson()).toList(),
      'obstacles': obstacles.map((o) => o.toJson()).toList(),
      'hazards': hazards.map((h) => h.toJson()).toList(),
    };
  }

  BattlePosition? getPosition(int x, int y) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      return grid[y][x];
    }
    return null;
  }

  BattleEntity? getEntityAt(int x, int y) {
    BattlePosition? position = getPosition(x, y);
    if (position?.occupantId != null) {
      return entities.firstWhere((e) => e.id == position!.occupantId);
    }
    return null;
  }

  List<BattleEntity> getEntitiesInRange(BattlePosition center, double range) {
    return entities.where((entity) {
      return entity.isAlive && center.distanceTo(entity.position) <= range;
    }).toList();
  }

  List<BattleEntity> getAdjacentEntities(BattlePosition position) {
    return entities.where((entity) {
      return entity.isAlive && position.isAdjacent(entity.position);
    }).toList();
  }

  bool isPositionOccupied(int x, int y) {
    return getPosition(x, y)?.occupantId != null;
  }

  bool isPositionWalkable(int x, int y) {
    BattlePosition? position = getPosition(x, y);
    return position != null && 
           position.type != PositionType.obstacle && 
           position.type != PositionType.hazard &&
           position.occupantId == null;
  }

  List<BattlePosition> findPath(BattlePosition start, BattlePosition end) {
    // Simple A* pathfinding implementation
    List<BattlePosition> path = [];
    // Implementation would go here
    return path;
  }
}

class MultiEnemyBattleService {
  static BattleField createBattleField({
    required int width,
    required int height,
    required List<BattleEntity> enemies,
    required BattleEntity player,
  }) {
    // Create grid
    List<List<BattlePosition>> grid = List.generate(
      height,
      (y) => List.generate(
        width,
        (x) => BattlePosition(
          x: x,
          y: y,
          type: PositionType.empty,
        ),
      ),
    );

    // Place player
    BattlePosition playerPosition = BattlePosition(
      x: 0,
      y: height ~/ 2,
      type: PositionType.player,
      occupantId: player.id,
    );
    grid[playerPosition.y][playerPosition.x] = playerPosition;

    // Place enemies
    List<BattleEntity> placedEnemies = [];
    Random random = Random();
    
    for (int i = 0; i < enemies.length; i++) {
      BattleEntity enemy = enemies[i];
      int attempts = 0;
      BattlePosition? enemyPosition;
      
      while (attempts < 50 && enemyPosition == null) {
        int x = random.nextInt(width);
        int y = random.nextInt(height);
        
        if (grid[y][x].type == PositionType.empty && 
            grid[y][x].occupantId == null) {
          enemyPosition = BattlePosition(
            x: x,
            y: y,
            type: PositionType.enemy,
            occupantId: enemy.id,
          );
          grid[y][x] = enemyPosition;
        }
        attempts++;
      }
      
      if (enemyPosition != null) {
        placedEnemies.add(enemy.copyWith(position: enemyPosition));
      }
    }

    // Add some obstacles
    List<BattlePosition> obstacles = [];
    for (int i = 0; i < (width * height * 0.1).round(); i++) {
      int x = random.nextInt(width);
      int y = random.nextInt(height);
      
      if (grid[y][x].type == PositionType.empty && 
          grid[y][x].occupantId == null) {
        BattlePosition obstacle = BattlePosition(
          x: x,
          y: y,
          type: PositionType.obstacle,
        );
        grid[y][x] = obstacle;
        obstacles.add(obstacle);
      }
    }

    // Add some hazards
    List<BattlePosition> hazards = [];
    for (int i = 0; i < (width * height * 0.05).round(); i++) {
      int x = random.nextInt(width);
      int y = random.nextInt(height);
      
      if (grid[y][x].type == PositionType.empty && 
          grid[y][x].occupantId == null) {
        BattlePosition hazard = BattlePosition(
          x: x,
          y: y,
          type: PositionType.hazard,
        );
        grid[y][x] = hazard;
        hazards.add(hazard);
      }
    }

    return BattleField(
      width: width,
      height: height,
      grid: grid,
      entities: [player.copyWith(position: playerPosition)] + placedEnemies,
      obstacles: obstacles,
      hazards: hazards,
    );
  }

  static List<BattleEntity> determineTurnOrder(List<BattleEntity> entities) {
    // Sort by initiative (higher first), then by speed (higher first)
    List<BattleEntity> sorted = List.from(entities);
    sorted.sort((a, b) {
      if (a.initiative != b.initiative) {
        return b.initiative.compareTo(a.initiative);
      }
      return b.speed.compareTo(a.speed);
    });
    return sorted.where((e) => e.isAlive).toList();
  }

  static List<BattleEntity> getValidTargets(
    BattleEntity attacker,
    BattleField battlefield,
    String abilityId,
  ) {
    List<BattleEntity> validTargets = [];
    
    // Get ability targeting rules
    TargetingRules rules = _getTargetingRules(abilityId);
    
    switch (rules.targetType) {
      case TargetType.single:
        validTargets = _getSingleTargets(attacker, battlefield, rules);
        break;
      case TargetType.area:
        validTargets = _getAreaTargets(attacker, battlefield, rules);
        break;
      case TargetType.line:
        validTargets = _getLineTargets(attacker, battlefield, rules);
        break;
      case TargetType.self:
        validTargets = [attacker];
        break;
      case TargetType.all:
        validTargets = battlefield.entities.where((e) => e.isAlive).toList();
        break;
    }
    
    return validTargets;
  }

  static List<BattleEntity> _getSingleTargets(
    BattleEntity attacker,
    BattleField battlefield,
    TargetingRules rules,
  ) {
    List<BattleEntity> targets = [];
    
    for (var entity in battlefield.entities) {
      if (!entity.isAlive) continue;
      
      if (rules.canTargetSelf && entity.id == attacker.id) {
        targets.add(entity);
        continue;
      }
      
      if (rules.canTargetAllies && entity.type == EntityType.ally) {
        targets.add(entity);
        continue;
      }
      
      if (rules.canTargetEnemies && entity.type == EntityType.enemy) {
        double distance = attacker.position.distanceTo(entity.position);
        if (distance <= rules.range) {
          targets.add(entity);
        }
      }
    }
    
    return targets;
  }

  static List<BattleEntity> _getAreaTargets(
    BattleEntity attacker,
    BattleField battlefield,
    TargetingRules rules,
  ) {
    List<BattleEntity> targets = [];
    
    for (var entity in battlefield.entities) {
      if (!entity.isAlive) continue;
      
      double distance = attacker.position.distanceTo(entity.position);
      if (distance <= rules.range) {
        if (rules.canTargetSelf && entity.id == attacker.id) {
          targets.add(entity);
        } else if (rules.canTargetAllies && entity.type == EntityType.ally) {
          targets.add(entity);
        } else if (rules.canTargetEnemies && entity.type == EntityType.enemy) {
          targets.add(entity);
        }
      }
    }
    
    return targets;
  }

  static List<BattleEntity> _getLineTargets(
    BattleEntity attacker,
    BattleField battlefield,
    TargetingRules rules,
  ) {
    List<BattleEntity> targets = [];
    
    // Get direction from attacker to target position
    // This is a simplified implementation
    for (var entity in battlefield.entities) {
      if (!entity.isAlive) continue;
      
      double distance = attacker.position.distanceTo(entity.position);
      if (distance <= rules.range) {
        // Check if entity is in line of sight
        if (_isInLineOfSight(attacker.position, entity.position, battlefield)) {
          if (rules.canTargetEnemies && entity.type == EntityType.enemy) {
            targets.add(entity);
          }
        }
      }
    }
    
    return targets;
  }

  static bool _isInLineOfSight(
    BattlePosition start,
    BattlePosition end,
    BattleField battlefield,
  ) {
    // Simple line of sight check
    // In a real implementation, this would use Bresenham's line algorithm
    return true; // Simplified for now
  }

  static TargetingRules _getTargetingRules(String abilityId) {
    // Define targeting rules for different abilities
    switch (abilityId) {
      case 'basic_attack':
        return TargetingRules(
          targetType: TargetType.single,
          range: 1.5,
          canTargetSelf: false,
          canTargetAllies: false,
          canTargetEnemies: true,
        );
      case 'area_attack':
        return TargetingRules(
          targetType: TargetType.area,
          range: 3.0,
          canTargetSelf: false,
          canTargetAllies: false,
          canTargetEnemies: true,
        );
      case 'heal':
        return TargetingRules(
          targetType: TargetType.single,
          range: 2.0,
          canTargetSelf: true,
          canTargetAllies: true,
          canTargetEnemies: false,
        );
      case 'buff':
        return TargetingRules(
          targetType: TargetType.area,
          range: 2.0,
          canTargetSelf: true,
          canTargetAllies: true,
          canTargetEnemies: false,
        );
      default:
        return TargetingRules(
          targetType: TargetType.single,
          range: 1.0,
          canTargetSelf: false,
          canTargetAllies: false,
          canTargetEnemies: true,
        );
    }
  }

  static bool canMoveTo(
    BattleEntity entity,
    BattlePosition targetPosition,
    BattleField battlefield,
  ) {
    if (!battlefield.isPositionWalkable(targetPosition.x, targetPosition.y)) {
      return false;
    }
    
    double distance = entity.position.distanceTo(targetPosition);
    return distance <= entity.speed;
  }

  static List<BattlePosition> getValidMovePositions(
    BattleEntity entity,
    BattleField battlefield,
  ) {
    List<BattlePosition> validPositions = [];
    
    for (int y = 0; y < battlefield.height; y++) {
      for (int x = 0; x < battlefield.width; x++) {
        BattlePosition position = battlefield.getPosition(x, y)!;
        if (canMoveTo(entity, position, battlefield)) {
          validPositions.add(position);
        }
      }
    }
    
    return validPositions;
  }
}

class TargetingRules {
  final TargetType targetType;
  final double range;
  final bool canTargetSelf;
  final bool canTargetAllies;
  final bool canTargetEnemies;

  TargetingRules({
    required this.targetType,
    required this.range,
    required this.canTargetSelf,
    required this.canTargetAllies,
    required this.canTargetEnemies,
  });
}

enum TargetType {
  single,
  area,
  line,
  self,
  all,
}

// Riverpod providers
final multiEnemyBattleServiceProvider = Provider<MultiEnemyBattleService>((ref) {
  return MultiEnemyBattleService();
});

final currentBattleFieldProvider = StateProvider<BattleField?>((ref) {
  return null;
});

final turnOrderProvider = StateProvider<List<BattleEntity>>((ref) {
  return [];
});
