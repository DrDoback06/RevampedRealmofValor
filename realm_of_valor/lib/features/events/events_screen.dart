import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/event_model.dart';
import 'providers.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final eventStats = ref.watch(eventStatsProvider);
    final userParticipations = ref.watch(userActiveParticipationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(eventRefreshProvider.notifier).state = DateTime.now();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Stats
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active',
                    '${eventStats['active_events']}',
                    Icons.event_available,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Upcoming',
                    '${eventStats['upcoming_events']}',
                    Icons.event_note,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Participated',
                    '${eventStats['user_participated']}',
                    Icons.person,
                    Colors.orange,
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
                hintText: 'Search events...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(eventSearchProvider.notifier).state = value;
              },
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.grey[50],
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('All Events', 0),
                ),
                Expanded(
                  child: _buildTabButton('Active', 1),
                ),
                Expanded(
                  child: _buildTabButton('Upcoming', 2),
                ),
                Expanded(
                  child: _buildTabButton('My Events', 3),
                ),
              ],
            ),
          ),

          // Events List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(eventRefreshProvider.notifier).state = DateTime.now();
              },
              child: _buildEventsList(),
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

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    List<GameEvent> events;
    
    switch (_selectedTabIndex) {
      case 0:
        events = ref.watch(searchedEventsProvider);
        break;
      case 1:
        events = ref.watch(activeEventsProvider);
        break;
      case 2:
        events = ref.watch(upcomingEventsProvider);
        break;
      case 3:
        events = ref.watch(userEventsProvider);
        break;
      default:
        events = ref.watch(searchedEventsProvider);
    }

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(GameEvent event) {
    final isParticipating = ref.watch(userActiveParticipationsProvider)
        .any((participation) => participation.eventId == event.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getEventGradientColor(event.type).withOpacity(0.1),
              _getEventGradientColor(event.type).withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              Row(
                children: [
                  Text(
                    event.typeIcon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(event.difficulty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.difficulty.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Event Details
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatEventTime(event),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (event.isLocationBased) ...[
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      event.location ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Participants
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${event.participants?.length ?? 0}/${event.maxParticipants}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (event.isFull)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'FULL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Rewards Preview
              if (event.rewards != null) ...[
                Text(
                  'Rewards:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: event.rewards!.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      backgroundColor: Colors.grey[200],
                      labelStyle: const TextStyle(fontSize: 10),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showEventDetails(event),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isParticipating ? null : () => _joinEvent(event),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isParticipating ? Colors.grey : null,
                      ),
                      child: Text(isParticipating ? 'Joined' : 'Join'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventGradientColor(EventType type) {
    switch (type) {
      case EventType.battle:
        return Colors.red;
      case EventType.quest:
        return Colors.blue;
      case EventType.social:
        return Colors.green;
      case EventType.fitness:
        return Colors.orange;
      case EventType.achievement:
        return Colors.purple;
      case EventType.weather:
        return Colors.cyan;
      case EventType.seasonal:
        return Colors.pink;
      case EventType.special:
        return Colors.amber;
    }
  }

  Color _getDifficultyColor(EventDifficulty difficulty) {
    switch (difficulty) {
      case EventDifficulty.easy:
        return Colors.green;
      case EventDifficulty.medium:
        return Colors.orange;
      case EventDifficulty.hard:
        return Colors.red;
      case EventDifficulty.extreme:
        return Colors.purple;
    }
  }

  String _formatEventTime(GameEvent event) {
    final now = DateTime.now();
    final startTime = event.startTime;
    final endTime = event.endTime;
    
    if (event.isActive) {
      final remaining = endTime.difference(now);
      if (remaining.inDays > 0) {
        return '${remaining.inDays}d ${remaining.inHours % 24}h remaining';
      } else if (remaining.inHours > 0) {
        return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
      } else {
        return '${remaining.inMinutes}m remaining';
      }
    } else if (event.isUpcoming) {
      final untilStart = startTime.difference(now);
      if (untilStart.inDays > 0) {
        return 'Starts in ${untilStart.inDays}d ${untilStart.inHours % 24}h';
      } else if (untilStart.inHours > 0) {
        return 'Starts in ${untilStart.inHours}h ${untilStart.inMinutes % 60}m';
      } else {
        return 'Starts in ${untilStart.inMinutes}m';
      }
    } else {
      return '${startTime.day}/${startTime.month} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showEventDetails(GameEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EventDetailsSheet(event: event),
    );
  }

  void _joinEvent(GameEvent event) {
    // In a real app, this would call an API to join the event
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined ${event.name}!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type Filter
            DropdownButtonFormField<EventType?>(
              value: ref.read(eventFilterProvider)['type'],
              decoration: const InputDecoration(labelText: 'Event Type'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...EventType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                )),
              ],
              onChanged: (value) {
                final currentFilter = ref.read(eventFilterProvider);
                ref.read(eventFilterProvider.notifier).state = {
                  ...currentFilter,
                  'type': value,
                };
              },
            ),
            const SizedBox(height: 16),
            // Difficulty Filter
            DropdownButtonFormField<EventDifficulty?>(
              value: ref.read(eventFilterProvider)['difficulty'],
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Difficulties')),
                ...EventDifficulty.values.map((difficulty) => DropdownMenuItem(
                  value: difficulty,
                  child: Text(difficulty.name),
                )),
              ],
              onChanged: (value) {
                final currentFilter = ref.read(eventFilterProvider);
                ref.read(eventFilterProvider.notifier).state = {
                  ...currentFilter,
                  'difficulty': value,
                };
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(eventFilterProvider.notifier).state = {
                'type': null,
                'difficulty': null,
                'status': null,
                'location_based': false,
                'user_eligible': false,
              };
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _EventDetailsSheet extends ConsumerWidget {
  final GameEvent event;

  const _EventDetailsSheet({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(eventLeaderboardProvider(event.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Header
                      Row(
                        children: [
                          Text(
                            event.typeIcon,
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  event.description,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Event Details
                      _buildDetailSection('Event Details', [
                        _buildDetailRow('Status', event.status.name),
                        _buildDetailRow('Difficulty', event.difficulty.name),
                        _buildDetailRow('Start Time', _formatDateTime(event.startTime)),
                        _buildDetailRow('End Time', _formatDateTime(event.endTime)),
                        _buildDetailRow('Duration', _formatDuration(event.duration)),
                        if (event.location != null)
                          _buildDetailRow('Location', event.location!),
                        if (event.isLocationBased)
                          _buildDetailRow('Radius', '${event.radius}m'),
                        _buildDetailRow('Participants', '${event.participants?.length ?? 0}/${event.maxParticipants}'),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Requirements
                      if (event.requirements != null) ...[
                        _buildDetailSection('Requirements', [
                          ...event.requirements!.entries.map((entry) =>
                            _buildDetailRow(entry.key, entry.value.toString()),
                          ),
                        ]),
                        const SizedBox(height: 24),
                      ],
                      
                      // Rewards
                      if (event.rewards != null) ...[
                        _buildDetailSection('Rewards', [
                          ...event.rewards!.entries.map((entry) =>
                            _buildDetailRow(entry.key, entry.value.toString()),
                          ),
                        ]),
                        const SizedBox(height: 24),
                      ],
                      
                      // Leaderboard
                      _buildDetailSection('Leaderboard', [
                        ...leaderboard.topEntries.take(5).map((entry) =>
                          _buildDetailRow(
                            '#${entry.rank} ${entry.username}',
                            '${entry.score} pts',
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} days';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours';
    } else {
      return '${duration.inMinutes} minutes';
    }
  }
}
