import 'package:flutter/material.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/models/trail_model.dart';
import '../../../services/repeatable_quest_service.dart';
import 'package:intl/intl.dart';

/// Quest Completion History Widget
/// 
/// Shows previously completed quests with:
/// - Completion count
/// - First/last completion dates
/// - Current streak
/// - Best streak
/// - Repeat button
/// - Stats and badges

class QuestCompletionHistory extends StatelessWidget {
  final RepeatableQuestService questService;
  final List<Quest> completedQuests;
  final Function(Quest) onRepeatQuest;

  const QuestCompletionHistory({
    super.key,
    required this.questService,
    required this.completedQuests,
    required this.onRepeatQuest,
  });

  @override
  Widget build(BuildContext context) {
    if (completedQuests.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildCompletionList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Completed Trails',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Chip(
            label: Text('${completedQuests.length} trails'),
            backgroundColor: Colors.green.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: completedQuests.length,
      itemBuilder: (context, index) {
        final quest = completedQuests[index];
        return _buildCompletionCard(quest);
      },
    );
  }

  Widget _buildCompletionCard(Quest quest) {
    final stats = questService.getCompletionStats(quest.id);
    final completionCount = stats['total_completions'] as int;
    final currentStreak = stats['current_streak'] as int;
    final bestStreak = stats['best_streak'] as int;
    final lastCompleted = stats['last_completed'] as DateTime?;
    
    final canRepeat = questService.canRepeatQuest(quest.id, 'trail');
    final timeUntilRepeat = questService.getTimeUntilRepeat(quest.id, 'trail');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: _buildTrailIcon(quest),
        title: Text(
          quest.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text('$completionCount completions'),
                const SizedBox(width: 16),
                if (currentStreak > 0) ...[
                  Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('$currentStreak day streak'),
                ],
              ],
            ),
            if (lastCompleted != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last: ${_formatDate(lastCompleted)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        trailing: _buildRepeatButton(quest, canRepeat, timeUntilRepeat),
        children: [
          _buildExpandedStats(quest, stats),
        ],
      ),
    );
  }

  Widget _buildTrailIcon(Quest quest) {
    // Get difficulty from tags
    final difficultyTag = quest.tags.firstWhere(
      (tag) => tag.startsWith('trail_difficulty:'),
      orElse: () => 'trail_difficulty:moderate',
    );
    final difficulty = difficultyTag.split(':')[1];
    
    Color color;
    switch (difficulty) {
      case 'easy':
        color = Colors.green;
        break;
      case 'moderate':
        color = Colors.blue;
        break;
      case 'hard':
        color = Colors.orange;
        break;
      case 'expert':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.hiking, color: color),
    );
  }

  Widget _buildRepeatButton(Quest quest, bool canRepeat, Duration? timeUntilRepeat) {
    if (canRepeat) {
      return ElevatedButton.icon(
        onPressed: () => onRepeatQuest(quest),
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Repeat'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    } else if (timeUntilRepeat != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_formatDuration(timeUntilRepeat)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }
    
    return const SizedBox();
  }

  Widget _buildExpandedStats(Quest quest, Map<String, dynamic> stats) {
    final completionCount = stats['total_completions'] as int;
    final currentStreak = stats['current_streak'] as int;
    final bestStreak = stats['best_streak'] as int;
    final firstCompleted = stats['first_completed'] as DateTime?;
    
    // Calculate next rewards
    final nextRewards = questService.calculateScaledRewards(
      originalQuest: quest,
      completionNumber: completionCount + 1,
    );
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          _buildStatRow('Total Completions', '$completionCount'),
          _buildStatRow('Current Streak', '$currentStreak days'),
          _buildStatRow('Best Streak', '$bestStreak days'),
          if (firstCompleted != null)
            _buildStatRow('First Completed', _formatDate(firstCompleted)),
          
          const Divider(height: 24),
          
          // Next completion rewards
          const Text(
            'Next Completion Rewards',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRewardChip(Icons.stars, '${nextRewards.xp} XP', Colors.blue),
              const SizedBox(width: 8),
              _buildRewardChip(Icons.monetization_on, '${nextRewards.gold} Gold', Colors.amber),
            ],
          ),
          
          // Milestone info
          if (_getNextMilestone(completionCount) != null) ...[
            const SizedBox(height: 12),
            _buildMilestoneInfo(completionCount),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneInfo(int completionCount) {
    final milestone = _getNextMilestone(completionCount);
    if (milestone == null) return const SizedBox();
    
    final remaining = milestone - completionCount;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Milestone: $milestone completions',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$remaining more to go! Bonus rewards await!',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int? _getNextMilestone(int current) {
    const milestones = [10, 25, 50, 100];
    for (final milestone in milestones) {
      if (current < milestone) return milestone;
    }
    return null;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hiking, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Completed Trails Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your first trail to see it here!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
