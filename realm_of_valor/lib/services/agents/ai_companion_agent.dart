import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/result.dart';
import '../base_agent.dart';
import '../event_bus.dart';
import '../../data/models/quest_model.dart';

enum CompanionPersonality {
  friendly,
  enthusiastic,
  wisdom,
  mysterious,
}

class AICompanionAgent extends BaseAgent {
  AICompanionAgent(super.bus);

  CompanionPersonality _personality = CompanionPersonality.friendly;
  final Map<String, String> _memory = {};
  bool _isEnabled = true;
  int _cooldownTicks = 0;
  static const int _cooldownDuration = 10; // ticks

  @override
  String get name => 'AI Companion Agent';

  @override
  Future<void> onInitialize() async {
    debugPrint('AICompanionAgent: Initializing AI Companion Agent');
    _subscribeToEvents();
    debugPrint('AICompanionAgent: Subscribed to events');
  }

  void _subscribeToEvents() {
    bus.subscribe('companion.set_personality', (evt, b) => _onSetPersonality(evt));
    bus.subscribe('companion.ask', (evt, b) => _onAskQuestion(evt));
    bus.subscribe('companion.toggle', (evt, b) => _onToggle(evt));
    bus.subscribe('companion.settings', (evt, b) => _onSettings(evt));
    
    // Proactive events
    bus.subscribe('quest.add', (evt, b) => _onQuestAdded(evt));
    bus.subscribe('quest.completed', (evt, b) => _onQuestComplete(evt));
    bus.subscribe('battle.start', (evt, b) => _onBattleStart(evt));
    bus.subscribe('battle.ended', (evt, b) => _onBattleEnd(evt));
    bus.subscribe('fitness.update', (evt, b) => _onFitnessUpdate(evt));
    bus.subscribe('achievement.unlock', (evt, b) => _onAchievementUnlock(evt));
    bus.subscribe('card.obtain', (evt, b) => _onCardObtain(evt));
    bus.subscribe('character.level_up', (evt, b) => _onLevelUp(evt));
    bus.subscribe('location.update', (evt, b) => _onLocationUpdate(evt));
  }

  void _onSetPersonality(Event evt) {
    debugPrint('AICompanionAgent: Setting personality to ${evt.data?['personality']}');
    final personalityStr = evt.data?['personality'] as String?;
    if (personalityStr != null) {
      _personality = CompanionPersonality.values.firstWhere(
        (p) => p.name == personalityStr,
        orElse: () => CompanionPersonality.friendly,
      );
      debugPrint('AICompanionAgent: Personality set to ${_personality.name}');
    }
  }

  void _onAskQuestion(Event evt) {
    debugPrint('AICompanionAgent: Processing question: ${evt.data?['question']}');
    final question = evt.data?['question'] as String?;
    if (question != null) {
      final response = _generateResponse(question);
      debugPrint('AICompanionAgent: Generated response: $response');
      
      bus.publish(Event(
        type: 'companion.reply',
        data: {
          'question': question,
          'response': response,
          'personality': _personality.name,
        },
      ));
    }
  }

  void _onToggle(Event evt) {
    debugPrint('AICompanionAgent: Toggling companion');
    _isEnabled = !_isEnabled;
    debugPrint('AICompanionAgent: Companion enabled: $_isEnabled');
    
    bus.publish(Event(
      type: 'companion.status',
      data: {'enabled': _isEnabled},
    ));
  }

  void _onSettings(Event evt) {
    debugPrint('AICompanionAgent: Processing settings update');
    final settings = evt.data as Map<String, dynamic>?;
    if (settings != null) {
      if (settings.containsKey('personality')) {
        _personality = CompanionPersonality.values.firstWhere(
          (p) => p.name == settings['personality'],
          orElse: () => CompanionPersonality.friendly,
        );
        debugPrint('AICompanionAgent: Personality updated to ${_personality.name}');
      }
      
      if (settings.containsKey('enabled')) {
        _isEnabled = settings['enabled'] as bool;
        debugPrint('AICompanionAgent: Enabled status updated to $_isEnabled');
      }
    }
  }

  void _onQuestAdded(Event evt) {
    debugPrint('AICompanionAgent: Quest added event received');
    if (!_isEnabled || _cooldownTicks > 0) {
      debugPrint('AICompanionAgent: Skipping proactive response (disabled or cooldown)');
      return;
    }
    
    final questData = evt.data as Map<String, dynamic>?;
    if (questData != null) {
      final questTitle = questData['title'] as String? ?? 'Unknown Quest';
      final questType = questData['type'] as String? ?? 'Unknown';
      
      debugPrint('AICompanionAgent: Quest added - $questTitle ($questType)');
      
      final tip = _generateQuestTip(questTitle, questType);
      debugPrint('AICompanionAgent: Generated quest tip: $tip');
      
      _sendProactiveTip('New Quest Available!', tip);
    }
  }

  void _onQuestComplete(Event evt) {
    debugPrint('AICompanionAgent: Quest completed event received');
    if (!_isEnabled || _cooldownTicks > 0) return;
    
    final questData = evt.data as Map<String, dynamic>?;
    if (questData != null) {
      final questTitle = questData['title'] as String? ?? 'Unknown Quest';
      final rewards = questData['rewards'] as Map<String, dynamic>?;
      
      debugPrint('AICompanionAgent: Quest completed - $questTitle');
      
      final congratulations = _generateCompletionMessage(questTitle, rewards);
      debugPrint('AICompanionAgent: Generated completion message: $congratulations');
      
      _sendProactiveTip('Quest Completed!', congratulations);
    }
  }

  void _onBattleStart(Event evt) {
    debugPrint('AICompanionAgent: Battle started event received');
    if (!_isEnabled || _cooldownTicks > 0) return;
    
    final battleData = evt.data as Map<String, dynamic>?;
    if (battleData != null) {
      final enemyName = battleData['enemy'] as String? ?? 'Unknown Enemy';
      
      debugPrint('AICompanionAgent: Battle started against $enemyName');
      
      final battleTip = _generateBattleTip(enemyName);
      debugPrint('AICompanionAgent: Generated battle tip: $battleTip');
      
      _sendProactiveTip('Battle Started!', battleTip);
    }
  }

  void _onBattleEnd(Event evt) {
    debugPrint('AICompanionAgent: Battle ended event received');
    if (!_isEnabled || _cooldownTicks > 0) return;
    
    final battleData = evt.data as Map<String, dynamic>?;
    if (battleData != null) {
      final result = battleData['result'] as String? ?? 'unknown';
      final enemyName = battleData['enemy'] as String? ?? 'Unknown Enemy';
      
      debugPrint('AICompanionAgent: Battle ended - $result against $enemyName');
      
      final battleResult = _generateBattleResult(result, enemyName);
      debugPrint('AICompanionAgent: Generated battle result: $battleResult');
      
      _sendProactiveTip('Battle Result', battleResult);
    }
  }

  void _onFitnessUpdate(Event evt) {
    debugPrint('AICompanionAgent: Fitness update event received');
    if (!_isEnabled || _cooldownTicks > 0) return;
    
    final fitnessData = evt.data as Map<String, dynamic>?;
    if (fitnessData != null) {
      final steps = fitnessData['steps'] as int? ?? 0;
      final goal = fitnessData['goal'] as int? ?? 10000;
      
      debugPrint('AICompanionAgent: Fitness update - $steps/$goal steps');
      
      if (steps >= goal) {
        final fitnessTip = _generateFitnessTip(steps, goal);
        debugPrint('AICompanionAgent: Generated fitness tip: $fitnessTip');
        
        _sendProactiveTip('Fitness Goal Reached!', fitnessTip);
      }
    }
  }

  void _onAchievementUnlock(Event evt) {
    debugPrint('AICompanionAgent: Achievement unlocked event received');
    if (!_isEnabled || _cooldownTicks > 0) return;
    
    final achievementData = evt.data as Map<String, dynamic>?;
    if (achievementData != null) {
      final achievementName = achievementData['name'] as String? ?? 'Unknown Achievement';
      
      debugPrint('AICompanionAgent: Achievement unlocked - $achievementName');
      
      final achievementTip = _generateAchievementTip(achievementName);
      debugPrint('AICompanionAgent: Generated achievement tip: $achievementTip');
      
      _sendProactiveTip('Achievement Unlocked!', achievementTip);
    }
  }

  void _onCardObtain(Event evt) {
    debugPrint('AICompanionAgent: Card obtained event received');
    if (!_isEnabled || _cooldownTicks > 0) return;
    
    final cardData = evt.data as Map<String, dynamic>?;
    if (cardData != null) {
      final cardName = cardData['name'] as String? ?? 'Unknown Card';
      final rarity = cardData['rarity'] as String? ?? 'common';
      
      debugPrint('AICompanionAgent: Card obtained - $cardName ($rarity)');
      
      final cardTip = _generateCardTip(cardName, rarity);
      debugPrint('AICompanionAgent: Generated card tip: $cardTip');
      
      _sendProactiveTip('New Card Obtained!', cardTip);
    }
  }

  void _onLevelUp(Event evt) {
    debugPrint('AICompanionAgent: Level up event received');
    if (!_isEnabled || _cooldownTicks > 0) return;
    
    final levelData = evt.data as Map<String, dynamic>?;
    if (levelData != null) {
      final newLevel = levelData['level'] as int? ?? 1;
      
      debugPrint('AICompanionAgent: Level up to $newLevel');
      
      final levelTip = _generateLevelUpTip(newLevel);
      debugPrint('AICompanionAgent: Generated level up tip: $levelTip');
      
      _sendProactiveTip('Level Up!', levelTip);
    }
  }

  void _onLocationUpdate(Event evt) {
    debugPrint('AICompanionAgent: Location update event received');
    if (!_isEnabled || _cooldownTicks > 0) return;
    
    final locationData = evt.data as Map<String, dynamic>?;
    if (locationData != null) {
      final latitude = locationData['latitude'] as double? ?? 0.0;
      final longitude = locationData['longitude'] as double? ?? 0.0;
      
      debugPrint('AICompanionAgent: Location updated - $latitude, $longitude');
      
      // Store location in memory for context
      _memory['last_location'] = '($latitude, $longitude)';
      debugPrint('AICompanionAgent: Location stored in memory');
    }
  }

  String _generateResponse(String question) {
    debugPrint('AICompanionAgent: Generating response for: $question');
    
    final lowerQuestion = question.toLowerCase();
    String response = '';

    if (lowerQuestion.contains('quest') || lowerQuestion.contains('mission')) {
      response = _getQuestResponse();
    } else if (lowerQuestion.contains('battle') || lowerQuestion.contains('fight')) {
      response = _getBattleResponse();
    } else if (lowerQuestion.contains('fitness') || lowerQuestion.contains('exercise')) {
      response = _getFitnessResponse();
    } else if (lowerQuestion.contains('card') || lowerQuestion.contains('pack')) {
      response = _getCardResponse();
    } else if (lowerQuestion.contains('character') || lowerQuestion.contains('level')) {
      response = _getCharacterResponse();
    } else if (lowerQuestion.contains('map') || lowerQuestion.contains('location')) {
      response = _getMapResponse();
    } else {
      response = _getGeneralResponse();
    }

    debugPrint('AICompanionAgent: Response generated: $response');
    return _applyPersonality(response);
  }

  String _getQuestResponse() {
    debugPrint('AICompanionAgent: Getting quest response');
    final responses = [
      'Check your quest log for available missions!',
      'Explore the map to find location-based quests.',
      'Complete daily quests for consistent rewards.',
      'Main quests advance the story - focus on those first!',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _getBattleResponse() {
    debugPrint('AICompanionAgent: Getting battle response');
    final responses = [
      'Use your strongest cards in battle!',
      'Check your equipment before engaging enemies.',
      'Some battles require specific strategies.',
      'Don\'t forget to heal between battles!',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _getFitnessResponse() {
    debugPrint('AICompanionAgent: Getting fitness response');
    final responses = [
      'Walking and running count towards fitness goals!',
      'Complete fitness quests for bonus XP.',
      'Set daily step goals to stay motivated.',
      'Combine exercise with quest completion!',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _getCardResponse() {
    debugPrint('AICompanionAgent: Getting card response');
    final responses = [
      'Open card packs to get new equipment!',
      'Rare cards provide better stats.',
      'Equip cards to improve your character.',
      'Save premium packs for special occasions!',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _getCharacterResponse() {
    debugPrint('AICompanionAgent: Getting character response');
    final responses = [
      'Level up to unlock new abilities!',
      'Spend skill points wisely.',
      'Equip better gear to increase stats.',
      'Complete quests to gain experience!',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _getMapResponse() {
    debugPrint('AICompanionAgent: Getting map response');
    final responses = [
      'Explore new areas to discover quests!',
      'Use the map to find nearby points of interest.',
      'Some quests only appear in specific locations.',
      'Travel to unlock new adventure areas!',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _getGeneralResponse() {
    debugPrint('AICompanionAgent: Getting general response');
    final responses = [
      'I\'m here to help with your adventure!',
      'Ask me about quests, battles, or fitness goals.',
      'Explore the world to discover new content!',
      'Keep playing to unlock more features!',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  String _generateQuestTip(String questTitle, String questType) {
    debugPrint('AICompanionAgent: Generating quest tip for $questTitle ($questType)');
    return 'New quest available: $questTitle! This $questType quest will help you progress in your adventure.';
  }

  String _generateCompletionMessage(String questTitle, Map<String, dynamic>? rewards) {
    debugPrint('AICompanionAgent: Generating completion message for $questTitle');
    final rewardText = rewards != null ? ' You earned rewards!' : '';
    return 'Congratulations! You completed "$questTitle"!$rewardText';
  }

  String _generateBattleTip(String enemyName) {
    debugPrint('AICompanionAgent: Generating battle tip for $enemyName');
    return 'Battle against $enemyName has begun! Use your best strategy and equipment!';
  }

  String _generateBattleResult(String result, String enemyName) {
    debugPrint('AICompanionAgent: Generating battle result for $result against $enemyName');
    if (result == 'victory') {
      return 'Victory! You defeated $enemyName! Well done!';
    } else if (result == 'defeat') {
      return 'Defeat against $enemyName. Don\'t give up - try again with better preparation!';
    } else {
      return 'Battle with $enemyName ended. The result was $result.';
    }
  }

  String _generateFitnessTip(int steps, int goal) {
    debugPrint('AICompanionAgent: Generating fitness tip for $steps/$goal steps');
    return 'Amazing! You reached your daily step goal of $goal steps! Keep up the great work!';
  }

  String _generateAchievementTip(String achievementName) {
    debugPrint('AICompanionAgent: Generating achievement tip for $achievementName');
    return 'Achievement unlocked: $achievementName! Your dedication is paying off!';
  }

  String _generateCardTip(String cardName, String rarity) {
    debugPrint('AICompanionAgent: Generating card tip for $cardName ($rarity)');
    return 'You obtained $cardName! This $rarity card will be useful in your adventures.';
  }

  String _generateLevelUpTip(int newLevel) {
    debugPrint('AICompanionAgent: Generating level up tip for level $newLevel');
    return 'Congratulations! You reached level $newLevel! New abilities await!';
  }

  void _sendProactiveTip(String title, String message) {
    debugPrint('AICompanionAgent: Sending proactive tip - $title: $message');
    
    bus.publish(Event(
      type: 'companion.tip',
      data: {
        'title': title,
        'message': _applyPersonality(message),
        'personality': _personality.name,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
    
    _cooldownTicks = _cooldownDuration;
    debugPrint('AICompanionAgent: Cooldown set to $_cooldownTicks ticks');
  }

  String _applyPersonality(String message) {
    debugPrint('AICompanionAgent: Applying personality ${_personality.name} to message');
    
    switch (_personality) {
      case CompanionPersonality.friendly:
        return message;
      case CompanionPersonality.enthusiastic:
        return '🎉 $message 🎉';
      case CompanionPersonality.wisdom:
        return '💭 $message 💭';
      case CompanionPersonality.mysterious:
        return '🔮 $message 🔮';
    }
  }

  @override
  void onTick() {
    if (_cooldownTicks > 0) {
      _cooldownTicks--;
      debugPrint('AICompanionAgent: Cooldown tick: $_cooldownTicks remaining');
    }
  }

  @override
  Future<void> onDispose() async {
    debugPrint('AICompanionAgent: Disposing AI Companion Agent');
    _memory.clear();
  }
}
