import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum CosmeticType {
  skin,
  hair,
  eyes,
  outfit,
  weapon,
  mount,
  pet,
  effect,
  emote,
  title,
}

enum CosmeticRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

enum CosmeticCategory {
  character,
  equipment,
  companion,
  effect,
  social,
}

class CosmeticItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final CosmeticType type;
  final CosmeticCategory category;
  final CosmeticRarity rarity;
  final String icon;
  final String? previewImage;
  final Color primaryColor;
  final Color secondaryColor;
  final Map<String, dynamic> properties;
  final List<String> tags;
  final bool isEquippable;
  final bool isTradeable;
  final bool isLimited;
  final DateTime? releaseDate;
  final DateTime? expiryDate;
  final String? lore;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.rarity,
    required this.icon,
    this.previewImage,
    required this.primaryColor,
    required this.secondaryColor,
    required this.properties,
    required this.tags,
    this.isEquippable = true,
    this.isTradeable = true,
    this.isLimited = false,
    this.releaseDate,
    this.expiryDate,
    this.lore,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    category,
    rarity,
    icon,
    previewImage,
    primaryColor,
    secondaryColor,
    properties,
    tags,
    isEquippable,
    isTradeable,
    isLimited,
    releaseDate,
    expiryDate,
    lore,
  ];
}

class CharacterAppearance extends Equatable {
  final String characterId;
  final Map<CosmeticType, String> equippedCosmetics;
  final Map<String, dynamic> customizations;
  final Color skinTone;
  final Color hairColor;
  final Color eyeColor;
  final double height;
  final double weight;
  final Map<String, dynamic> facialFeatures;
  final Map<String, dynamic> bodyFeatures;
  final DateTime lastModified;

  const CharacterAppearance({
    required this.characterId,
    required this.equippedCosmetics,
    required this.customizations,
    required this.skinTone,
    required this.hairColor,
    required this.eyeColor,
    required this.height,
    required this.weight,
    required this.facialFeatures,
    required this.bodyFeatures,
    required this.lastModified,
  });

  @override
  List<Object?> get props => [
    characterId,
    equippedCosmetics,
    customizations,
    skinTone,
    hairColor,
    eyeColor,
    height,
    weight,
    facialFeatures,
    bodyFeatures,
    lastModified,
  ];
}

class CosmeticCollection extends Equatable {
  final String characterId;
  final List<String> ownedCosmetics;
  final List<String> equippedCosmetics;
  final Map<String, DateTime> acquisitionDates;
  final Map<String, int> usageCount;
  final List<String> favorites;
  final Map<String, dynamic> preferences;

  const CosmeticCollection({
    required this.characterId,
    required this.ownedCosmetics,
    required this.equippedCosmetics,
    required this.acquisitionDates,
    required this.usageCount,
    required this.favorites,
    required this.preferences,
  });

  @override
  List<Object?> get props => [
    characterId,
    ownedCosmetics,
    equippedCosmetics,
    acquisitionDates,
    usageCount,
    favorites,
    preferences,
  ];
}

class CharacterCustomizationService {
  static final Map<String, CosmeticItem> _cosmetics = {
    // Skin Tones
    'skin_pale': CosmeticItem(
      id: 'skin_pale',
      name: 'Pale Skin',
      description: 'A light, pale skin tone',
      type: CosmeticType.skin,
      category: CosmeticCategory.character,
      rarity: CosmeticRarity.common,
      icon: '👤',
      primaryColor: const Color(0xFFF5D0C5),
      secondaryColor: const Color(0xFFE8C4B8),
      properties: {'skin_tone': 'pale'},
      tags: ['skin', 'pale', 'light'],
    ),
    
    'skin_tan': CosmeticItem(
      id: 'skin_tan',
      name: 'Tan Skin',
      description: 'A warm, tan skin tone',
      type: CosmeticType.skin,
      category: CosmeticCategory.character,
      rarity: CosmeticRarity.common,
      icon: '👤',
      primaryColor: const Color(0xFFD2B48C),
      secondaryColor: const Color(0xFFC19A6B),
      properties: {'skin_tone': 'tan'},
      tags: ['skin', 'tan', 'warm'],
    ),
    
    'skin_dark': CosmeticItem(
      id: 'skin_dark',
      name: 'Dark Skin',
      description: 'A rich, dark skin tone',
      type: CosmeticType.skin,
      category: CosmeticCategory.character,
      rarity: CosmeticRarity.common,
      icon: '👤',
      primaryColor: const Color(0xFF8B4513),
      secondaryColor: const Color(0xFF654321),
      properties: {'skin_tone': 'dark'},
      tags: ['skin', 'dark', 'rich'],
    ),

    // Hair Styles
    'hair_short': CosmeticItem(
      id: 'hair_short',
      name: 'Short Hair',
      description: 'A practical short haircut',
      type: CosmeticType.hair,
      category: CosmeticCategory.character,
      rarity: CosmeticRarity.common,
      icon: '💇‍♂️',
      primaryColor: const Color(0xFF8B4513),
      secondaryColor: const Color(0xFF654321),
      properties: {'hair_style': 'short', 'length': 'short'},
      tags: ['hair', 'short', 'practical'],
    ),
    
    'hair_long': CosmeticItem(
      id: 'hair_long',
      name: 'Long Hair',
      description: 'Flowing long hair',
      type: CosmeticType.hair,
      category: CosmeticCategory.character,
      rarity: CosmeticRarity.uncommon,
      icon: '💇‍♀️',
      primaryColor: const Color(0xFF8B4513),
      secondaryColor: const Color(0xFF654321),
      properties: {'hair_style': 'long', 'length': 'long'},
      tags: ['hair', 'long', 'flowing'],
    ),
    
    'hair_spiky': CosmeticItem(
      id: 'hair_spiky',
      name: 'Spiky Hair',
      description: 'Wild spiky hair',
      type: CosmeticType.hair,
      category: CosmeticCategory.character,
      rarity: CosmeticRarity.rare,
      icon: '💇‍♂️',
      primaryColor: const Color(0xFF8B4513),
      secondaryColor: const Color(0xFF654321),
      properties: {'hair_style': 'spiky', 'length': 'medium'},
      tags: ['hair', 'spiky', 'wild'],
    ),

    // Eye Colors
    'eyes_blue': CosmeticItem(
      id: 'eyes_blue',
      name: 'Blue Eyes',
      description: 'Bright blue eyes',
      type: CosmeticType.eyes,
      category: CosmeticCategory.character,
      rarity: CosmeticRarity.common,
      icon: '👁️',
      primaryColor: const Color(0xFF1E90FF),
      secondaryColor: const Color(0xFF4169E1),
      properties: {'eye_color': 'blue'},
      tags: ['eyes', 'blue', 'bright'],
    ),
    
    'eyes_green': CosmeticItem(
      id: 'eyes_green',
      name: 'Green Eyes',
      description: 'Emerald green eyes',
      type: CosmeticType.eyes,
      category: CosmeticCategory.character,
      rarity: CosmeticRarity.uncommon,
      icon: '👁️',
      primaryColor: const Color(0xFF32CD32),
      secondaryColor: const Color(0xFF228B22),
      properties: {'eye_color': 'green'},
      tags: ['eyes', 'green', 'emerald'],
    ),
    
    'eyes_golden': CosmeticItem(
      id: 'eyes_golden',
      name: 'Golden Eyes',
      description: 'Mystical golden eyes',
      type: CosmeticType.eyes,
      category: CosmeticCategory.character,
      rarity: CosmeticRarity.epic,
      icon: '👁️',
      primaryColor: const Color(0xFFFFD700),
      secondaryColor: const Color(0xFFFFA500),
      properties: {'eye_color': 'golden', 'mystical': true},
      tags: ['eyes', 'golden', 'mystical'],
    ),

    // Outfits
    'outfit_adventurer': CosmeticItem(
      id: 'outfit_adventurer',
      name: 'Adventurer\'s Garb',
      description: 'Practical clothing for adventurers',
      type: CosmeticType.outfit,
      category: CosmeticCategory.equipment,
      rarity: CosmeticRarity.common,
      icon: '👕',
      primaryColor: const Color(0xFF8B4513),
      secondaryColor: const Color(0xFF654321),
      properties: {'outfit_type': 'adventurer', 'durability': 100},
      tags: ['outfit', 'adventurer', 'practical'],
    ),
    
    'outfit_mage': CosmeticItem(
      id: 'outfit_mage',
      name: 'Mage Robes',
      description: 'Elegant robes for spellcasters',
      type: CosmeticType.outfit,
      category: CosmeticCategory.equipment,
      rarity: CosmeticRarity.uncommon,
      icon: '👕',
      primaryColor: const Color(0xFF4B0082),
      secondaryColor: const Color(0xFF800080),
      properties: {'outfit_type': 'mage', 'magic_affinity': 0.1},
      tags: ['outfit', 'mage', 'elegant'],
    ),
    
    'outfit_royal': CosmeticItem(
      id: 'outfit_royal',
      name: 'Royal Attire',
      description: 'Luxurious royal clothing',
      type: CosmeticType.outfit,
      category: CosmeticCategory.equipment,
      rarity: CosmeticRarity.legendary,
      icon: '👕',
      primaryColor: const Color(0xFFFFD700),
      secondaryColor: const Color(0xFFFFA500),
      properties: {'outfit_type': 'royal', 'charisma_bonus': 0.2},
      tags: ['outfit', 'royal', 'luxurious'],
    ),

    // Weapons
    'weapon_sword_basic': CosmeticItem(
      id: 'weapon_sword_basic',
      name: 'Basic Sword',
      description: 'A simple but reliable sword',
      type: CosmeticType.weapon,
      category: CosmeticCategory.equipment,
      rarity: CosmeticRarity.common,
      icon: '⚔️',
      primaryColor: const Color(0xFFC0C0C0),
      secondaryColor: const Color(0xFF808080),
      properties: {'weapon_type': 'sword', 'damage': 10},
      tags: ['weapon', 'sword', 'basic'],
    ),
    
    'weapon_staff_magic': CosmeticItem(
      id: 'weapon_staff_magic',
      name: 'Magic Staff',
      description: 'A staff imbued with magical power',
      type: CosmeticType.weapon,
      category: CosmeticCategory.equipment,
      rarity: CosmeticRarity.rare,
      icon: '🪄',
      primaryColor: const Color(0xFF4B0082),
      secondaryColor: const Color(0xFF800080),
      properties: {'weapon_type': 'staff', 'magic_power': 0.3},
      tags: ['weapon', 'staff', 'magic'],
    ),
    
    'weapon_sword_legendary': CosmeticItem(
      id: 'weapon_sword_legendary',
      name: 'Legendary Blade',
      description: 'A sword of legendary power',
      type: CosmeticType.weapon,
      category: CosmeticCategory.equipment,
      rarity: CosmeticRarity.legendary,
      icon: '⚔️',
      primaryColor: const Color(0xFFFFD700),
      secondaryColor: const Color(0xFFFFA500),
      properties: {'weapon_type': 'sword', 'damage': 50, 'legendary': true},
      tags: ['weapon', 'sword', 'legendary'],
    ),

    // Mounts
    'mount_horse': CosmeticItem(
      id: 'mount_horse',
      name: 'Trusty Steed',
      description: 'A reliable horse mount',
      type: CosmeticType.mount,
      category: CosmeticCategory.companion,
      rarity: CosmeticRarity.common,
      icon: '🐎',
      primaryColor: const Color(0xFF8B4513),
      secondaryColor: const Color(0xFF654321),
      properties: {'mount_type': 'horse', 'speed': 1.2},
      tags: ['mount', 'horse', 'reliable'],
    ),
    
    'mount_griffin': CosmeticItem(
      id: 'mount_griffin',
      name: 'Noble Griffin',
      description: 'A majestic flying mount',
      type: CosmeticType.mount,
      category: CosmeticCategory.companion,
      rarity: CosmeticRarity.epic,
      icon: '🦅',
      primaryColor: const Color(0xFFD2B48C),
      secondaryColor: const Color(0xFFC19A6B),
      properties: {'mount_type': 'griffin', 'speed': 2.0, 'flying': true},
      tags: ['mount', 'griffin', 'flying'],
    ),

    // Pets
    'pet_cat': CosmeticItem(
      id: 'pet_cat',
      name: 'Loyal Cat',
      description: 'A faithful feline companion',
      type: CosmeticType.pet,
      category: CosmeticCategory.companion,
      rarity: CosmeticRarity.common,
      icon: '🐱',
      primaryColor: const Color(0xFFD2B48C),
      secondaryColor: const Color(0xFFC19A6B),
      properties: {'pet_type': 'cat', 'loyalty': 0.8},
      tags: ['pet', 'cat', 'loyal'],
    ),
    
    'pet_dragon': CosmeticItem(
      id: 'pet_dragon',
      name: 'Baby Dragon',
      description: 'A young dragon companion',
      type: CosmeticType.pet,
      category: CosmeticCategory.companion,
      rarity: CosmeticRarity.mythic,
      icon: '🐉',
      primaryColor: const Color(0xFFFF4500),
      secondaryColor: const Color(0xFFDC143C),
      properties: {'pet_type': 'dragon', 'power': 0.9, 'rare': true},
      tags: ['pet', 'dragon', 'powerful'],
    ),

    // Effects
    'effect_fire_aura': CosmeticItem(
      id: 'effect_fire_aura',
      name: 'Fire Aura',
      description: 'A blazing fire effect around your character',
      type: CosmeticType.effect,
      category: CosmeticCategory.effect,
      rarity: CosmeticRarity.rare,
      icon: '🔥',
      primaryColor: const Color(0xFFFF4500),
      secondaryColor: const Color(0xFFFF6347),
      properties: {'effect_type': 'aura', 'element': 'fire'},
      tags: ['effect', 'fire', 'aura'],
    ),
    
    'effect_ice_trail': CosmeticItem(
      id: 'effect_ice_trail',
      name: 'Ice Trail',
      description: 'Leave a trail of ice crystals as you walk',
      type: CosmeticType.effect,
      category: CosmeticCategory.effect,
      rarity: CosmeticRarity.epic,
      icon: '❄️',
      primaryColor: const Color(0xFF87CEEB),
      secondaryColor: const Color(0xFFB0E0E6),
      properties: {'effect_type': 'trail', 'element': 'ice'},
      tags: ['effect', 'ice', 'trail'],
    ),

    // Emotes
    'emote_wave': CosmeticItem(
      id: 'emote_wave',
      name: 'Wave',
      description: 'A friendly wave emote',
      type: CosmeticType.emote,
      category: CosmeticCategory.social,
      rarity: CosmeticRarity.common,
      icon: '👋',
      primaryColor: const Color(0xFFFFFFFF),
      secondaryColor: const Color(0xFFF0F0F0),
      properties: {'emote_type': 'wave', 'duration': 3},
      tags: ['emote', 'wave', 'friendly'],
    ),
    
    'emote_dance': CosmeticItem(
      id: 'emote_dance',
      name: 'Dance',
      description: 'A joyful dance emote',
      type: CosmeticType.emote,
      category: CosmeticCategory.social,
      rarity: CosmeticRarity.uncommon,
      icon: '💃',
      primaryColor: const Color(0xFFFFFFFF),
      secondaryColor: const Color(0xFFF0F0F0),
      properties: {'emote_type': 'dance', 'duration': 5},
      tags: ['emote', 'dance', 'joyful'],
    ),
  };

  static CosmeticItem getCosmetic(String id) {
    return _cosmetics[id] ?? _cosmetics['skin_pale']!;
  }

  static List<CosmeticItem> getCosmeticsByType(CosmeticType type) {
    return _cosmetics.values.where((c) => c.type == type).toList();
  }

  static List<CosmeticItem> getCosmeticsByCategory(CosmeticCategory category) {
    return _cosmetics.values.where((c) => c.category == category).toList();
  }

  static List<CosmeticItem> getCosmeticsByRarity(CosmeticRarity rarity) {
    return _cosmetics.values.where((c) => c.rarity == rarity).toList();
  }

  static List<CosmeticItem> getAllCosmetics() {
    return _cosmetics.values.toList();
  }

  static CharacterAppearance createDefaultAppearance(String characterId) {
    return CharacterAppearance(
      characterId: characterId,
      equippedCosmetics: {
        CosmeticType.skin: 'skin_pale',
        CosmeticType.hair: 'hair_short',
        CosmeticType.eyes: 'eyes_blue',
        CosmeticType.outfit: 'outfit_adventurer',
        CosmeticType.weapon: 'weapon_sword_basic',
      },
      customizations: {
        'height': 1.7,
        'weight': 70.0,
        'facial_hair': false,
        'scars': false,
        'tattoos': false,
      },
      skinTone: const Color(0xFFF5D0C5),
      hairColor: const Color(0xFF8B4513),
      eyeColor: const Color(0xFF1E90FF),
      height: 1.7,
      weight: 70.0,
      facialFeatures: {
        'nose_type': 'normal',
        'eye_shape': 'normal',
        'lip_shape': 'normal',
        'cheekbones': 'normal',
      },
      bodyFeatures: {
        'muscle_definition': 'normal',
        'body_type': 'average',
        'posture': 'normal',
      },
      lastModified: DateTime.now(),
    );
  }

  static CharacterAppearance equipCosmetic(CharacterAppearance appearance, CosmeticItem cosmetic) {
    final updatedCosmetics = Map<CosmeticType, String>.from(appearance.equippedCosmetics);
    updatedCosmetics[cosmetic.type] = cosmetic.id;
    
    return CharacterAppearance(
      characterId: appearance.characterId,
      equippedCosmetics: updatedCosmetics,
      customizations: appearance.customizations,
      skinTone: cosmetic.type == CosmeticType.skin ? cosmetic.primaryColor : appearance.skinTone,
      hairColor: cosmetic.type == CosmeticType.hair ? cosmetic.primaryColor : appearance.hairColor,
      eyeColor: cosmetic.type == CosmeticType.eyes ? cosmetic.primaryColor : appearance.eyeColor,
      height: appearance.height,
      weight: appearance.weight,
      facialFeatures: appearance.facialFeatures,
      bodyFeatures: appearance.bodyFeatures,
      lastModified: DateTime.now(),
    );
  }

  static CharacterAppearance unequipCosmetic(CharacterAppearance appearance, CosmeticType type) {
    final updatedCosmetics = Map<CosmeticType, String>.from(appearance.equippedCosmetics);
    updatedCosmetics.remove(type);
    
    return CharacterAppearance(
      characterId: appearance.characterId,
      equippedCosmetics: updatedCosmetics,
      customizations: appearance.customizations,
      skinTone: appearance.skinTone,
      hairColor: appearance.hairColor,
      eyeColor: appearance.eyeColor,
      height: appearance.height,
      weight: appearance.weight,
      facialFeatures: appearance.facialFeatures,
      bodyFeatures: appearance.bodyFeatures,
      lastModified: DateTime.now(),
    );
  }

  static CharacterAppearance updateCustomization(CharacterAppearance appearance, Map<String, dynamic> customizations) {
    final updatedCustomizations = Map<String, dynamic>.from(appearance.customizations);
    updatedCustomizations.addAll(customizations);
    
    return CharacterAppearance(
      characterId: appearance.characterId,
      equippedCosmetics: appearance.equippedCosmetics,
      customizations: updatedCustomizations,
      skinTone: appearance.skinTone,
      hairColor: appearance.hairColor,
      eyeColor: appearance.eyeColor,
      height: appearance.height,
      weight: appearance.weight,
      facialFeatures: appearance.facialFeatures,
      bodyFeatures: appearance.bodyFeatures,
      lastModified: DateTime.now(),
    );
  }

  static CosmeticCollection createDefaultCollection(String characterId) {
    return CosmeticCollection(
      characterId: characterId,
      ownedCosmetics: [
        'skin_pale',
        'hair_short',
        'eyes_blue',
        'outfit_adventurer',
        'weapon_sword_basic',
      ],
      equippedCosmetics: [
        'skin_pale',
        'hair_short',
        'eyes_blue',
        'outfit_adventurer',
        'weapon_sword_basic',
      ],
      acquisitionDates: {
        'skin_pale': DateTime.now(),
        'hair_short': DateTime.now(),
        'eyes_blue': DateTime.now(),
        'outfit_adventurer': DateTime.now(),
        'weapon_sword_basic': DateTime.now(),
      },
      usageCount: {
        'skin_pale': 1,
        'hair_short': 1,
        'eyes_blue': 1,
        'outfit_adventurer': 1,
        'weapon_sword_basic': 1,
      },
      favorites: [],
      preferences: {
        'show_effects': true,
        'show_mounts': true,
        'show_pets': true,
        'auto_equip_new': false,
      },
    );
  }

  static CosmeticCollection addCosmetic(CosmeticCollection collection, String cosmeticId) {
    final updatedOwned = List<String>.from(collection.ownedCosmetics);
    if (!updatedOwned.contains(cosmeticId)) {
      updatedOwned.add(cosmeticId);
    }
    
    final updatedAcquisitionDates = Map<String, DateTime>.from(collection.acquisitionDates);
    if (!updatedAcquisitionDates.containsKey(cosmeticId)) {
      updatedAcquisitionDates[cosmeticId] = DateTime.now();
    }
    
    final updatedUsageCount = Map<String, int>.from(collection.usageCount);
    if (!updatedUsageCount.containsKey(cosmeticId)) {
      updatedUsageCount[cosmeticId] = 0;
    }
    
    return CosmeticCollection(
      characterId: collection.characterId,
      ownedCosmetics: updatedOwned,
      equippedCosmetics: collection.equippedCosmetics,
      acquisitionDates: updatedAcquisitionDates,
      usageCount: updatedUsageCount,
      favorites: collection.favorites,
      preferences: collection.preferences,
    );
  }

  static CosmeticCollection useCosmetic(CosmeticCollection collection, String cosmeticId) {
    final updatedUsageCount = Map<String, int>.from(collection.usageCount);
    updatedUsageCount[cosmeticId] = (updatedUsageCount[cosmeticId] ?? 0) + 1;
    
    return CosmeticCollection(
      characterId: collection.characterId,
      ownedCosmetics: collection.ownedCosmetics,
      equippedCosmetics: collection.equippedCosmetics,
      acquisitionDates: collection.acquisitionDates,
      usageCount: updatedUsageCount,
      favorites: collection.favorites,
      preferences: collection.preferences,
    );
  }

  static CosmeticCollection toggleFavorite(CosmeticCollection collection, String cosmeticId) {
    final updatedFavorites = List<String>.from(collection.favorites);
    if (updatedFavorites.contains(cosmeticId)) {
      updatedFavorites.remove(cosmeticId);
    } else {
      updatedFavorites.add(cosmeticId);
    }
    
    return CosmeticCollection(
      characterId: collection.characterId,
      ownedCosmetics: collection.ownedCosmetics,
      equippedCosmetics: collection.equippedCosmetics,
      acquisitionDates: collection.acquisitionDates,
      usageCount: collection.usageCount,
      favorites: updatedFavorites,
      preferences: collection.preferences,
    );
  }

  static List<CosmeticItem> getRecommendations(CosmeticCollection collection, List<String> recentActivity) {
    final recommendations = <CosmeticItem>[];
    final ownedIds = collection.ownedCosmetics.toSet();
    
    // Recommend cosmetics based on rarity progression
    for (final cosmetic in _cosmetics.values) {
      if (!ownedIds.contains(cosmetic.id)) {
        if (cosmetic.rarity == CosmeticRarity.uncommon && 
            collection.ownedCosmetics.where((id) => 
              _cosmetics[id]?.rarity == CosmeticRarity.common
            ).length >= 5) {
          recommendations.add(cosmetic);
        } else if (cosmetic.rarity == CosmeticRarity.rare && 
                   collection.ownedCosmetics.where((id) => 
                     _cosmetics[id]?.rarity == CosmeticRarity.uncommon
                   ).length >= 3) {
          recommendations.add(cosmetic);
        }
      }
    }
    
    // Recommend based on activity
    if (recentActivity.contains('battle')) {
      final battleCosmetics = _cosmetics.values.where((c) => 
        c.tags.contains('battle') || c.tags.contains('warrior')
      ).toList();
      recommendations.addAll(battleCosmetics.where((c) => !ownedIds.contains(c.id)));
    }
    
    if (recentActivity.contains('magic')) {
      final magicCosmetics = _cosmetics.values.where((c) => 
        c.tags.contains('magic') || c.tags.contains('mage')
      ).toList();
      recommendations.addAll(magicCosmetics.where((c) => !ownedIds.contains(c.id)));
    }
    
    return recommendations.take(10).toList();
  }

  static Map<String, dynamic> getCollectionStats(CosmeticCollection collection) {
    final stats = <String, dynamic>{};
    
    stats['total_owned'] = collection.ownedCosmetics.length;
    stats['total_available'] = _cosmetics.length;
    stats['completion_percentage'] = (collection.ownedCosmetics.length / _cosmetics.length) * 100;
    
    // Rarity breakdown
    final rarityCounts = <CosmeticRarity, int>{};
    for (final cosmeticId in collection.ownedCosmetics) {
      final cosmetic = _cosmetics[cosmeticId];
      if (cosmetic != null) {
        rarityCounts[cosmetic.rarity] = (rarityCounts[cosmetic.rarity] ?? 0) + 1;
      }
    }
    stats['rarity_breakdown'] = rarityCounts;
    
    // Most used cosmetics
    final sortedUsage = collection.usageCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    stats['most_used'] = sortedUsage.take(5).map((e) => {
      'id': e.key,
      'name': _cosmetics[e.key]?.name ?? 'Unknown',
      'uses': e.value,
    }).toList();
    
    // Recent acquisitions
    final sortedAcquisitions = collection.acquisitionDates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    stats['recent_acquisitions'] = sortedAcquisitions.take(5).map((e) => {
      'id': e.key,
      'name': _cosmetics[e.key]?.name ?? 'Unknown',
      'date': e.value.toIso8601String(),
    }).toList();
    
    return stats;
  }
}
