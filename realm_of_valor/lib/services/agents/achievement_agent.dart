import '../../data/models/achievement_model.dart';
import '../base_agent.dart';
import '../event_bus.dart';

class AchievementAgent extends BaseAgent {
  AchievementAgent(super.bus, {required List<Achievement> achievements}) : _achievements = achievements;

  final List<Achievement> _achievements;
  final Map<String, AchievementProgress> _progress = <String, AchievementProgress>{};

  @override
  String get name => 'Achievement';

  @override
  Future<void> onInitialize() async {
    for (final achievement in _achievements) {
      _progress[achievement.id] = AchievementProgress(
        achievementId: achievement.id,
        currentProgress: {},
        completionPercentage: 0.0,
        isCompleted: false,
      );
      // Subscribe to relevant events based on achievement category
      _subscribeToEvents(achievement);
    }
  }

  @override
  Future<void> onDispose() async {}

  void _subscribeToEvents(Achievement achievement) {
    switch (achievement.category) {
      case AchievementCategory.battle:
        bus.subscribe('battle.ended', (evt, b) => _handleBattleEvent(achievement, evt));
        break;
      case AchievementCategory.quest:
        bus.subscribe('quest.completed', (evt, b) => _handleQuestEvent(achievement, evt));
        break;
      case AchievementCategory.fitness:
        bus.subscribe('fitness.goal_reached', (evt, b) => _handleFitnessEvent(achievement, evt));
        break;
      case AchievementCategory.collection:
        bus.subscribe('card_collected', (evt, b) => _handleCollectionEvent(achievement, evt));
        break;
      default:
        // Subscribe to general events
        bus.subscribe('achievement_progress', (evt, b) => _handleGeneralEvent(achievement, evt));
    }
  }

  void _handleBattleEvent(Achievement achievement, Event evt) {
    _updateProgress(achievement, evt);
  }

  void _handleQuestEvent(Achievement achievement, Event evt) {
    _updateProgress(achievement, evt);
  }

  void _handleFitnessEvent(Achievement achievement, Event evt) {
    _updateProgress(achievement, evt);
  }

  void _handleCollectionEvent(Achievement achievement, Event evt) {
    _updateProgress(achievement, evt);
  }

  void _handleGeneralEvent(Achievement achievement, Event evt) {
    _updateProgress(achievement, evt);
  }

  void _updateProgress(Achievement achievement, Event evt) {
    final prog = _progress[achievement.id];
    if (prog == null || prog.isCompleted) return;

    // Update progress based on achievement requirements
    final currentProgress = Map<String, int>.from(prog.currentProgress);
    final eventType = evt.type;
    
    // Increment progress for this event type
    currentProgress[eventType] = (currentProgress[eventType] ?? 0) + 1;
    
    // Calculate completion percentage
    final totalRequired = achievement.requirements?.values.fold(0, (sum, value) => sum + value) ?? 1;
    final currentTotal = currentProgress.values.fold(0, (sum, value) => sum + value);
    final completionPercentage = (currentTotal / totalRequired).clamp(0.0, 1.0);
    
    // Check if achievement is completed
    final isCompleted = completionPercentage >= 1.0;
    
    // Update progress
    _progress[achievement.id] = AchievementProgress(
      achievementId: achievement.id,
      currentProgress: currentProgress,
      completionPercentage: completionPercentage,
      isCompleted: isCompleted,
    );
    
    // If achievement is completed, publish event
    if (isCompleted) {
      bus.publish(Event(type: 'achievement.unlocked', data: {
        'id': achievement.id,
        'name': achievement.name,
        'points': achievement.points,
      }));
    }
  }
}
