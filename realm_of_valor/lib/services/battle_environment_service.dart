import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/battle_models.dart';
import '../data/models/weather_model.dart';
import '../data/models/quest_models.dart';

class BattleEnvironment {
  final String id;
  final String name;
  final String description;
  final String backgroundImage;
  final List<EnvironmentEffect> effects;
  final List<String> ambientSounds;
  final Map<String, double> statModifiers;
  final List<String> specialRules;
  final String weatherCondition;
  final String timeOfDay;
  final String locationType;

  BattleEnvironment({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundImage,
    required this.effects,
    required this.ambientSounds,
    required this.statModifiers,
    required this.specialRules,
    required this.weatherCondition,
    required this.timeOfDay,
    required this.locationType,
  });

  factory BattleEnvironment.fromJson(Map<String, dynamic> json) {
    return BattleEnvironment(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      backgroundImage: json['backgroundImage'],
      effects: (json['effects'] as List)
          .map((e) => EnvironmentEffect.fromJson(e))
          .toList(),
      ambientSounds: List<String>.from(json['ambientSounds']),
      statModifiers: Map<String, double>.from(json['statModifiers']),
      specialRules: List<String>.from(json['specialRules']),
      weatherCondition: json['weatherCondition'],
      timeOfDay: json['timeOfDay'],
      locationType: json['locationType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'backgroundImage': backgroundImage,
      'effects': effects.map((e) => e.toJson()).toList(),
      'ambientSounds': ambientSounds,
      'statModifiers': statModifiers,
      'specialRules': specialRules,
      'weatherCondition': weatherCondition,
      'timeOfDay': timeOfDay,
      'locationType': locationType,
    };
  }
}

class EnvironmentEffect {
  final String id;
  final String name;
  final String description;
  final EffectType type;
  final Map<String, double> modifiers;
  final int duration;
  final String triggerCondition;
  final String visualEffect;
  final String soundEffect;

  EnvironmentEffect({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.modifiers,
    required this.duration,
    required this.triggerCondition,
    required this.visualEffect,
    required this.soundEffect,
  });

  factory EnvironmentEffect.fromJson(Map<String, dynamic> json) {
    return EnvironmentEffect(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: EffectType.values.firstWhere((e) => e.name == json['type']),
      modifiers: Map<String, double>.from(json['modifiers']),
      duration: json['duration'],
      triggerCondition: json['triggerCondition'],
      visualEffect: json['visualEffect'],
      soundEffect: json['soundEffect'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'modifiers': modifiers,
      'duration': duration,
      'triggerCondition': triggerCondition,
      'visualEffect': visualEffect,
      'soundEffect': soundEffect,
    };
  }
}

enum EffectType {
  damage,
  healing,
  statBoost,
  statReduction,
  cardEffect,
  turnModifier,
  visual,
  audio,
}

class BattleEnvironmentService {
  static final List<BattleEnvironment> _environments = [
    // Forest environments
    BattleEnvironment(
      id: 'mystic_forest',
      name: 'Mystic Forest',
      description: 'An enchanted forest where ancient magic flows through the trees.',
      backgroundImage: 'assets/images/environments/mystic_forest.jpg',
      effects: [
        EnvironmentEffect(
          id: 'nature_boost',
          name: 'Nature\'s Blessing',
          description: 'Nature magic cards deal 20% more damage',
          type: EffectType.cardEffect,
          modifiers: {'nature_damage': 1.2},
          duration: -1,
          triggerCondition: 'always',
          visualEffect: 'green_glow',
          soundEffect: 'forest_ambience',
        ),
      ],
      ambientSounds: ['forest_wind', 'bird_chirps', 'rustling_leaves'],
      statModifiers: {'mana_regen': 1.1},
      specialRules: ['nature_cards_enhanced'],
      weatherCondition: 'any',
      timeOfDay: 'any',
      locationType: 'forest',
    ),
    
    // Mountain environments
    BattleEnvironment(
      id: 'stormy_peak',
      name: 'Stormy Peak',
      description: 'A treacherous mountain peak battered by fierce winds and lightning.',
      backgroundImage: 'assets/images/environments/stormy_peak.jpg',
      effects: [
        EnvironmentEffect(
          id: 'lightning_strike',
          name: 'Lightning Strike',
          description: 'Random lightning strikes deal damage to both players',
          type: EffectType.damage,
          modifiers: {'lightning_damage': 15.0},
          duration: 1,
          triggerCondition: 'turn_start',
          visualEffect: 'lightning_flash',
          soundEffect: 'thunder_crack',
        ),
      ],
      ambientSounds: ['howling_wind', 'thunder_rumble', 'rock_slide'],
      statModifiers: {'accuracy': 0.9},
      specialRules: ['lightning_strikes_random'],
      weatherCondition: 'storm',
      timeOfDay: 'any',
      locationType: 'mountain',
    ),
    
    // Water environments
    BattleEnvironment(
      id: 'crystal_lake',
      name: 'Crystal Lake',
      description: 'A serene lake with crystal-clear waters that enhance healing magic.',
      backgroundImage: 'assets/images/environments/crystal_lake.jpg',
      effects: [
        EnvironmentEffect(
          id: 'healing_waters',
          name: 'Healing Waters',
          description: 'All healing effects are enhanced by 30%',
          type: EffectType.healing,
          modifiers: {'healing_power': 1.3},
          duration: -1,
          triggerCondition: 'always',
          visualEffect: 'blue_ripple',
          soundEffect: 'water_splash',
        ),
      ],
      ambientSounds: ['water_lap', 'gentle_waves', 'distant_birds'],
      statModifiers: {'healing_received': 1.2},
      specialRules: ['healing_enhanced'],
      weatherCondition: 'any',
      timeOfDay: 'any',
      locationType: 'water',
    ),
    
    // Desert environments
    BattleEnvironment(
      id: 'scorching_dunes',
      name: 'Scorching Dunes',
      description: 'Burning hot desert sands that drain energy and enhance fire magic.',
      backgroundImage: 'assets/images/environments/scorching_dunes.jpg',
      effects: [
        EnvironmentEffect(
          id: 'heat_exhaustion',
          name: 'Heat Exhaustion',
          description: 'Players lose 5 HP per turn due to extreme heat',
          type: EffectType.damage,
          modifiers: {'heat_damage': 5.0},
          duration: -1,
          triggerCondition: 'turn_end',
          visualEffect: 'heat_waves',
          soundEffect: 'hot_wind',
        ),
        EnvironmentEffect(
          id: 'fire_enhancement',
          name: 'Fire Enhancement',
          description: 'Fire magic cards deal 25% more damage',
          type: EffectType.cardEffect,
          modifiers: {'fire_damage': 1.25},
          duration: -1,
          triggerCondition: 'always',
          visualEffect: 'fire_aura',
          soundEffect: 'fire_crackle',
        ),
      ],
      ambientSounds: ['hot_wind', 'sand_whistle', 'distant_coyote'],
      statModifiers: {'fire_resistance': 0.8, 'water_resistance': 1.2},
      specialRules: ['fire_enhanced', 'heat_damage'],
      weatherCondition: 'sunny',
      timeOfDay: 'day',
      locationType: 'desert',
    ),
    
    // Urban environments
    BattleEnvironment(
      id: 'shadowy_alley',
      name: 'Shadowy Alley',
      description: 'A dark urban alley where stealth and precision are key.',
      backgroundImage: 'assets/images/environments/shadowy_alley.jpg',
      effects: [
        EnvironmentEffect(
          id: 'stealth_advantage',
          name: 'Stealth Advantage',
          description: 'Critical hit chance increased by 15%',
          type: EffectType.statBoost,
          modifiers: {'critical_chance': 1.15},
          duration: -1,
          triggerCondition: 'always',
          visualEffect: 'shadow_veil',
          soundEffect: 'distant_traffic',
        ),
      ],
      ambientSounds: ['distant_traffic', 'footsteps', 'dripping_water'],
      statModifiers: {'stealth': 1.2, 'visibility': 0.8},
      specialRules: ['stealth_enhanced'],
      weatherCondition: 'any',
      timeOfDay: 'night',
      locationType: 'urban',
    ),
  ];

  static BattleEnvironment generateEnvironment({
    required WeatherData weather,
    required String locationType,
    required String timeOfDay,
    required Quest? quest,
  }) {
    // Filter environments based on conditions
    List<BattleEnvironment> candidates = _environments.where((env) {
      bool weatherMatch = env.weatherCondition == 'any' || 
                         env.weatherCondition == weather.condition.toLowerCase();
      bool timeMatch = env.timeOfDay == 'any' || env.timeOfDay == timeOfDay;
      bool locationMatch = env.locationType == locationType;
      
      return weatherMatch && timeMatch && locationMatch;
    }).toList();

    // If no specific match, use a generic environment
    if (candidates.isEmpty) {
      candidates = _environments.where((env) => 
        env.weatherCondition == 'any' && 
        env.timeOfDay == 'any'
      ).toList();
    }

    // Add quest-specific modifications
    BattleEnvironment baseEnv = candidates[Random().nextInt(candidates.length)];
    
    if (quest != null) {
      return _modifyEnvironmentForQuest(baseEnv, quest);
    }

    return baseEnv;
  }

  static BattleEnvironment _modifyEnvironmentForQuest(
    BattleEnvironment baseEnv, 
    Quest quest
  ) {
    List<EnvironmentEffect> modifiedEffects = List.from(baseEnv.effects);
    
    // Add quest-specific effects
    if (quest.tags.contains('boss')) {
      modifiedEffects.add(EnvironmentEffect(
        id: 'boss_aura',
        name: 'Boss Aura',
        description: 'The boss is empowered by the environment',
        type: EffectType.statBoost,
        modifiers: {'boss_damage': 1.2, 'boss_defense': 1.1},
        duration: -1,
        triggerCondition: 'always',
        visualEffect: 'dark_aura',
        soundEffect: 'boss_roar',
      ));
    }
    
    if (quest.tags.contains('time_limit')) {
      modifiedEffects.add(EnvironmentEffect(
        id: 'time_pressure',
        name: 'Time Pressure',
        description: 'Players must act quickly or face penalties',
        type: EffectType.turnModifier,
        modifiers: {'turn_time_limit': 30.0},
        duration: -1,
        triggerCondition: 'turn_start',
        visualEffect: 'clock_timer',
        soundEffect: 'ticking_clock',
      ));
    }

    return BattleEnvironment(
      id: '${baseEnv.id}_quest_${quest.id}',
      name: baseEnv.name,
      description: baseEnv.description,
      backgroundImage: baseEnv.backgroundImage,
      effects: modifiedEffects,
      ambientSounds: baseEnv.ambientSounds,
      statModifiers: baseEnv.statModifiers,
      specialRules: baseEnv.specialRules,
      weatherCondition: baseEnv.weatherCondition,
      timeOfDay: baseEnv.timeOfDay,
      locationType: baseEnv.locationType,
    );
  }

  static List<EnvironmentEffect> getActiveEffects(BattleEnvironment environment) {
    return environment.effects.where((effect) => 
      effect.duration == -1 || effect.duration > 0
    ).toList();
  }

  static Map<String, double> calculateStatModifiers(BattleEnvironment environment) {
    Map<String, double> totalModifiers = Map.from(environment.statModifiers);
    
    for (var effect in environment.effects) {
      if (effect.type == EffectType.statBoost || effect.type == EffectType.statReduction) {
        effect.modifiers.forEach((key, value) {
          totalModifiers[key] = (totalModifiers[key] ?? 1.0) * value;
        });
      }
    }
    
    return totalModifiers;
  }

  static List<String> getSpecialRules(BattleEnvironment environment) {
    return environment.specialRules;
  }

  static String getBackgroundImage(BattleEnvironment environment) {
    return environment.backgroundImage;
  }

  static List<String> getAmbientSounds(BattleEnvironment environment) {
    return environment.ambientSounds;
  }
}

// Riverpod providers
final battleEnvironmentServiceProvider = Provider<BattleEnvironmentService>((ref) {
  return BattleEnvironmentService();
});

final currentBattleEnvironmentProvider = StateProvider<BattleEnvironment?>((ref) {
  return null;
});
