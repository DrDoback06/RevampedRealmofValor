import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/battle_models.dart';

class PlayerStatistics {
  final String playerId;
  final String playerName;
  final int totalBattles;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;
  final int totalDamageDealt;
  final int totalDamageReceived;
  final int totalHealingDone;
  final int totalCardsPlayed;
  final int totalSpecialAbilitiesUsed;
  final Duration totalBattleTime;
  final int currentStreak;
  final int longestStreak;
  final int rank;
  final int experience;
  final int level;
  final Map<String, dynamic> achievements;
  final List<String> favoriteCards;
  final Map<String, int> cardUsageStats;
  final DateTime lastBattleTime;
  final DateTime createdAt;

  PlayerStatistics({
    required this.playerId,
    required this.playerName,
    required this.totalBattles,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.totalDamageDealt,
    required this.totalDamageReceived,
    required this.totalHealingDone,
    required this.totalCardsPlayed,
    required this.totalSpecialAbilitiesUsed,
    required this.totalBattleTime,
    required this.currentStreak,
    required this.longestStreak,
    required this.rank,
    required this.experience,
    required this.level,
    required this.achievements,
    required this.favoriteCards,
    required this.cardUsageStats,
    required this.lastBattleTime,
    required this.createdAt,
  });

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) {
    return PlayerStatistics(
      playerId: json['playerId'],
      playerName: json['playerName'],
      totalBattles: json['totalBattles'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
      winRate: json['winRate']?.toDouble() ?? 0.0,
      totalDamageDealt: json['totalDamageDealt'] ?? 0,
      totalDamageReceived: json['totalDamageReceived'] ?? 0,
      totalHealingDone: json['totalHealingDone'] ?? 0,
      totalCardsPlayed: json['totalCardsPlayed'] ?? 0,
      totalSpecialAbilitiesUsed: json['totalSpecialAbilitiesUsed'] ?? 0,
      totalBattleTime: Duration(milliseconds: json['totalBattleTimeMs'] ?? 0),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      rank: json['rank'] ?? 0,
      experience: json['experience'] ?? 0,
      level: json['level'] ?? 1,
      achievements: Map<String, dynamic>.from(json['achievements'] ?? {}),
      favoriteCards: List<String>.from(json['favoriteCards'] ?? []),
      cardUsageStats: Map<String, int>.from(json['cardUsageStats'] ?? {}),
      lastBattleTime: DateTime.parse(json['lastBattleTime']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'totalBattles': totalBattles,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'winRate': winRate,
      'totalDamageDealt': totalDamageDealt,
      'totalDamageReceived': totalDamageReceived,
      'totalHealingDone': totalHealingDone,
      'totalCardsPlayed': totalCardsPlayed,
      'totalSpecialAbilitiesUsed': totalSpecialAbilitiesUsed,
      'totalBattleTimeMs': totalBattleTime.inMilliseconds,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'rank': rank,
      'experience': experience,
      'level': level,
      'achievements': achievements,
      'favoriteCards': favoriteCards,
      'cardUsageStats': cardUsageStats,
      'lastBattleTime': lastBattleTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PlayerStatistics copyWith({
    String? playerId,
    String? playerName,
    int? totalBattles,
    int? wins,
    int? losses,
    int? draws,
    double? winRate,
    int? totalDamageDealt,
    int? totalDamageReceived,
    int? totalHealingDone,
    int? totalCardsPlayed,
    int? totalSpecialAbilitiesUsed,
    Duration? totalBattleTime,
    int? currentStreak,
    int? longestStreak,
    int? rank,
    int? experience,
    int? level,
    Map<String, dynamic>? achievements,
    List<String>? favoriteCards,
    Map<String, int>? cardUsageStats,
    DateTime? lastBattleTime,
    DateTime? createdAt,
  }) {
    return PlayerStatistics(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      totalBattles: totalBattles ?? this.totalBattles,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      winRate: winRate ?? this.winRate,
      totalDamageDealt: totalDamageDealt ?? this.totalDamageDealt,
      totalDamageReceived: totalDamageReceived ?? this.totalDamageReceived,
      totalHealingDone: totalHealingDone ?? this.totalHealingDone,
      totalCardsPlayed: totalCardsPlayed ?? this.totalCardsPlayed,
      totalSpecialAbilitiesUsed: totalSpecialAbilitiesUsed ?? this.totalSpecialAbilitiesUsed,
      totalBattleTime: totalBattleTime ?? this.totalBattleTime,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      rank: rank ?? this.rank,
      experience: experience ?? this.experience,
      level: level ?? this.level,
      achievements: achievements ?? this.achievements,
      favoriteCards: favoriteCards ?? this.favoriteCards,
      cardUsageStats: cardUsageStats ?? this.cardUsageStats,
      lastBattleTime: lastBattleTime ?? this.lastBattleTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get totalMatches => wins + losses + draws;
  double get averageDamagePerBattle => totalBattles > 0 ? totalDamageDealt / totalBattles : 0.0;
  double get averageDamageReceivedPerBattle => totalBattles > 0 ? totalDamageReceived / totalBattles : 0.0;
  double get averageHealingPerBattle => totalBattles > 0 ? totalHealingDone / totalBattles : 0.0;
  double get averageCardsPerBattle => totalBattles > 0 ? totalCardsPlayed / totalBattles : 0.0;
  Duration get averageBattleTime => totalBattles > 0 ? Duration(milliseconds: totalBattleTime.inMilliseconds ~/ totalBattles) : Duration.zero;
}

class Leaderboard {
  final String id;
  final String name;
  final String description;
  final LeaderboardType type;
  final List<LeaderboardEntry> entries;
  final DateTime lastUpdated;
  final int maxEntries;
  final Map<String, dynamic> criteria;

  Leaderboard({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.entries,
    required this.lastUpdated,
    required this.maxEntries,
    required this.criteria,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: LeaderboardType.values.firstWhere((e) => e.name == json['type']),
      entries: (json['entries'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      maxEntries: json['maxEntries'],
      criteria: Map<String, dynamic>.from(json['criteria']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'entries': entries.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'maxEntries': maxEntries,
      'criteria': criteria,
    };
  }

  List<LeaderboardEntry> get topEntries => entries.take(maxEntries).toList();
}

enum LeaderboardType {
  wins,
  winRate,
  damageDealt,
  damageReceived,
  healingDone,
  cardsPlayed,
  battleTime,
  experience,
  level,
  streak,
  custom,
}

class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int rank;
  final double score;
  final Map<String, dynamic> details;
  final DateTime lastUpdated;

  LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.rank,
    required this.score,
    required this.details,
    required this.lastUpdated,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerId: json['playerId'],
      playerName: json['playerName'],
      rank: json['rank'],
      score: json['score']?.toDouble() ?? 0.0,
      details: Map<String, dynamic>.from(json['details']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'rank': rank,
      'score': score,
      'details': details,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final Map<String, dynamic> criteria;
  final int points;
  final String icon;
  final bool isSecret;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.criteria,
    required this.points,
    required this.icon,
    required this.isSecret,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: AchievementType.values.firstWhere((e) => e.name == json['type']),
      criteria: Map<String, dynamic>.from(json['criteria']),
      points: json['points'],
      icon: json['icon'],
      isSecret: json['isSecret'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'criteria': criteria,
      'points': points,
      'icon': icon,
      'isSecret': isSecret,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  bool get isUnlocked => unlockedAt != null;
}

enum AchievementType {
  battle,
  damage,
  healing,
  cards,
  streak,
  time,
  social,
  collection,
  special,
}

class BattleStatisticsService {
  static final Map<String, PlayerStatistics> _playerStats = {};
  static final Map<String, Leaderboard> _leaderboards = {};
  static final Map<String, Achievement> _achievements = {};

  static void initializeAchievements() {
    _achievements.addAll({
      'first_win': Achievement(
        id: 'first_win',
        name: 'First Victory',
        description: 'Win your first battle',
        type: AchievementType.battle,
        criteria: {'wins': 1},
        points: 10,
        icon: 'assets/icons/achievements/first_win.png',
        isSecret: false,
      ),
      
      'winning_streak_5': Achievement(
        id: 'winning_streak_5',
        name: 'Hot Streak',
        description: 'Win 5 battles in a row',
        type: AchievementType.streak,
        criteria: {'streak': 5},
        points: 50,
        icon: 'assets/icons/achievements/streak_5.png',
        isSecret: false,
      ),
      
      'winning_streak_10': Achievement(
        id: 'winning_streak_10',
        name: 'Unstoppable',
        description: 'Win 10 battles in a row',
        type: AchievementType.streak,
        criteria: {'streak': 10},
        points: 100,
        icon: 'assets/icons/achievements/streak_10.png',
        isSecret: false,
      ),
      
      'damage_dealer': Achievement(
        id: 'damage_dealer',
        name: 'Damage Dealer',
        description: 'Deal 1000 total damage',
        type: AchievementType.damage,
        criteria: {'totalDamage': 1000},
        points: 25,
        icon: 'assets/icons/achievements/damage_dealer.png',
        isSecret: false,
      ),
      
      'healer': Achievement(
        id: 'healer',
        name: 'Healer',
        description: 'Heal 500 total health',
        type: AchievementType.healing,
        criteria: {'totalHealing': 500},
        points: 30,
        icon: 'assets/icons/achievements/healer.png',
        isSecret: false,
      ),
      
      'card_master': Achievement(
        id: 'card_master',
        name: 'Card Master',
        description: 'Play 100 cards',
        type: AchievementType.cards,
        criteria: {'cardsPlayed': 100},
        points: 40,
        icon: 'assets/icons/achievements/card_master.png',
        isSecret: false,
      ),
      
      'battle_veteran': Achievement(
        id: 'battle_veteran',
        name: 'Battle Veteran',
        description: 'Participate in 50 battles',
        type: AchievementType.battle,
        criteria: {'totalBattles': 50},
        points: 75,
        icon: 'assets/icons/achievements/veteran.png',
        isSecret: false,
      ),
      
      'speed_demon': Achievement(
        id: 'speed_demon',
        name: 'Speed Demon',
        description: 'Complete a battle in under 30 seconds',
        type: AchievementType.time,
        criteria: {'battleTime': 30000}, // 30 seconds in milliseconds
        points: 20,
        icon: 'assets/icons/achievements/speed_demon.png',
        isSecret: false,
      ),
      
      'perfect_victory': Achievement(
        id: 'perfect_victory',
        name: 'Perfect Victory',
        description: 'Win a battle without taking any damage',
        type: AchievementType.battle,
        criteria: {'damageReceived': 0, 'result': 'win'},
        points: 100,
        icon: 'assets/icons/achievements/perfect_victory.png',
        isSecret: true,
      ),
      
      'comeback_king': Achievement(
        id: 'comeback_king',
        name: 'Comeback King',
        description: 'Win a battle when your health was below 10%',
        type: AchievementType.battle,
        criteria: {'lowHealthWin': true},
        points: 150,
        icon: 'assets/icons/achievements/comeback_king.png',
        isSecret: true,
      ),
    });
  }

  static void initializeLeaderboards() {
    _leaderboards.addAll({
      'wins': Leaderboard(
        id: 'wins',
        name: 'Most Wins',
        description: 'Players with the most battle victories',
        type: LeaderboardType.wins,
        entries: [],
        lastUpdated: DateTime.now(),
        maxEntries: 100,
        criteria: {'sortBy': 'wins', 'order': 'desc'},
      ),
      
      'win_rate': Leaderboard(
        id: 'win_rate',
        name: 'Best Win Rate',
        description: 'Players with the highest win percentage',
        type: LeaderboardType.winRate,
        entries: [],
        lastUpdated: DateTime.now(),
        maxEntries: 100,
        criteria: {'sortBy': 'winRate', 'order': 'desc', 'minBattles': 10},
      ),
      
      'damage_dealt': Leaderboard(
        id: 'damage_dealt',
        name: 'Damage Dealers',
        description: 'Players who deal the most damage',
        type: LeaderboardType.damageDealt,
        entries: [],
        lastUpdated: DateTime.now(),
        maxEntries: 100,
        criteria: {'sortBy': 'totalDamageDealt', 'order': 'desc'},
      ),
      
      'healing': Leaderboard(
        id: 'healing',
        name: 'Best Healers',
        description: 'Players who heal the most',
        type: LeaderboardType.healingDone,
        entries: [],
        lastUpdated: DateTime.now(),
        maxEntries: 100,
        criteria: {'sortBy': 'totalHealingDone', 'order': 'desc'},
      ),
      
      'experience': Leaderboard(
        id: 'experience',
        name: 'Highest Level',
        description: 'Players with the highest experience level',
        type: LeaderboardType.experience,
        entries: [],
        lastUpdated: DateTime.now(),
        maxEntries: 100,
        criteria: {'sortBy': 'level', 'order': 'desc'},
      ),
      
      'streak': Leaderboard(
        id: 'streak',
        name: 'Longest Streaks',
        description: 'Players with the longest winning streaks',
        type: LeaderboardType.streak,
        entries: [],
        lastUpdated: DateTime.now(),
        maxEntries: 100,
        criteria: {'sortBy': 'longestStreak', 'order': 'desc'},
      ),
    });
  }

  static void updatePlayerStatistics(String playerId, BattleStatistics battleStats, bool isVictory) {
    PlayerStatistics? currentStats = _playerStats[playerId];
    
    if (currentStats == null) {
      // Create new player statistics
      currentStats = PlayerStatistics(
        playerId: playerId,
        playerName: 'Player $playerId', // This would come from user data
        totalBattles: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        winRate: 0.0,
        totalDamageDealt: 0,
        totalDamageReceived: 0,
        totalHealingDone: 0,
        totalCardsPlayed: 0,
        totalSpecialAbilitiesUsed: 0,
        totalBattleTime: Duration.zero,
        currentStreak: 0,
        longestStreak: 0,
        rank: 0,
        experience: 0,
        level: 1,
        achievements: {},
        favoriteCards: [],
        cardUsageStats: {},
        lastBattleTime: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }

    // Update statistics
    int newWins = currentStats.wins + (isVictory ? 1 : 0);
    int newLosses = currentStats.losses + (isVictory ? 0 : 1);
    int newTotalBattles = currentStats.totalBattles + 1;
    double newWinRate = newTotalBattles > 0 ? newWins / newTotalBattles : 0.0;
    
    int newCurrentStreak = isVictory ? currentStats.currentStreak + 1 : 0;
    int newLongestStreak = max(currentStats.longestStreak, newCurrentStreak);
    
    int newExperience = currentStats.experience + (isVictory ? 50 : 10);
    int newLevel = (newExperience / 100).floor() + 1;

    PlayerStatistics updatedStats = currentStats.copyWith(
      totalBattles: newTotalBattles,
      wins: newWins,
      losses: newLosses,
      winRate: newWinRate,
      totalDamageDealt: currentStats.totalDamageDealt + battleStats.damageDealt,
      totalDamageReceived: currentStats.totalDamageReceived + battleStats.damageReceived,
      totalHealingDone: currentStats.totalHealingDone + battleStats.healingDone,
      totalCardsPlayed: currentStats.totalCardsPlayed + battleStats.cardsPlayed,
      totalSpecialAbilitiesUsed: currentStats.totalSpecialAbilitiesUsed + battleStats.specialAbilitiesUsed,
      totalBattleTime: currentStats.totalBattleTime + battleStats.battleDuration,
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      experience: newExperience,
      level: newLevel,
      lastBattleTime: DateTime.now(),
    );

    _playerStats[playerId] = updatedStats;

    // Check for achievements
    _checkAchievements(playerId, updatedStats, battleStats, isVictory);

    // Update leaderboards
    _updateLeaderboards();
  }

  static void _checkAchievements(String playerId, PlayerStatistics stats, BattleStatistics battleStats, bool isVictory) {
    for (var achievement in _achievements.values) {
      if (achievement.isUnlocked) continue; // Already unlocked
      
      bool shouldUnlock = false;
      
      switch (achievement.id) {
        case 'first_win':
          shouldUnlock = stats.wins == 1;
          break;
        case 'winning_streak_5':
          shouldUnlock = stats.currentStreak == 5;
          break;
        case 'winning_streak_10':
          shouldUnlock = stats.currentStreak == 10;
          break;
        case 'damage_dealer':
          shouldUnlock = stats.totalDamageDealt >= 1000;
          break;
        case 'healer':
          shouldUnlock = stats.totalHealingDone >= 500;
          break;
        case 'card_master':
          shouldUnlock = stats.totalCardsPlayed >= 100;
          break;
        case 'battle_veteran':
          shouldUnlock = stats.totalBattles >= 50;
          break;
        case 'speed_demon':
          shouldUnlock = battleStats.battleDuration.inMilliseconds <= 30000;
          break;
        case 'perfect_victory':
          shouldUnlock = isVictory && battleStats.damageReceived == 0;
          break;
        case 'comeback_king':
          // This would need to be tracked during battle
          shouldUnlock = false; // Placeholder
          break;
      }
      
      if (shouldUnlock) {
        _unlockAchievement(playerId, achievement.id);
      }
    }
  }

  static void _unlockAchievement(String playerId, String achievementId) {
    Achievement? achievement = _achievements[achievementId];
    if (achievement == null) return;

    // Create unlocked achievement
    Achievement unlockedAchievement = achievement.copyWith(
      unlockedAt: DateTime.now(),
    );

    // Update player's achievements
    PlayerStatistics? playerStats = _playerStats[playerId];
    if (playerStats != null) {
      Map<String, dynamic> newAchievements = Map.from(playerStats.achievements);
      newAchievements[achievementId] = unlockedAchievement.toJson();
      
      _playerStats[playerId] = playerStats.copyWith(
        achievements: newAchievements,
      );
    }
  }

  static void _updateLeaderboards() {
    List<PlayerStatistics> allPlayers = _playerStats.values.toList();
    
    // Update each leaderboard
    for (var leaderboard in _leaderboards.values) {
      List<LeaderboardEntry> entries = [];
      
      switch (leaderboard.type) {
        case LeaderboardType.wins:
          allPlayers.sort((a, b) => b.wins.compareTo(a.wins));
          break;
        case LeaderboardType.winRate:
          allPlayers.sort((a, b) => b.winRate.compareTo(a.winRate));
          break;
        case LeaderboardType.damageDealt:
          allPlayers.sort((a, b) => b.totalDamageDealt.compareTo(a.totalDamageDealt));
          break;
        case LeaderboardType.healingDone:
          allPlayers.sort((a, b) => b.totalHealingDone.compareTo(a.totalHealingDone));
          break;
        case LeaderboardType.experience:
          allPlayers.sort((a, b) => b.level.compareTo(a.level));
          break;
        case LeaderboardType.streak:
          allPlayers.sort((a, b) => b.longestStreak.compareTo(a.longestStreak));
          break;
        default:
          break;
      }
      
      // Create entries
      for (int i = 0; i < allPlayers.length && i < leaderboard.maxEntries; i++) {
        PlayerStatistics player = allPlayers[i];
        double score = _calculateScore(leaderboard.type, player);
        
        entries.add(LeaderboardEntry(
          playerId: player.playerId,
          playerName: player.playerName,
          rank: i + 1,
          score: score,
          details: _getPlayerDetails(leaderboard.type, player),
          lastUpdated: DateTime.now(),
        ));
      }
      
      // Update leaderboard
      _leaderboards[leaderboard.id] = leaderboard.copyWith(
        entries: entries,
        lastUpdated: DateTime.now(),
      );
    }
  }

  static double _calculateScore(LeaderboardType type, PlayerStatistics player) {
    switch (type) {
      case LeaderboardType.wins:
        return player.wins.toDouble();
      case LeaderboardType.winRate:
        return player.winRate * 100;
      case LeaderboardType.damageDealt:
        return player.totalDamageDealt.toDouble();
      case LeaderboardType.healingDone:
        return player.totalHealingDone.toDouble();
      case LeaderboardType.experience:
        return player.level.toDouble();
      case LeaderboardType.streak:
        return player.longestStreak.toDouble();
      default:
        return 0.0;
    }
  }

  static Map<String, dynamic> _getPlayerDetails(LeaderboardType type, PlayerStatistics player) {
    switch (type) {
      case LeaderboardType.wins:
        return {
          'wins': player.wins,
          'totalBattles': player.totalBattles,
          'winRate': player.winRate,
        };
      case LeaderboardType.winRate:
        return {
          'winRate': player.winRate,
          'wins': player.wins,
          'totalBattles': player.totalBattles,
        };
      case LeaderboardType.damageDealt:
        return {
          'totalDamage': player.totalDamageDealt,
          'averageDamage': player.averageDamagePerBattle,
          'battles': player.totalBattles,
        };
      case LeaderboardType.healingDone:
        return {
          'totalHealing': player.totalHealingDone,
          'averageHealing': player.averageHealingPerBattle,
          'battles': player.totalBattles,
        };
      case LeaderboardType.experience:
        return {
          'level': player.level,
          'experience': player.experience,
          'totalBattles': player.totalBattles,
        };
      case LeaderboardType.streak:
        return {
          'longestStreak': player.longestStreak,
          'currentStreak': player.currentStreak,
          'totalWins': player.wins,
        };
      default:
        return {};
    }
  }

  static PlayerStatistics? getPlayerStatistics(String playerId) {
    return _playerStats[playerId];
  }

  static List<PlayerStatistics> getAllPlayerStatistics() {
    return _playerStats.values.toList();
  }

  static List<PlayerStatistics> getTopPlayers(int count) {
    List<PlayerStatistics> players = _playerStats.values.toList();
    players.sort((a, b) => b.wins.compareTo(a.wins));
    return players.take(count).toList();
  }

  static Leaderboard? getLeaderboard(String leaderboardId) {
    return _leaderboards[leaderboardId];
  }

  static List<Leaderboard> getAllLeaderboards() {
    return _leaderboards.values.toList();
  }

  static List<Achievement> getPlayerAchievements(String playerId) {
    PlayerStatistics? playerStats = _playerStats[playerId];
    if (playerStats == null) return [];

    List<Achievement> achievements = [];
    for (var achievement in _achievements.values) {
      if (playerStats.achievements.containsKey(achievement.id)) {
        achievements.add(achievement.copyWith(
          unlockedAt: DateTime.parse(playerStats.achievements[achievement.id]['unlockedAt']),
        ));
      }
    }
    return achievements;
  }

  static List<Achievement> getAllAchievements() {
    return _achievements.values.toList();
  }

  static void resetPlayerStatistics(String playerId) {
    _playerStats.remove(playerId);
  }

  static void deleteLeaderboard(String leaderboardId) {
    _leaderboards.remove(leaderboardId);
  }
}

// Extension to add copyWith method to Leaderboard
extension LeaderboardCopyWith on Leaderboard {
  Leaderboard copyWith({
    String? id,
    String? name,
    String? description,
    LeaderboardType? type,
    List<LeaderboardEntry>? entries,
    DateTime? lastUpdated,
    int? maxEntries,
    Map<String, dynamic>? criteria,
  }) {
    return Leaderboard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      entries: entries ?? this.entries,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      maxEntries: maxEntries ?? this.maxEntries,
      criteria: criteria ?? this.criteria,
    );
  }
}

// Extension to add copyWith method to Achievement
extension AchievementCopyWith on Achievement {
  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    AchievementType? type,
    Map<String, dynamic>? criteria,
    int? points,
    String? icon,
    bool? isSecret,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      criteria: criteria ?? this.criteria,
      points: points ?? this.points,
      icon: icon ?? this.icon,
      isSecret: isSecret ?? this.isSecret,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

// Riverpod providers
final battleStatisticsServiceProvider = Provider<BattleStatisticsService>((ref) {
  return BattleStatisticsService();
});

final playerStatisticsProvider = StateProvider<Map<String, PlayerStatistics>>((ref) {
  return {};
});

final leaderboardsProvider = StateProvider<List<Leaderboard>>((ref) {
  return BattleStatisticsService.getAllLeaderboards();
});

final achievementsProvider = StateProvider<List<Achievement>>((ref) {
  return BattleStatisticsService.getAllAchievements();
});
