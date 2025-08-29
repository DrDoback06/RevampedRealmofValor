import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/battle_models.dart';

class StatusEffect {
  final String id;
  final String name;
  final String description;
  final StatusEffectType type;
  final int duration;
  final int maxStacks;
  final int currentStacks;
  final Map<String, double> modifiers;
  final String triggerCondition;
  final String visualEffect;
  final String soundEffect;
  final bool isPositive;
  final bool canBeRemoved;
  final List<String> immunities;
  final Map<String, double> stackModifiers;

  StatusEffect({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.duration,
    required this.maxStacks,
    this.currentStacks = 1,
    required this.modifiers,
    required this.triggerCondition,
    required this.visualEffect,
    required this.soundEffect,
    required this.isPositive,
    this.canBeRemoved = true,
    this.immunities = const [],
    this.stackModifiers = const {},
  });

  factory StatusEffect.fromJson(Map<String, dynamic> json) {
    return StatusEffect(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: StatusEffectType.values.firstWhere((e) => e.name == json['type']),
      duration: json['duration'],
      maxStacks: json['maxStacks'],
      currentStacks: json['currentStacks'] ?? 1,
      modifiers: Map<String, double>.from(json['modifiers']),
      triggerCondition: json['triggerCondition'],
      visualEffect: json['visualEffect'],
      soundEffect: json['soundEffect'],
      isPositive: json['isPositive'],
      canBeRemoved: json['canBeRemoved'] ?? true,
      immunities: List<String>.from(json['immunities'] ?? []),
      stackModifiers: Map<String, double>.from(json['stackModifiers'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'duration': duration,
      'maxStacks': maxStacks,
      'currentStacks': currentStacks,
      'modifiers': modifiers,
      'triggerCondition': triggerCondition,
      'visualEffect': visualEffect,
      'soundEffect': soundEffect,
      'isPositive': isPositive,
      'canBeRemoved': canBeRemoved,
      'immunities': immunities,
      'stackModifiers': stackModifiers,
    };
  }

  StatusEffect copyWith({
    String? id,
    String? name,
    String? description,
    StatusEffectType? type,
    int? duration,
    int? maxStacks,
    int? currentStacks,
    Map<String, double>? modifiers,
    String? triggerCondition,
    String? visualEffect,
    String? soundEffect,
    bool? isPositive,
    bool? canBeRemoved,
    List<String>? immunities,
    Map<String, double>? stackModifiers,
  }) {
    return StatusEffect(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      maxStacks: maxStacks ?? this.maxStacks,
      currentStacks: currentStacks ?? this.currentStacks,
      modifiers: modifiers ?? this.modifiers,
      triggerCondition: triggerCondition ?? this.triggerCondition,
      visualEffect: visualEffect ?? this.visualEffect,
      soundEffect: soundEffect ?? this.soundEffect,
      isPositive: isPositive ?? this.isPositive,
      canBeRemoved: canBeRemoved ?? this.canBeRemoved,
      immunities: immunities ?? this.immunities,
      stackModifiers: stackModifiers ?? this.stackModifiers,
    );
  }

  Map<String, double> getEffectiveModifiers() {
    Map<String, double> effective = Map.from(modifiers);
    
    // Apply stack modifiers
    if (currentStacks > 1 && stackModifiers.isNotEmpty) {
      stackModifiers.forEach((key, value) {
        if (effective.containsKey(key)) {
          effective[key] = effective[key]! * (1 + (value * (currentStacks - 1)));
        }
      });
    }
    
    return effective;
  }

  bool canStack() {
    return currentStacks < maxStacks;
  }

  StatusEffect addStack() {
    if (canStack()) {
      return copyWith(currentStacks: currentStacks + 1);
    }
    return this;
  }
}

enum StatusEffectType {
  damage,
  healing,
  statBoost,
  statReduction,
  dot, // Damage over time
  hot, // Healing over time
  stun,
  silence,
  taunt,
  stealth,
  reflect,
  absorb,
  counter,
  transform,
  summon,
}

class StatusEffectManager {
  final Map<String, StatusEffect> activeEffects = {};
  final List<StatusEffectInteraction> interactions = [];

  void addEffect(StatusEffect effect) {
    if (activeEffects.containsKey(effect.id)) {
      // Stack existing effect
      StatusEffect existing = activeEffects[effect.id]!;
      if (existing.canStack()) {
        activeEffects[effect.id] = existing.addStack();
      } else {
        // Refresh duration
        activeEffects[effect.id] = effect.copyWith(currentStacks: existing.currentStacks);
      }
    } else {
      activeEffects[effect.id] = effect;
    }

    // Check for interactions
    _checkInteractions(effect);
  }

  void removeEffect(String effectId) {
    activeEffects.remove(effectId);
  }

  void updateEffects() {
    List<String> toRemove = [];
    
    activeEffects.forEach((id, effect) {
      if (effect.duration > 0) {
        activeEffects[id] = effect.copyWith(duration: effect.duration - 1);
        if (effect.duration <= 1) {
          toRemove.add(id);
        }
      }
    });

    toRemove.forEach(removeEffect);
  }

  Map<String, double> getTotalModifiers() {
    Map<String, double> total = {};
    
    activeEffects.values.forEach((effect) {
      Map<String, double> effectMods = effect.getEffectiveModifiers();
      effectMods.forEach((key, value) {
        total[key] = (total[key] ?? 1.0) * value;
      });
    });
    
    return total;
  }

  List<StatusEffect> getEffectsByType(StatusEffectType type) {
    return activeEffects.values.where((effect) => effect.type == type).toList();
  }

  bool hasEffect(String effectId) {
    return activeEffects.containsKey(effectId);
  }

  bool isImmuneTo(String effectType) {
    return activeEffects.values.any((effect) => 
      effect.immunities.contains(effectType)
    );
  }

  void _checkInteractions(StatusEffect newEffect) {
    activeEffects.values.forEach((existingEffect) {
      StatusEffectInteraction? interaction = _findInteraction(newEffect, existingEffect);
      if (interaction != null) {
        interactions.add(interaction);
        _applyInteraction(interaction);
      }
    });
  }

  StatusEffectInteraction? _findInteraction(StatusEffect effect1, StatusEffect effect2) {
    // Define interaction rules
    if (effect1.type == StatusEffectType.stun && effect2.type == StatusEffectType.silence) {
      return StatusEffectInteraction(
        type: InteractionType.enhance,
        description: 'Stunned and silenced targets take 50% more damage',
        modifiers: {'damage_taken': 1.5},
      );
    }
    
    if (effect1.type == StatusEffectType.stealth && effect2.type == StatusEffectType.taunt) {
      return StatusEffectInteraction(
        type: InteractionType.cancel,
        description: 'Stealth cancels taunt effect',
        targetEffect: effect2.id,
      );
    }
    
    if (effect1.type == StatusEffectType.reflect && effect2.type == StatusEffectType.absorb) {
      return StatusEffectInteraction(
        type: InteractionType.combine,
        description: 'Reflect and absorb combine for 100% damage reflection',
        modifiers: {'damage_reflection': 1.0},
      );
    }
    
    return null;
  }

  void _applyInteraction(StatusEffectInteraction interaction) {
    switch (interaction.type) {
      case InteractionType.enhance:
        // Apply enhancement modifiers
        break;
      case InteractionType.cancel:
        if (interaction.targetEffect != null) {
          removeEffect(interaction.targetEffect!);
        }
        break;
      case InteractionType.combine:
        // Apply combination effects
        break;
      case InteractionType.transform:
        // Apply transformation effects
        break;
    }
  }
}

class StatusEffectInteraction {
  final InteractionType type;
  final String description;
  final Map<String, double>? modifiers;
  final String? targetEffect;

  StatusEffectInteraction({
    required this.type,
    required this.description,
    this.modifiers,
    this.targetEffect,
  });
}

enum InteractionType {
  enhance,
  cancel,
  combine,
  transform,
}

class StatusEffectService {
  static final Map<String, StatusEffect> _effectTemplates = {
    // Damage effects
    'burn': StatusEffect(
      id: 'burn',
      name: 'Burn',
      description: 'Takes fire damage over time',
      type: StatusEffectType.dot,
      duration: 3,
      maxStacks: 5,
      modifiers: {'fire_damage_per_turn': 10.0},
      triggerCondition: 'turn_end',
      visualEffect: 'fire_particles',
      soundEffect: 'burning',
      isPositive: false,
    ),
    
    'poison': StatusEffect(
      id: 'poison',
      name: 'Poison',
      description: 'Takes poison damage over time',
      type: StatusEffectType.dot,
      duration: 5,
      maxStacks: 3,
      modifiers: {'poison_damage_per_turn': 8.0},
      triggerCondition: 'turn_end',
      visualEffect: 'green_mist',
      soundEffect: 'hissing',
      isPositive: false,
      stackModifiers: {'poison_damage_per_turn': 0.5}, // 50% increase per stack
    ),
    
    // Healing effects
    'regeneration': StatusEffect(
      id: 'regeneration',
      name: 'Regeneration',
      description: 'Heals over time',
      type: StatusEffectType.hot,
      duration: 4,
      maxStacks: 3,
      modifiers: {'healing_per_turn': 15.0},
      triggerCondition: 'turn_end',
      visualEffect: 'green_glow',
      soundEffect: 'healing_chime',
      isPositive: true,
    ),
    
    // Stat effects
    'strength_boost': StatusEffect(
      id: 'strength_boost',
      name: 'Strength Boost',
      description: 'Increases attack power',
      type: StatusEffectType.statBoost,
      duration: 3,
      maxStacks: 3,
      modifiers: {'attack_power': 1.2},
      triggerCondition: 'always',
      visualEffect: 'red_aura',
      soundEffect: 'power_up',
      isPositive: true,
    ),
    
    'weakness': StatusEffect(
      id: 'weakness',
      name: 'Weakness',
      description: 'Reduces attack power',
      type: StatusEffectType.statReduction,
      duration: 3,
      maxStacks: 3,
      modifiers: {'attack_power': 0.8},
      triggerCondition: 'always',
      visualEffect: 'gray_aura',
      soundEffect: 'power_down',
      isPositive: false,
    ),
    
    // Control effects
    'stun': StatusEffect(
      id: 'stun',
      name: 'Stun',
      description: 'Cannot take actions',
      type: StatusEffectType.stun,
      duration: 1,
      maxStacks: 1,
      modifiers: {'can_act': 0.0},
      triggerCondition: 'turn_start',
      visualEffect: 'stars',
      soundEffect: 'stun',
      isPositive: false,
      canBeRemoved: false,
    ),
    
    'silence': StatusEffect(
      id: 'silence',
      name: 'Silence',
      description: 'Cannot use special abilities',
      type: StatusEffectType.silence,
      duration: 2,
      maxStacks: 1,
      modifiers: {'can_use_special': 0.0},
      triggerCondition: 'always',
      visualEffect: 'mute_icon',
      soundEffect: 'silence',
      isPositive: false,
    ),
    
    // Defensive effects
    'shield': StatusEffect(
      id: 'shield',
      name: 'Shield',
      description: 'Absorbs incoming damage',
      type: StatusEffectType.absorb,
      duration: 2,
      maxStacks: 3,
      modifiers: {'damage_absorption': 25.0},
      triggerCondition: 'damage_taken',
      visualEffect: 'blue_shield',
      soundEffect: 'shield_up',
      isPositive: true,
    ),
    
    'reflect': StatusEffect(
      id: 'reflect',
      name: 'Reflect',
      description: 'Reflects damage back to attacker',
      type: StatusEffectType.reflect,
      duration: 2,
      maxStacks: 2,
      modifiers: {'damage_reflection': 0.3},
      triggerCondition: 'damage_taken',
      visualEffect: 'mirror_effect',
      soundEffect: 'reflect',
      isPositive: true,
    ),
    
    // Special effects
    'stealth': StatusEffect(
      id: 'stealth',
      name: 'Stealth',
      description: 'Cannot be targeted by attacks',
      type: StatusEffectType.stealth,
      duration: 2,
      maxStacks: 1,
      modifiers: {'untargetable': 1.0},
      triggerCondition: 'always',
      visualEffect: 'invisibility',
      soundEffect: 'stealth',
      isPositive: true,
    ),
    
    'taunt': StatusEffect(
      id: 'taunt',
      name: 'Taunt',
      description: 'Forces enemies to target this unit',
      type: StatusEffectType.taunt,
      duration: 2,
      maxStacks: 1,
      modifiers: {'taunt': 1.0},
      triggerCondition: 'always',
      visualEffect: 'taunt_icon',
      soundEffect: 'taunt',
      isPositive: false,
    ),
  };

  static StatusEffect? getEffectTemplate(String effectId) {
    return _effectTemplates[effectId];
  }

  static List<StatusEffect> getAllEffectTemplates() {
    return _effectTemplates.values.toList();
  }

  static StatusEffect createEffect(String effectId, {int? customDuration}) {
    StatusEffect? template = getEffectTemplate(effectId);
    if (template == null) {
      throw Exception('Unknown effect template: $effectId');
    }
    
    if (customDuration != null) {
      return template.copyWith(duration: customDuration);
    }
    
    return template;
  }

  static List<StatusEffect> getEffectsByCategory(StatusEffectType type) {
    return _effectTemplates.values.where((effect) => effect.type == type).toList();
  }

  static List<StatusEffect> getPositiveEffects() {
    return _effectTemplates.values.where((effect) => effect.isPositive).toList();
  }

  static List<StatusEffect> getNegativeEffects() {
    return _effectTemplates.values.where((effect) => !effect.isPositive).toList();
  }
}

// Riverpod providers
final statusEffectServiceProvider = Provider<StatusEffectService>((ref) {
  return StatusEffectService();
});

final statusEffectManagerProvider = StateProvider<StatusEffectManager>((ref) {
  return StatusEffectManager();
});
