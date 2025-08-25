import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/achievement_model.dart';
import 'achievement_system.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  AchievementCategory? _selectedCategory;
  AchievementRarity? _selectedRarity;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider);
    final unlockedAchievements = ref.watch(unlockedAchievementsProvider);
    final totalPoints = ref.watch(achievementPointsProvider);
    final progress = ref.watch(achievementProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Achievement Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Unlocked',
                    '${unlockedAchievements.length}/${achievements.length}',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Points',
                    '$totalPoints',
                    Icons.stars,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Progress',
                    '${((unlockedAchievements.length / achievements.length) * 100).round()}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search achievements...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Active Filters
          if (_selectedCategory != null || _selectedRarity != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                children: [
                  if (_selectedCategory != null)
                    Chip(
                      label: Text(_selectedCategory!.name),
                      onDeleted: () => setState(() => _selectedCategory = null),
                    ),
                  if (_selectedRarity != null)
                    Chip(
                      label: Text(_selectedRarity!.name),
                      onDeleted: () => setState(() => _selectedRarity = null),
                    ),
                ],
              ),
            ),

          // Achievements List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final isUnlocked = achievement.isUnlocked;
                final achievementProgress = progress[achievement.id] ?? 0.0;

                // Apply filters
                if (_selectedCategory != null && achievement.category != _selectedCategory) {
                  return const SizedBox.shrink();
                }
                if (_selectedRarity != null && achievement.rarity != _selectedRarity) {
                  return const SizedBox.shrink();
                }
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  if (!achievement.name.toLowerCase().contains(query) &&
                      !achievement.description.toLowerCase().contains(query)) {
                    return const SizedBox.shrink();
                  }
                }

                return _buildAchievementCard(achievement, isUnlocked, achievementProgress);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked, double progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    _getRarityColor(achievement.rarity).withOpacity(0.1),
                    _getRarityColor(achievement.rarity).withOpacity(0.05),
                  ]
                : [
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.05),
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Achievement Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? _getRarityColor(achievement.rarity).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    achievement.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Achievement Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? null : Colors.grey[600],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRarityColor(achievement.rarity),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${achievement.points} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnlocked ? null : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          achievement.categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (isUnlocked)
                          const Icon(Icons.check_circle, color: Colors.green, size: 16)
                        else
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    if (!isUnlocked) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_getRarityColor(achievement.rarity)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
      case AchievementRarity.mythic:
        return Colors.yellow.shade700;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Achievements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Filter
            DropdownButtonFormField<AchievementCategory?>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Categories')),
                ...AchievementCategory.values.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.name),
                )),
              ],
              onChanged: (value) => setState(() => _selectedCategory = value),
            ),
            const SizedBox(height: 16),
            // Rarity Filter
            DropdownButtonFormField<AchievementRarity?>(
              value: _selectedRarity,
              decoration: const InputDecoration(labelText: 'Rarity'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Rarities')),
                ...AchievementRarity.values.map((rarity) => DropdownMenuItem(
                  value: rarity,
                  child: Text(rarity.name),
                )),
              ],
              onChanged: (value) => setState(() => _selectedRarity = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
