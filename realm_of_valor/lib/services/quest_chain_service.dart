import 'dart:math';
import '../../../data/models/quest_model.dart';

class QuestChainService {
  static final QuestChainService _instance = QuestChainService._internal();
  factory QuestChainService() => _instance;
  QuestChainService._internal();

  final Random _random = Random();

  /// Generate a quest chain
  QuestChain generateQuestChain({
    required String chainId,
    required String title,
    required QuestType primaryType,
    required int chainLength,
    required LatLng startLocation,
    required int playerLevel,
  }) {
    final quests = <Quest>[];
    final connections = <QuestConnection>[];
    
    // Generate the first quest
    final firstQuest = _generateChainQuest(
      chainId: chainId,
      questIndex: 0,
      totalQuests: chainLength,
      questType: primaryType,
      location: startLocation,
      playerLevel: playerLevel,
      isFirst: true,
    );
    quests.add(firstQuest);
    
    // Generate subsequent quests
    for (int i = 1; i < chainLength; i++) {
      final previousQuest = quests[i - 1];
      final nextLocation = _generateNextLocation(previousQuest.location!);
      
      final quest = _generateChainQuest(
        chainId: chainId,
        questIndex: i,
        totalQuests: chainLength,
        questType: _determineNextQuestType(primaryType, i, chainLength),
        location: nextLocation,
        playerLevel: playerLevel,
        isFirst: false,
        previousQuest: previousQuest,
      );
      
      quests.add(quest);
      
      // Add connection
      connections.add(QuestConnection(
        fromQuestId: previousQuest.id,
        toQuestId: quest.id,
        connectionType: _determineConnectionType(i, chainLength),
      ));
    }
    
    return QuestChain(
      id: chainId,
      title: title,
      description: _generateChainDescription(title, chainLength, primaryType),
      quests: quests,
      connections: connections,
      totalQuests: chainLength,
      completedQuests: 0,
      rewards: _generateChainRewards(chainLength, playerLevel),
      isCompleted: false,
    );
  }

  Quest _generateChainQuest({
    required String chainId,
    required int questIndex,
    required int totalQuests,
    required QuestType questType,
    required LatLng location,
    required int playerLevel,
    required bool isFirst,
    Quest? previousQuest,
  }) {
    final questId = '${chainId}_quest_$questIndex';
    final questTitle = _generateChainQuestTitle(questIndex, totalQuests, questType);
    final questDescription = _generateChainQuestDescription(
      questIndex, 
      totalQuests, 
      questType, 
      isFirst, 
      previousQuest,
    );
    
    // Calculate rewards based on position in chain
    final baseReward = 20 + (playerLevel * 5);
    final chainBonus = (questIndex + 1) * 10; // Later quests give more rewards
    
    return Quest(
      id: questId,
      title: questTitle,
      type: questType,
      category: QuestCategory.main,
      status: QuestStatus.notStarted,
      description: questDescription,
      objectives: _generateChainObjectives(questIndex, totalQuests, questType),
      rewards: QuestRewards(
        xp: baseReward + chainBonus,
        gold: (baseReward + chainBonus) ~/ 2,
        gems: _random.nextInt(3) + 1,
        items: _generateChainRewardItems(questIndex, questType),
        skillPoints: questIndex == totalQuests - 1 ? 2 : 0, // Final quest gives skill points
      ),
      location: QuestLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        radius: 100.0,
        name: 'Chain Quest Location ${questIndex + 1}',
      ),
      tags: _generateChainTags(chainId, questIndex, questType),
      prerequisites: previousQuest != null ? [previousQuest.id] : [],
      timeLimit: _calculateChainTimeLimit(questIndex, totalQuests),
    );
  }

  String _generateChainQuestTitle(int questIndex, int totalQuests, QuestType questType) {
    final partNumber = questIndex + 1;
    final totalParts = totalQuests;
    
    String baseTitle;
    switch (questType) {
      case QuestType.battle:
        baseTitle = _getBattleChainTitle(questIndex);
        break;
      case QuestType.treasure:
        baseTitle = _getTreasureChainTitle(questIndex);
        break;
      case QuestType.location:
        baseTitle = _getLocationChainTitle(questIndex);
        break;
      case QuestType.story:
        baseTitle = _getStoryChainTitle(questIndex);
        break;
      default:
        baseTitle = 'Chain Quest ${partNumber}';
    }
    
    return '$baseTitle (Part $partNumber/$totalParts)';
  }

  String _getBattleChainTitle(int questIndex) {
    final titles = [
      'The First Strike',
      'Escalating Conflict',
      'The Siege',
      'Final Showdown',
      'Victory Celebration',
    ];
    return titles[questIndex % titles.length];
  }

  String _getTreasureChainTitle(int questIndex) {
    final titles = [
      'The First Clue',
      'Following the Trail',
      'The Hidden Chamber',
      'The Guardian\'s Test',
      'The Ultimate Treasure',
    ];
    return titles[questIndex % titles.length];
  }

  String _getLocationChainTitle(int questIndex) {
    final titles = [
      'The Journey Begins',
      'Crossing the Border',
      'The Heart of the Land',
      'The Sacred Ground',
      'The Destination',
    ];
    return titles[questIndex % titles.length];
  }

  String _getStoryChainTitle(int questIndex) {
    final titles = [
      'The Beginning',
      'Rising Action',
      'The Climax',
      'Falling Action',
      'The Conclusion',
    ];
    return titles[questIndex % titles.length];
  }

  String _generateChainQuestDescription(
    int questIndex, 
    int totalQuests, 
    QuestType questType, 
    bool isFirst, 
    Quest? previousQuest,
  ) {
    String baseDescription;
    
    if (isFirst) {
      baseDescription = 'Begin your epic journey. This is the first step in a grand adventure.';
    } else {
      baseDescription = 'Continue your quest. The path grows more challenging as you progress.';
    }
    
    // Add quest-specific details
    switch (questType) {
      case QuestType.battle:
        baseDescription += ' Prepare for combat and test your skills.';
        break;
      case QuestType.treasure:
        baseDescription += ' Search for hidden treasures and ancient artifacts.';
        break;
      case QuestType.location:
        baseDescription += ' Explore new territories and discover their secrets.';
        break;
      case QuestType.story:
        baseDescription += ' Uncover the mysteries of this ancient tale.';
        break;
      default:
        baseDescription += ' Complete this part of your journey.';
    }
    
    // Add progress context
    if (questIndex == totalQuests - 1) {
      baseDescription += ' This is the final challenge of your quest chain!';
    } else {
      baseDescription += ' Complete this to unlock the next part of your journey.';
    }
    
    return baseDescription;
  }

  List<QuestObjective> _generateChainObjectives(int questIndex, int totalQuests, QuestType questType) {
    final objectives = <QuestObjective>[];
    
    // Main objective
    objectives.add(QuestObjective(
      id: 'complete_chain_quest',
      description: 'Complete this part of the quest chain',
      target: 1,
      progress: 0,
      type: 'chain',
    ));
    
    // Additional objectives based on quest type
    switch (questType) {
      case QuestType.battle:
        objectives.add(QuestObjective(
          id: 'defeat_enemies',
          description: 'Defeat all enemies in the area',
          target: 3 + questIndex, // More enemies in later quests
          progress: 0,
          type: 'combat',
        ));
        break;
      case QuestType.treasure:
        objectives.add(QuestObjective(
          id: 'find_artifacts',
          description: 'Find hidden artifacts',
          target: 2 + questIndex,
          progress: 0,
          type: 'exploration',
        ));
        break;
      case QuestType.location:
        objectives.add(QuestObjective(
          id: 'explore_areas',
          description: 'Explore marked locations',
          target: 1 + questIndex,
          progress: 0,
          type: 'exploration',
        ));
        break;
      case QuestType.story:
        objectives.add(QuestObjective(
          id: 'gather_information',
          description: 'Gather information from NPCs',
          target: 2,
          progress: 0,
          type: 'social',
        ));
        break;
    }
    
    return objectives;
  }

  List<String> _generateChainTags(String chainId, int questIndex, QuestType questType) {
    final tags = <String>[
      'quest_chain:$chainId',
      'chain_position:$questIndex',
      'quest_type:${questType.name}',
    ];
    
    if (questIndex == 0) {
      tags.add('chain_start');
    }
    
    return tags;
  }

  List<String> _generateChainRewardItems(int questIndex, QuestType questType) {
    final items = <String>[];
    
    // Base items for quest type
    switch (questType) {
      case QuestType.battle:
        items.addAll(['weapon_upgrade', 'armor_piece']);
        break;
      case QuestType.treasure:
        items.addAll(['treasure_map', 'ancient_coin']);
        break;
      case QuestType.location:
        items.addAll(['travel_token', 'exploration_gear']);
        break;
      case QuestType.story:
        items.addAll(['story_scroll', 'knowledge_tome']);
        break;
    }
    
    // Chain-specific items
    items.add('chain_token_${questIndex + 1}');
    
    return items;
  }

  LatLng _generateNextLocation(QuestLocation previousLocation) {
    // Generate a location within 2km of the previous location
    final latOffset = (_random.nextDouble() - 0.5) * 0.02; // ~2km
    final lngOffset = (_random.nextDouble() - 0.5) * 0.02; // ~2km
    
    return LatLng(
      previousLocation.latitude + latOffset,
      previousLocation.longitude + lngOffset,
    );
  }

  QuestType _determineNextQuestType(QuestType primaryType, int questIndex, int totalQuests) {
    // Mix up quest types throughout the chain
    if (questIndex == totalQuests - 1) {
      return primaryType; // Final quest matches primary type
    }
    
    // Randomly vary quest types
    final questTypes = QuestType.values;
    final randomType = questTypes[_random.nextInt(questTypes.length)];
    
    // 70% chance to keep primary type, 30% chance to vary
    return _random.nextDouble() < 0.7 ? primaryType : randomType;
  }

  ConnectionType _determineConnectionType(int questIndex, int totalQuests) {
    if (questIndex == totalQuests - 2) {
      return ConnectionType.final; // Connection to final quest
    } else if (questIndex == 0) {
      return ConnectionType.start; // First connection
    } else {
      return ConnectionType.standard; // Standard connection
    }
  }

  String _generateChainDescription(String title, int chainLength, QuestType primaryType) {
    return 'A $chainLength-part quest chain about $title. '
           'This epic journey will test your skills in ${primaryType.name} quests. '
           'Complete each part to unlock the next and earn special chain rewards.';
  }

  QuestRewards _generateChainRewards(int chainLength, int playerLevel) {
    final baseReward = 100 + (playerLevel * 20);
    final chainBonus = chainLength * 50;
    
    return QuestRewards(
      xp: baseReward + chainBonus,
      gold: (baseReward + chainBonus) ~/ 2,
      gems: chainLength * 5,
      items: ['chain_completion_trophy', 'special_chain_item'],
      skillPoints: chainLength,
    );
  }

  int? _calculateChainTimeLimit(int questIndex, int totalQuests) {
    // Later quests have shorter time limits
    final baseTime = 120; // 2 hours
    final timeReduction = questIndex * 10; // 10 minutes less per quest
    
    return baseTime - timeReduction;
  }

  /// Update quest chain progress
  void updateChainProgress(QuestChain chain, String completedQuestId) {
    final completedQuest = chain.quests.firstWhere((q) => q.id == completedQuestId);
    final questIndex = chain.quests.indexOf(completedQuest);
    
    chain.completedQuests = questIndex + 1;
    
    // Check if chain is completed
    if (chain.completedQuests >= chain.totalQuests) {
      chain.isCompleted = true;
    }
    
    // Unlock next quest if available
    if (questIndex + 1 < chain.quests.length) {
      final nextQuest = chain.quests[questIndex + 1];
      nextQuest.status = QuestStatus.notStarted;
    }
  }

  /// Get available quest chains for player level
  List<QuestChain> getAvailableChains(int playerLevel) {
    final chains = <QuestChain>[];
    
    // Generate different types of chains
    final chainTypes = [
      {'type': QuestType.battle, 'title': 'The Warrior\'s Path', 'length': 5},
      {'type': QuestType.treasure, 'title': 'The Treasure Hunter\'s Journey', 'length': 4},
      {'type': QuestType.location, 'title': 'The Explorer\'s Expedition', 'length': 6},
      {'type': QuestType.story, 'title': 'The Ancient Tale', 'length': 5},
    ];
    
    for (final chainType in chainTypes) {
      final chain = generateQuestChain(
        chainId: 'chain_${chainType['type']}_${DateTime.now().millisecondsSinceEpoch}',
        title: chainType['title'] as String,
        primaryType: chainType['type'] as QuestType,
        chainLength: chainType['length'] as int,
        startLocation: const LatLng(52.232192, -0.8912896), // Northampton
        playerLevel: playerLevel,
      );
      
      chains.add(chain);
    }
    
    return chains;
  }
}

class QuestChain {
  final String id;
  final String title;
  final String description;
  final List<Quest> quests;
  final List<QuestConnection> connections;
  final int totalQuests;
  int completedQuests;
  final QuestRewards rewards;
  bool isCompleted;

  QuestChain({
    required this.id,
    required this.title,
    required this.description,
    required this.quests,
    required this.connections,
    required this.totalQuests,
    required this.completedQuests,
    required this.rewards,
    required this.isCompleted,
  });

  double get progressPercentage => completedQuests / totalQuests;
  
  Quest? get currentQuest {
    if (completedQuests >= totalQuests) return null;
    return quests[completedQuests];
  }
  
  List<Quest> get availableQuests {
    return quests.take(completedQuests + 1).toList();
  }
}

class QuestConnection {
  final String fromQuestId;
  final String toQuestId;
  final ConnectionType connectionType;

  QuestConnection({
    required this.fromQuestId,
    required this.toQuestId,
    required this.connectionType,
  });
}

enum ConnectionType {
  start,
  standard,
  final,
  branch,
}