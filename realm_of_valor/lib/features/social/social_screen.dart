import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/user_model.dart';
import '../../../services/event_bus.dart';
import '../../../core/di.dart';
import '../auth/providers.dart';

// Custom User class for social features
class SocialUser {
  final String uid;
  final String email;
  final String displayName;
  final int level;
  final bool isOnline;
  final DateTime lastSeen;

  SocialUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.level,
    required this.isOnline,
    required this.lastSeen,
  });
}

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  int _currentIndex = 0;
  final List<String> _activityLog = [];
  final List<SocialPost> _posts = [];
  final List<Guild> _guilds = [];
  final List<SocialUser> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // Mock guilds
    _guilds.addAll([
      Guild(
        id: 'guild_1',
        name: 'Dragon Slayers',
        description: 'Elite guild focused on defeating powerful dragons',
        memberCount: 25,
        maxMembers: 50,
        level: 15,
        leader: 'DragonMaster',
        isMember: true,
      ),
      Guild(
        id: 'guild_2',
        name: 'Adventure Seekers',
        description: 'Casual guild for exploring and questing together',
        memberCount: 12,
        maxMembers: 30,
        level: 8,
        leader: 'Explorer',
        isMember: false,
      ),
    ]);

    // Mock friends
    _friends.addAll([
      SocialUser(
        uid: 'friend_1',
        email: 'warrior@example.com',
        displayName: 'IronWarrior',
        level: 12,
        isOnline: true,
        lastSeen: DateTime.now(),
      ),
      SocialUser(
        uid: 'friend_2',
        email: 'mage@example.com',
        displayName: 'FireMage',
        level: 18,
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ]);

    // Mock posts
    _posts.addAll([
      SocialPost(
        id: 'post_1',
        authorId: 'friend_1',
        authorName: 'IronWarrior',
        content: 'Just defeated a level 15 dragon! 🐉⚔️',
        type: PostType.achievement,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        likes: 5,
        comments: 2,
        imageUrl: null,
      ),
      SocialPost(
        id: 'post_2',
        authorId: 'friend_2',
        authorName: 'FireMage',
        content: 'Found a rare magic scroll in the ancient library 📚✨',
        type: PostType.discovery,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        likes: 8,
        comments: 3,
        imageUrl: null,
      ),
    ]);
  }

  void _addToLog(String message) {
    setState(() {
      _activityLog.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_activityLog.length > 50) {
        _activityLog.removeAt(0);
      }
    });
  }

  void _createPost() {
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'What\'s happening?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Post Type:'),
                const SizedBox(width: 8),
                DropdownButton<PostType>(
                  value: PostType.activity,
                  items: PostType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {},
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (contentController.text.isNotEmpty) {
                _submitPost(contentController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _submitPost(String content) {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    final post = SocialPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorId: currentUser.uid,
      authorName: currentUser.displayName ?? 'Adventurer',
      content: content,
      type: PostType.activity,
      timestamp: DateTime.now(),
      likes: 0,
      comments: 0,
      imageUrl: null,
    );

    setState(() {
      _posts.insert(0, post);
    });

    _addToLog('Created new post: ${content.substring(0, content.length > 30 ? 30 : content.length)}...');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post created successfully!')),
    );
  }

  void _likePost(String postId) {
    setState(() {
      final post = _posts.firstWhere((p) => p.id == postId);
      post.likes++;
    });
    _addToLog('Liked a post');
  }

  void _joinGuild(Guild guild) {
    setState(() {
      guild.isMember = true;
      guild.memberCount++;
    });
    _addToLog('Joined guild: ${guild.name}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined ${guild.name}!')),
    );
  }

  void _leaveGuild(Guild guild) {
    setState(() {
      guild.isMember = false;
      guild.memberCount--;
    });
    _addToLog('Left guild: ${guild.name}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Left ${guild.name}')),
    );
  }

  void _addFriend() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Friend\'s Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                _sendFriendRequest(emailController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _sendFriendRequest(String email) {
    _addToLog('Sent friend request to: $email');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to $email')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createPost,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                _buildTabButton(0, 'Feed', Icons.rss_feed),
                _buildTabButton(1, 'Guilds', Icons.group),
                _buildTabButton(2, 'Friends', Icons.people),
                _buildTabButton(3, 'Activity', Icons.timeline),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildFeedTab(),
                _buildGuildsTab(),
                _buildFriendsTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(post.authorName[0]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatTimestamp(post.timestamp),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _getPostTypeIcon(post.type),
                      color: _getPostTypeColor(post.type),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(post.content),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up),
                      onPressed: () => _likePost(post.id),
                    ),
                    Text('${post.likes}'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.comment),
                      onPressed: () {},
                    ),
                    Text('${post.comments}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuildsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _guilds.length,
      itemBuilder: (context, index) {
        final guild = _guilds[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: guild.isMember ? Colors.green : Colors.grey,
                      child: Icon(
                        Icons.group,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guild.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Level ${guild.level} • ${guild.memberCount}/${guild.maxMembers} members',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (guild.isMember)
                      ElevatedButton(
                        onPressed: () => _leaveGuild(guild),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Leave'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _joinGuild(guild),
                        child: const Text('Join'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(guild.description),
                const SizedBox(height: 8),
                Text(
                  'Leader: ${guild.leader}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addFriend,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Friend'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _friends.length,
            itemBuilder: (context, index) {
              final friend = _friends[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: friend.isOnline ? Colors.green : Colors.grey,
                    child: Text(friend.displayName[0]),
                  ),
                  title: Text(friend.displayName),
                  subtitle: Text(
                    friend.isOnline 
                        ? 'Online • Level ${friend.level}'
                        : 'Last seen ${_formatTimestamp(friend.lastSeen)} • Level ${friend.level}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.person),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _activityLog.clear();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _activityLog.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _activityLog[index],
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  IconData _getPostTypeIcon(PostType type) {
    switch (type) {
      case PostType.activity:
        return Icons.directions_run;
      case PostType.achievement:
        return Icons.emoji_events;
      case PostType.discovery:
        return Icons.explore;
      case PostType.battle:
        return Icons.sports_kabaddi;
    }
  }

  Color _getPostTypeColor(PostType type) {
    switch (type) {
      case PostType.activity:
        return Colors.blue;
      case PostType.achievement:
        return Colors.amber;
      case PostType.discovery:
        return Colors.green;
      case PostType.battle:
        return Colors.red;
    }
  }
}

enum PostType {
  activity,
  achievement,
  discovery,
  battle;

  String get displayName {
    switch (this) {
      case PostType.activity:
        return 'Activity';
      case PostType.achievement:
        return 'Achievement';
      case PostType.discovery:
        return 'Discovery';
      case PostType.battle:
        return 'Battle';
    }
  }
}

class SocialPost {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final PostType type;
  final DateTime timestamp;
  int likes;
  int comments;
  final String? imageUrl;

  SocialPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.likes,
    required this.comments,
    this.imageUrl,
  });
}

class Guild {
  final String id;
  final String name;
  final String description;
  int memberCount;
  final int maxMembers;
  final int level;
  final String leader;
  bool isMember;

  Guild({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.maxMembers,
    required this.level,
    required this.leader,
    required this.isMember,
  });
}
