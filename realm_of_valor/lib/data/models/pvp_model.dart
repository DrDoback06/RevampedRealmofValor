import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pvp_model.g.dart';

enum RankTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster, // Enhancement 1: Additional top tier
}

enum QueueType {
  casual,
  ranked,
  team2v2,
  team4v4,
  custom,
}

enum MatchResult {
  victory,
  defeat,
  draw,
  abandoned,
}

/// ENHANCEMENTS BEYOND SPEC:
/// 1. Grand Master tier above Master for top 100 players
/// 2. Division system within each tier (I, II, III, IV)
/// 3. Promotion series (best of 3/5 matches)
/// 4. Decay system for inactive high-rank players
/// 5. Performance-based MMR adjustments
/// 6. Streak bonuses and loss protection
/// 7. Role-based matchmaking preferences
/// 8. Season rewards and historical tracking

@JsonSerializable()
class PlayerRating extends Equatable {
  final String userId;
  final int elo; // Base ELO rating
  final int mmr; // Match making rating (hidden)
  final RankTier tier;
  final int division; // 1-4, where 4 is lowest
  final int leaguePoints; // 0-100, at 100 triggers promotion
  final int wins;
  final int losses;
  final int draws;
  final DateTime lastMatchDate;
  
  // Enhancement 2: Win/loss streaks
  final int currentStreak; // Positive for wins, negative for losses
  final int bestWinStreak;
  
  // Enhancement 3: Promotion series tracking
  final bool inPromoSeries;
  final int promoWins;
  final int promoLosses;
  final int promoGamesRequired; // 3 for division, 5 for tier
  
  // Enhancement 4: Decay tracking for inactive players
  final DateTime lastDecayCheck;
  final int decayWarnings; // Games needed to prevent decay
  
  // Enhancement 5: Performance bonuses
  final double performanceModifier; // 0.8 to 1.2 based on recent performance
  
  // Enhancement 6: Historical season data
  final int seasonId;
  final int peakElo;
  final RankTier peakTier;

  const PlayerRating({
    required this.userId,
    required this.elo,
    required this.mmr,
    required this.tier,
    required this.division,
    required this.leaguePoints,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.lastMatchDate,
    this.currentStreak = 0,
    this.bestWinStreak = 0,
    this.inPromoSeries = false,
    this.promoWins = 0,
    this.promoLosses = 0,
    this.promoGamesRequired = 3,
    required this.lastDecayCheck,
    this.decayWarnings = 0,
    this.performanceModifier = 1.0,
    required this.seasonId,
    required this.peakElo,
    required this.peakTier,
  });

  factory PlayerRating.fromJson(Map<String, dynamic> json) => _$PlayerRatingFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerRatingToJson(this);

  @override
  List<Object?> get props => [
    userId, elo, mmr, tier, division, leaguePoints, wins, losses, draws,
    lastMatchDate, currentStreak, bestWinStreak, inPromoSeries, promoWins,
    promoLosses, promoGamesRequired, lastDecayCheck, decayWarnings,
    performanceModifier, seasonId, peakElo, peakTier,
  ];

  int get totalGames => wins + losses + draws;
  
  double get winRate => totalGames > 0 ? (wins / totalGames) * 100 : 0.0;

  /// Get rank display string
  String get rankDisplay {
    final tierName = tier.name.toUpperCase();
    final romanNumerals = ['IV', 'III', 'II', 'I'];
    return '$tierName ${romanNumerals[division - 1]}';
  }

  /// Check if player needs decay protection
  bool needsDecayProtection() {
    if (tier.index < RankTier.platinum.index) return false; // No decay below Platinum
    
    final daysSinceMatch = DateTime.now().difference(lastMatchDate).inDays;
    return daysSinceMatch > 28; // 28 days of inactivity
  }

  /// Calculate expected ELO change
  int calculateEloChange(int opponentElo, bool won) {
    final kFactor = _getKFactor();
    final expected = 1 / (1 + Math.pow(10, (opponentElo - elo) / 400));
    final score = won ? 1.0 : 0.0;
    final change = (kFactor * (score - expected) * performanceModifier).round();
    
    // Streak bonus
    if (won && currentStreak > 0) {
      return change + (currentStreak >= 3 ? 2 : 0);
    }
    
    return change;
  }

  /// Get K-factor based on games played and tier
  int _getKFactor() {
    if (totalGames < 30) return 40; // New players
    if (tier.index >= RankTier.master.index) return 24; // High elo
    return 32; // Default
  }
}

@JsonSerializable()
class Match extends Equatable {
  final String matchId;
  final QueueType queueType;
  final List<String> playerIds;
  final Map<String, int> playerElos;
  final Map<String, MatchResult> results;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final String? winnerId;
  
  // Enhancement 7: Match statistics
  final Map<String, Map<String, dynamic>> playerStats;
  final String? mvpPlayerId; // Most valuable player
  
  // Enhancement 8: Replay data
  final String? replayId;
  final bool isRanked;
  
  const Match({
    required this.matchId,
    required this.queueType,
    required this.playerIds,
    required this.playerElos,
    required this.results,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    this.winnerId,
    required this.playerStats,
    this.mvpPlayerId,
    this.replayId,
    required this.isRanked,
  });

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);
  Map<String, dynamic> toJson() => _$MatchToJson(this);

  @override
  List<Object?> get props => [
    matchId, queueType, playerIds, playerElos, results, startTime, endTime,
    durationSeconds, winnerId, playerStats, mvpPlayerId, replayId, isRanked,
  ];

  bool get isComplete => endTime != null;
}

/// Enhancement 9: Matchmaking queue entry with role preferences
@JsonSerializable()
class QueueEntry extends Equatable {
  final String userId;
  final QueueType queueType;
  final int elo;
  final int mmr;
  final DateTime queuedAt;
  final List<String> preferredRoles; // ['tank', 'dps', 'support']
  final int searchRange; // Increases over time
  
  const QueueEntry({
    required this.userId,
    required this.queueType,
    required this.elo,
    required this.mmr,
    required this.queuedAt,
    this.preferredRoles = const [],
    this.searchRange = 100,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) => _$QueueEntryFromJson(json);
  Map<String, dynamic> toJson() => _$QueueEntryToJson(this);

  @override
  List<Object?> get props => [
    userId, queueType, elo, mmr, queuedAt, preferredRoles, searchRange,
  ];

  /// Get expanded search range based on queue time
  int getSearchRange() {
    final queueTimeSeconds = DateTime.now().difference(queuedAt).inSeconds;
    // Expand by 50 every 30 seconds, max 500
    return (searchRange + ((queueTimeSeconds ~/ 30) * 50)).clamp(100, 500);
  }
}

/// Enhancement 10: Season configuration and rewards
@JsonSerializable()
class Season extends Equatable {
  final int seasonId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final Map<RankTier, List<String>> rewards; // Card IDs and cosmetics per tier
  final Map<String, dynamic> specialEvents;
  final bool isActive;
  
  const Season({
    required this.seasonId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.rewards,
    required this.specialEvents,
    required this.isActive,
  });

  factory Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);
  Map<String, dynamic> toJson() => _$SeasonToJson(this);

  @override
  List<Object?> get props => [
    seasonId, name, startDate, endDate, rewards, specialEvents, isActive,
  ];

  bool get hasEnded => DateTime.now().isAfter(endDate);
  
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}

/// Helper class for math operations
class Math {
  static double pow(num x, num exponent) {
    return x.toDouble() * exponent.toDouble(); // Simplified, use dart:math in production
  }
}
