import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'character_classes.dart';
import 'character_achievements.dart';

enum CharacterSlotStatus {
  empty,
  occupied,
  locked,
  premium,
}

enum CharacterTransferType {
  equipment,
  items,
  currency,
  experience,
  skills,
  achievements,
}

class CharacterSlot extends Equatable {
  final String id;
  final String? characterId;
  final CharacterSlotStatus status;
  final bool isPremium;
  final DateTime? unlockDate;
  final DateTime? lastUsedDate;
  final Map<String, dynamic> slotBonuses;

  const CharacterSlot({
    required this.id,
    this.characterId,
    required this.status,
    this.isPremium = false,
    this.unlockDate,
    this.lastUsedDate,
    this.slotBonuses = const {},
  });

  @override
  List<Object?> get props => [
    id,
    characterId,
    status,
    isPremium,
    unlockDate,
    lastUsedDate,
    slotBonuses,
  ];
}

class CharacterProfile extends Equatable {
  final String id;
  final String name;
  final String description;
  final CharacterClass characterClass;
  final ClassSpecialization? specialization;
  final int level;
  final int experience;
  final Map<String, int> stats;
  final List<String> unlockedSkills;
  final Map<String, int> skillMastery;
  final List<String> achievements;
  final List<String> titles;
  final String? equippedTitle;
  final DateTime creationDate;
  final DateTime lastLoginDate;
  final int playTime;
  final Map<String, dynamic> characterData;

  const CharacterProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.characterClass,
    this.specialization,
    required this.level,
    required this.experience,
    required this.stats,
    required this.unlockedSkills,
    required this.skillMastery,
    required this.achievements,
    required this.titles,
    this.equippedTitle,
    required this.creationDate,
    required this.lastLoginDate,
    required this.playTime,
    required this.characterData,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    characterClass,
    specialization,
    level,
    experience,
    stats,
    unlockedSkills,
    skillMastery,
    achievements,
    titles,
    equippedTitle,
    creationDate,
    lastLoginDate,
    playTime,
    characterData,
  ];
}

class CharacterTransfer extends Equatable {
  final String id;
  final String sourceCharacterId;
  final String targetCharacterId;
  final CharacterTransferType type;
  final Map<String, dynamic> transferData;
  final bool isCompleted;
  final DateTime transferDate;
  final DateTime? completionDate;
  final String? transferNotes;

  const CharacterTransfer({
    required this.id,
    required this.sourceCharacterId,
    required this.targetCharacterId,
    required this.type,
    required this.transferData,
    required this.isCompleted,
    required this.transferDate,
    this.completionDate,
    this.transferNotes,
  });

  @override
  List<Object?> get props => [
    id,
    sourceCharacterId,
    targetCharacterId,
    type,
    transferData,
    isCompleted,
    transferDate,
    completionDate,
    transferNotes,
  ];
}

class MultiCharacterManager extends Equatable {
  final String accountId;
  final List<CharacterSlot> characterSlots;
  final List<CharacterProfile> characters;
  final String? activeCharacterId;
  final int maxSlots;
  final int premiumSlots;
  final Map<String, dynamic> accountBonuses;
  final List<CharacterTransfer> transferHistory;

  const MultiCharacterManager({
    required this.accountId,
    required this.characterSlots,
    required this.characters,
    this.activeCharacterId,
    required this.maxSlots,
    required this.premiumSlots,
    required this.accountBonuses,
    required this.transferHistory,
  });

  int get availableSlots => characterSlots.where((slot) => slot.status == CharacterSlotStatus.empty).length;
  int get occupiedSlots => characterSlots.where((slot) => slot.status == CharacterSlotStatus.occupied).length;
  bool get canCreateCharacter => availableSlots > 0;

  @override
  List<Object?> get props => [
    accountId,
    characterSlots,
    characters,
    activeCharacterId,
    maxSlots,
    premiumSlots,
    accountBonuses,
    transferHistory,
  ];
}

class MultiCharacterService {
  static const int defaultMaxSlots = 3;
  static const int premiumMaxSlots = 10;
  static const int slotUnlockCost = 1000;
  static const int premiumSlotCost = 5000;

  static List<CharacterSlot> createDefaultSlots() {
    return List.generate(defaultMaxSlots, (index) {
      return CharacterSlot(
        id: 'slot_${index + 1}',
        status: index == 0 ? CharacterSlotStatus.empty : CharacterSlotStatus.locked,
        isPremium: false,
      );
    });
  }

  static List<CharacterSlot> createPremiumSlots() {
    return List.generate(premiumMaxSlots, (index) {
      return CharacterSlot(
        id: 'premium_slot_${index + 1}',
        status: index < defaultMaxSlots ? CharacterSlotStatus.empty : CharacterSlotStatus.locked,
        isPremium: index >= defaultMaxSlots,
      );
    });
  }

  static bool canUnlockSlot(CharacterSlot slot, int accountLevel, int currency) {
    if (slot.status != CharacterSlotStatus.locked) return false;
    
    if (slot.isPremium) {
      return currency >= premiumSlotCost && accountLevel >= 50;
    } else {
      return currency >= slotUnlockCost && accountLevel >= 10;
    }
  }

  static CharacterSlot unlockSlot(CharacterSlot slot, DateTime unlockDate) {
    return CharacterSlot(
      id: slot.id,
      status: CharacterSlotStatus.empty,
      isPremium: slot.isPremium,
      unlockDate: unlockDate,
      slotBonuses: slot.slotBonuses,
    );
  }

  static CharacterSlot occupySlot(CharacterSlot slot, String characterId) {
    return CharacterSlot(
      id: slot.id,
      characterId: characterId,
      status: CharacterSlotStatus.occupied,
      isPremium: slot.isPremium,
      unlockDate: slot.unlockDate,
      lastUsedDate: DateTime.now(),
      slotBonuses: slot.slotBonuses,
    );
  }

  static CharacterSlot freeSlot(CharacterSlot slot) {
    return CharacterSlot(
      id: slot.id,
      status: CharacterSlotStatus.empty,
      isPremium: slot.isPremium,
      unlockDate: slot.unlockDate,
      lastUsedDate: slot.lastUsedDate,
      slotBonuses: slot.slotBonuses,
    );
  }

  static CharacterProfile createCharacterProfile({
    required String id,
    required String name,
    required String description,
    required CharacterClass characterClass,
    ClassSpecialization? specialization,
    int level = 1,
    int experience = 0,
    Map<String, int>? stats,
    List<String>? unlockedSkills,
    Map<String, int>? skillMastery,
  }) {
    final classData = CharacterClassService.getClassData(characterClass);
    final baseStats = CharacterClassService.calculateTotalStats(characterClass, specialization, level);
    
    return CharacterProfile(
      id: id,
      name: name,
      description: description,
      characterClass: characterClass,
      specialization: specialization,
      level: level,
      experience: experience,
      stats: stats ?? baseStats,
      unlockedSkills: unlockedSkills ?? classData.startingSkills,
      skillMastery: skillMastery ?? {},
      achievements: [],
      titles: [],
      creationDate: DateTime.now(),
      lastLoginDate: DateTime.now(),
      playTime: 0,
      characterData: {},
    );
  }

  static bool canTransferItem(CharacterTransferType type, CharacterProfile source, CharacterProfile target) {
    switch (type) {
      case CharacterTransferType.equipment:
        return source.level >= 10 && target.level >= 10;
      case CharacterTransferType.items:
        return true;
      case CharacterTransferType.currency:
        return source.level >= 5 && target.level >= 5;
      case CharacterTransferType.experience:
        return source.level >= 20 && target.level >= 20;
      case CharacterTransferType.skills:
        return source.level >= 15 && target.level >= 15;
      case CharacterTransferType.achievements:
        return false; // Achievements cannot be transferred
    }
  }

  static CharacterTransfer createTransfer({
    required String sourceCharacterId,
    required String targetCharacterId,
    required CharacterTransferType type,
    required Map<String, dynamic> transferData,
    String? transferNotes,
  }) {
    return CharacterTransfer(
      id: 'transfer_${DateTime.now().millisecondsSinceEpoch}',
      sourceCharacterId: sourceCharacterId,
      targetCharacterId: targetCharacterId,
      type: type,
      transferData: transferData,
      isCompleted: false,
      transferDate: DateTime.now(),
      transferNotes: transferNotes,
    );
  }

  static CharacterTransfer completeTransfer(CharacterTransfer transfer) {
    return CharacterTransfer(
      id: transfer.id,
      sourceCharacterId: transfer.sourceCharacterId,
      targetCharacterId: transfer.targetCharacterId,
      type: transfer.type,
      transferData: transfer.transferData,
      isCompleted: true,
      transferDate: transfer.transferDate,
      completionDate: DateTime.now(),
      transferNotes: transfer.transferNotes,
    );
  }

  static Map<String, double> calculateAccountBonuses(MultiCharacterManager manager) {
    final bonuses = <String, double>{};
    
    // Bonus for having multiple characters
    final characterCount = manager.characters.length;
    if (characterCount >= 3) {
      bonuses['experience_gain'] = 0.1;
    }
    if (characterCount >= 5) {
      bonuses['experience_gain'] = 0.2;
      bonuses['skill_point_gain'] = 0.05;
    }
    if (characterCount >= 10) {
      bonuses['experience_gain'] = 0.3;
      bonuses['skill_point_gain'] = 0.1;
      bonuses['all_stats'] = 0.05;
    }
    
    // Premium slot bonuses
    final premiumSlotCount = manager.characterSlots.where((slot) => slot.isPremium).length;
    if (premiumSlotCount >= 3) {
      bonuses['premium_bonus'] = 0.1;
    }
    
    // Account level bonuses
    final accountLevel = _calculateAccountLevel(manager);
    if (accountLevel >= 50) {
      bonuses['account_mastery'] = 0.1;
    }
    
    return bonuses;
  }

  static int _calculateAccountLevel(MultiCharacterManager manager) {
    int totalLevel = 0;
    int totalExperience = 0;
    
    for (final character in manager.characters) {
      totalLevel += character.level;
      totalExperience += character.experience;
    }
    
    // Account level is based on total character levels and experience
    return (totalLevel + (totalExperience / 1000)).round();
  }

  static List<CharacterProfile> getCharactersByClass(MultiCharacterManager manager, CharacterClass characterClass) {
    return manager.characters.where((character) => character.characterClass == characterClass).toList();
  }

  static List<CharacterProfile> getCharactersByLevel(MultiCharacterManager manager, int minLevel, int maxLevel) {
    return manager.characters
        .where((character) => character.level >= minLevel && character.level <= maxLevel)
        .toList();
  }

  static CharacterProfile? getActiveCharacter(MultiCharacterManager manager) {
    if (manager.activeCharacterId == null) return null;
    
    return manager.characters
        .firstWhere(
          (character) => character.id == manager.activeCharacterId,
          orElse: () => manager.characters.first,
        );
  }

  static MultiCharacterManager setActiveCharacter(MultiCharacterManager manager, String characterId) {
    return MultiCharacterManager(
      accountId: manager.accountId,
      characterSlots: manager.characterSlots,
      characters: manager.characters,
      activeCharacterId: characterId,
      maxSlots: manager.maxSlots,
      premiumSlots: manager.premiumSlots,
      accountBonuses: manager.accountBonuses,
      transferHistory: manager.transferHistory,
    );
  }

  static MultiCharacterManager addCharacter(MultiCharacterManager manager, CharacterProfile character, String slotId) {
    final updatedSlots = manager.characterSlots.map((slot) {
      if (slot.id == slotId) {
        return occupySlot(slot, character.id);
      }
      return slot;
    }).toList();
    
    final updatedCharacters = List<CharacterProfile>.from(manager.characters)..add(character);
    
    return MultiCharacterManager(
      accountId: manager.accountId,
      characterSlots: updatedSlots,
      characters: updatedCharacters,
      activeCharacterId: manager.activeCharacterId,
      maxSlots: manager.maxSlots,
      premiumSlots: manager.premiumSlots,
      accountBonuses: manager.accountBonuses,
      transferHistory: manager.transferHistory,
    );
  }

  static MultiCharacterManager removeCharacter(MultiCharacterManager manager, String characterId) {
    final updatedSlots = manager.characterSlots.map((slot) {
      if (slot.characterId == characterId) {
        return freeSlot(slot);
      }
      return slot;
    }).toList();
    
    final updatedCharacters = manager.characters.where((character) => character.id != characterId).toList();
    
    String? newActiveCharacterId = manager.activeCharacterId;
    if (manager.activeCharacterId == characterId) {
      newActiveCharacterId = updatedCharacters.isNotEmpty ? updatedCharacters.first.id : null;
    }
    
    return MultiCharacterManager(
      accountId: manager.accountId,
      characterSlots: updatedSlots,
      characters: updatedCharacters,
      activeCharacterId: newActiveCharacterId,
      maxSlots: manager.maxSlots,
      premiumSlots: manager.premiumSlots,
      accountBonuses: manager.accountBonuses,
      transferHistory: manager.transferHistory,
    );
  }

  static List<String> getCharacterRecommendations(MultiCharacterManager manager) {
    final recommendations = <String>[];
    final existingClasses = manager.characters.map((c) => c.characterClass).toSet();
    
    // Recommend missing character classes
    for (final characterClass in CharacterClass.values) {
      if (!existingClasses.contains(characterClass)) {
        final classData = CharacterClassService.getClassData(characterClass);
        recommendations.add('Try ${classData.name} - ${classData.description}');
      }
    }
    
    // Recommend slot unlocks
    if (manager.availableSlots == 0 && manager.maxSlots < premiumMaxSlots) {
      recommendations.add('Unlock more character slots to create additional characters');
    }
    
    // Recommend character transfers
    if (manager.characters.length >= 2) {
      recommendations.add('Use character transfers to share resources between characters');
    }
    
    return recommendations;
  }

  static Map<String, dynamic> getCharacterStatistics(MultiCharacterManager manager) {
    final stats = <String, dynamic>{};
    
    stats['total_characters'] = manager.characters.length;
    stats['total_level'] = manager.characters.fold(0, (sum, character) => sum + character.level);
    stats['total_experience'] = manager.characters.fold(0, (sum, character) => sum + character.experience);
    stats['total_play_time'] = manager.characters.fold(0, (sum, character) => sum + character.playTime);
    stats['total_achievements'] = manager.characters.fold(0, (sum, character) => sum + character.achievements.length);
    stats['total_titles'] = manager.characters.fold(0, (sum, character) => sum + character.titles.length);
    
    // Class distribution
    final classDistribution = <String, int>{};
    for (final character in manager.characters) {
      final className = CharacterClassService.getClassData(character.characterClass).name;
      classDistribution[className] = (classDistribution[className] ?? 0) + 1;
    }
    stats['class_distribution'] = classDistribution;
    
    // Level distribution
    final levelRanges = {
      '1-10': 0,
      '11-25': 0,
      '26-50': 0,
      '51-100': 0,
      '100+': 0,
    };
    
    for (final character in manager.characters) {
      if (character.level <= 10) {
        levelRanges['1-10'] = (levelRanges['1-10'] ?? 0) + 1;
      } else if (character.level <= 25) {
        levelRanges['11-25'] = (levelRanges['11-25'] ?? 0) + 1;
      } else if (character.level <= 50) {
        levelRanges['26-50'] = (levelRanges['26-50'] ?? 0) + 1;
      } else if (character.level <= 100) {
        levelRanges['51-100'] = (levelRanges['51-100'] ?? 0) + 1;
      } else {
        levelRanges['100+'] = (levelRanges['100+'] ?? 0) + 1;
      }
    }
    stats['level_distribution'] = levelRanges;
    
    return stats;
  }
}
