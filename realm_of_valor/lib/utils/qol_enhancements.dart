/// Quality of Life Enhancements for Realm of Valor
/// 
/// This file contains all QOL improvements across the app:
/// - Smart notifications
/// - Auto-save system
/// - Offline queue
/// - Tutorial hints
/// - Accessibility features
/// - Performance optimizations

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QOLEnhancements {
  static final QOLEnhancements _instance = QOLEnhancements._internal();
  factory QOLEnhancements() => _instance;
  QOLEnhancements._internal();
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // QOL 1: SMART NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Show contextual hints based on player actions
  static void showContextualHint(BuildContext context, String hintType) {
    final hints = {
      'first_trail': '💡 Tip: Enable Drive Mode for hands-free trail tracking!',
      'first_enemy': '💡 Tip: Elite enemies (⭐) drop guaranteed rare items!',
      'first_zone': '💡 Tip: Stack multiple zones for massive reward bonuses!',
      'low_health': '⚠️ Tip: Visit a safe zone to restore health!',
      'combo_active': '🔥 Tip: Keep the combo going! Complete activities within 5 minutes!',
      'level_up': '🎉 Tip: Check your character screen for new abilities!',
    };
    
    final message = hints[hintType];
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // QOL 2: AUTO-SAVE SYSTEM
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Timer? _autoSaveTimer;
  final Map<String, dynamic> _pendingData = {};
  
  /// Start auto-save system (saves every 30 seconds)
  void startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performAutoSave();
    });
  }
  
  /// Queue data for auto-save
  void queueForSave(String key, dynamic value) {
    _pendingData[key] = value;
  }
  
  Future<void> _performAutoSave() async {
    if (_pendingData.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in _pendingData.entries) {
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
        } else if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value);
        } else if (entry.value is double) {
          await prefs.setDouble(entry.key, entry.value);
        }
      }
      _pendingData.clear();
      print('QOL: Auto-save completed (${_pendingData.length} items)');
    } catch (e) {
      print('QOL: Auto-save error: $e');
    }
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // QOL 3: OFFLINE QUEUE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  final List<Map<String, dynamic>> _offlineQueue = [];
  
  /// Queue action for when connection is restored
  void queueOfflineAction(String actionType, Map<String, dynamic> data) {
    _offlineQueue.add({
      'type': actionType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    print('QOL: Queued offline action: $actionType');
  }
  
  /// Process queued offline actions
  Future<void> processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    
    print('QOL: Processing ${_offlineQueue.length} offline actions...');
    
    for (final action in _offlineQueue) {
      try {
        // Process action (would integrate with actual services)
        print('QOL: Processing ${action['type']}');
        // await _processAction(action);
      } catch (e) {
        print('QOL: Error processing offline action: $e');
      }
    }
    
    _offlineQueue.clear();
    print('QOL: Offline queue processed');
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // QOL 4: SMART LOADING
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Show loading with progress
  static void showSmartLoading(
    BuildContext context,
    String message, {
    double? progress,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress != null) ...[
              CircularProgressIndicator(value: progress),
              const SizedBox(height: 16),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ] else ...[
              const CircularProgressIndicator(),
            ],
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // QOL 5: QUICK ACTIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Quick action bottom sheet
  static void showQuickActions(
    BuildContext context, {
    VoidCallback? onNavigateHome,
    VoidCallback? onToggleCamera,
    VoidCallback? onViewQuests,
    VoidCallback? onViewInventory,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Return Home'),
              onTap: () {
                Navigator.pop(context);
                onNavigateHome?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Toggle Camera Mode'),
              onTap: () {
                Navigator.pop(context);
                onToggleCamera?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('View Quests'),
              onTap: () {
                Navigator.pop(context);
                onViewQuests?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('View Inventory'),
              onTap: () {
                Navigator.pop(context);
                onViewInventory?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // QOL 6: REWARD PREVIEW
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Show reward preview before starting quest
  static void showRewardPreview(
    BuildContext context, {
    required int baseXP,
    required int baseGold,
    required List<String> items,
    double zoneMultiplier = 1.0,
    int comboMultiplier = 1,
  }) {
    final finalXP = (baseXP * zoneMultiplier * comboMultiplier).round();
    final finalGold = (baseGold * zoneMultiplier * comboMultiplier).round();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💰 Reward Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Base XP: $baseXP'),
            if (zoneMultiplier > 1.0)
              Text('Zone Bonus: x${zoneMultiplier.toStringAsFixed(1)}', 
                style: const TextStyle(color: Colors.blue)),
            if (comboMultiplier > 1)
              Text('Combo Bonus: x$comboMultiplier', 
                style: const TextStyle(color: Colors.orange)),
            const Divider(),
            Text('Final XP: $finalXP ⭐', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Final Gold: $finalGold 💰', 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...items.map((item) => Text('  • $item')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // QOL 7: ACCESSIBILITY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  /// Text scaling for better readability
  static double getAccessibleTextScale(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.textScaleFactor.clamp(0.8, 1.5);
  }
  
  /// High contrast mode detection
  static bool isHighContrastMode(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.highContrast;
  }
  
  /// Color-blind friendly palette
  static Color getAccessibleColor(String colorType, BuildContext context) {
    final isHighContrast = isHighContrastMode(context);
    
    if (isHighContrast) {
      switch (colorType) {
        case 'success': return Colors.green.shade900;
        case 'error': return Colors.red.shade900;
        case 'warning': return Colors.orange.shade900;
        case 'info': return Colors.blue.shade900;
        default: return Colors.black;
      }
    } else {
      switch (colorType) {
        case 'success': return Colors.green;
        case 'error': return Colors.red;
        case 'warning': return Colors.orange;
        case 'info': return Colors.blue;
        default: return Colors.grey;
      }
    }
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // QOL 8: PERFORMANCE MONITORING
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  final Map<String, DateTime> _performanceTimers = {};
  
  /// Start performance timer
  void startPerformanceTimer(String label) {
    _performanceTimers[label] = DateTime.now();
  }
  
  /// End performance timer and log
  void endPerformanceTimer(String label) {
    final start = _performanceTimers[label];
    if (start != null) {
      final duration = DateTime.now().difference(start);
      print('⏱️ Performance [$label]: ${duration.inMilliseconds}ms');
      _performanceTimers.remove(label);
    }
  }
  
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DISPOSE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  void dispose() {
    _autoSaveTimer?.cancel();
    _pendingData.clear();
    _offlineQueue.clear();
    _performanceTimers.clear();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QOL 9: SMART CACHING
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class SmartCache<T> {
  final Map<String, CacheEntry<T>> _cache = {};
  final Duration maxAge;
  final int maxSize;
  
  SmartCache({
    this.maxAge = const Duration(minutes: 5),
    this.maxSize = 100,
  });
  
  /// Get cached value
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check if expired
    if (DateTime.now().difference(entry.timestamp) > maxAge) {
      _cache.remove(key);
      return null;
    }
    
    // Update access time
    entry.lastAccessed = DateTime.now();
    return entry.value;
  }
  
  /// Set cached value
  void set(String key, T value) {
    // Evict old entries if cache is full
    if (_cache.length >= maxSize) {
      _evictOldest();
    }
    
    _cache[key] = CacheEntry(
      value: value,
      timestamp: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
  }
  
  /// Evict oldest entry
  void _evictOldest() {
    DateTime? oldest;
    String? oldestKey;
    
    for (final entry in _cache.entries) {
      if (oldest == null || entry.value.lastAccessed.isBefore(oldest)) {
        oldest = entry.value.lastAccessed;
        oldestKey = entry.key;
      }
    }
    
    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }
  
  /// Clear cache
  void clear() {
    _cache.clear();
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime timestamp;
  DateTime lastAccessed;
  
  CacheEntry({
    required this.value,
    required this.timestamp,
    required this.lastAccessed,
  });
}
