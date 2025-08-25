import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'providers.dart';
import '../../../data/models/quest_model.dart';

class QuestListScreen extends ConsumerStatefulWidget {
  const QuestListScreen({super.key});

  @override
  ConsumerState<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends ConsumerState<QuestListScreen> {
  final List<String> _debugLog = [];

  void _logDebug(String message) {
    final timestamp = DateTime.now().toString().split('.')[0];
    final logMessage = '[$timestamp] QuestListScreen: $message';
    debugPrint(logMessage);
    setState(() {
      _debugLog.add(logMessage);
      if (_debugLog.length > 20) {
        _debugLog.removeAt(0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _logDebug('QuestListScreen initialized');
  }

  @override
  Widget build(BuildContext context) {
    _logDebug('Building QuestListScreen');
    
    final questsAsync = ref.watch(questsStreamProvider);
    final questActions = ref.read(questActionsProvider);

    _logDebug('Quests loaded: ${questsAsync.hasValue}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _logDebug('Adding random quest');
              _addRandomQuest(questActions);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug Panel
          if (_debugLog.isNotEmpty)
            Container(
              height: 120,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quest Debug Log',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _debugLog.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _debugLog.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _debugLog[index],
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: questsAsync.when(
              data: (quests) {
                _logDebug('Displaying ${quests.length} quests');
                
                if (quests.isEmpty) {
                  _logDebug('No quests available');
                  return const Center(
                    child: Text('No quests available. Add some quests to get started!'),
                  );
                }

                return ListView.builder(
                  itemCount: quests.length,
                  itemBuilder: (context, index) {
                    final quest = quests[index];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(quest.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(quest.description),
                            const SizedBox(height: 8),
                            ...quest.objectives.map((objective) => 
                              Row(
                                children: [
                                  Icon(
                                    objective.progress >= objective.target 
                                        ? Icons.check_circle 
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: objective.progress >= objective.target 
                                        ? Colors.green 
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${objective.description} (${objective.progress}/${objective.target})',
                                      style: TextStyle(
                                        color: objective.progress >= objective.target 
                                            ? Colors.green 
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: [
                                Chip(
                                  label: Text('${quest.type.name}'),
                                  backgroundColor: _getQuestTypeColor(quest.type.name),
                                ),
                                                                 if (quest.rewards.xp > 0)
                                   Chip(
                                     label: Text('${quest.rewards.xp} XP'),
                                     backgroundColor: Colors.amber[100],
                                   ),
                                if (quest.rewards.gold > 0)
                                  Chip(
                                    label: Text('${quest.rewards.gold} Gold'),
                                    backgroundColor: Colors.yellow[100],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            _logDebug('Quest action selected: $value for quest ${quest.title}');
                            _handleQuestAction(value, quest, questActions);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'complete',
                              child: Text('Complete Quest'),
                            ),
                            const PopupMenuItem(
                              value: 'abandon',
                              child: Text('Abandon Quest'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () {
                _logDebug('Quests loading...');
                return const Center(child: CircularProgressIndicator());
              },
              error: (error, stack) {
                _logDebug('Quests error: $error');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading quests: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _logDebug('Retrying quests load');
                          ref.invalidate(questsStreamProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getQuestTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'main':
        return Colors.red[100]!;
      case 'adventure':
        return Colors.blue[100]!;
      case 'side':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  void _addRandomQuest(QuestActions questActions) {
    _logDebug('Adding random quest');
    questActions.addSideQuest();
  }

  void _handleQuestAction(String action, dynamic quest, QuestActions questActions) {
    _logDebug('Handling quest action: $action for quest ${quest.title}');
    
    switch (action) {
      case 'complete':
        _logDebug('Completing quest: ${quest.title}');
        questActions.completeQuest(quest.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest completed: ${quest.title}'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'abandon':
        _logDebug('Abandoning quest: ${quest.title}');
        questActions.abandonQuest(quest.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest abandoned: ${quest.title}'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
    }
  }
}

