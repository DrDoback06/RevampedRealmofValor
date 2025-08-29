import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/battle_models.dart';

class Tournament {
  final String id;
  final String name;
  final String description;
  final TournamentType type;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants;
  final List<TournamentMatch> matches;
  final TournamentBracket bracket;
  final Map<String, TournamentPlayer> playerStats;
  final TournamentStatus status;
  final Map<String, dynamic> rules;
  final List<String> rewards;

  Tournament({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.participants,
    required this.matches,
    required this.bracket,
    required this.playerStats,
    required this.status,
    required this.rules,
    required this.rewards,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: TournamentType.values.firstWhere((e) => e.name == json['type']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      participants: List<String>.from(json['participants']),
      matches: (json['matches'] as List)
          .map((m) => TournamentMatch.fromJson(m))
          .toList(),
      bracket: TournamentBracket.fromJson(json['bracket']),
      playerStats: (json['playerStats'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, TournamentPlayer.fromJson(value))),
      status: TournamentStatus.values.firstWhere((e) => e.name == json['status']),
      rules: Map<String, dynamic>.from(json['rules']),
      rewards: List<String>.from(json['rewards']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'participants': participants,
      'matches': matches.map((m) => m.toJson()).toList(),
      'bracket': bracket.toJson(),
      'playerStats': playerStats.map((key, value) => MapEntry(key, value.toJson())),
      'status': status.name,
      'rules': rules,
      'rewards': rewards,
    };
  }

  bool get isActive => status == TournamentStatus.active;
  bool get isRegistrationOpen => status == TournamentStatus.registration;
  bool get isCompleted => status == TournamentStatus.completed;
  bool get isCancelled => status == TournamentStatus.cancelled;

  List<TournamentPlayer> get sortedPlayers {
    List<TournamentPlayer> players = playerStats.values.toList();
    players.sort((a, b) => b.points.compareTo(a.points));
    return players;
  }

  TournamentPlayer? getWinner() {
    if (!isCompleted) return null;
    return sortedPlayers.first;
  }

  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    TournamentType? type,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? participants,
    List<TournamentMatch>? matches,
    TournamentBracket? bracket,
    Map<String, TournamentPlayer>? playerStats,
    TournamentStatus? status,
    Map<String, dynamic>? rules,
    List<String>? rewards,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      bracket: bracket ?? this.bracket,
      playerStats: playerStats ?? this.playerStats,
      status: status ?? this.status,
      rules: rules ?? this.rules,
      rewards: rewards ?? this.rewards,
    );
  }
}

enum TournamentType {
  singleElimination,
  doubleElimination,
  roundRobin,
  swiss,
  battleRoyale,
}

enum TournamentStatus {
  registration,
  active,
  completed,
  cancelled,
}

class TournamentMatch {
  final String id;
  final String tournamentId;
  final String player1Id;
  final String player2Id;
  final MatchStatus status;
  final String? winnerId;
  final String? loserId;
  final DateTime? scheduledTime;
  final DateTime? completedTime;
  final int round;
  final int matchNumber;
  final Map<String, dynamic> results;
  final List<String> replays;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.player1Id,
    required this.player2Id,
    required this.status,
    this.winnerId,
    this.loserId,
    this.scheduledTime,
    this.completedTime,
    required this.round,
    required this.matchNumber,
    required this.results,
    required this.replays,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'],
      tournamentId: json['tournamentId'],
      player1Id: json['player1Id'],
      player2Id: json['player2Id'],
      status: MatchStatus.values.firstWhere((e) => e.name == json['status']),
      winnerId: json['winnerId'],
      loserId: json['loserId'],
      scheduledTime: json['scheduledTime'] != null 
          ? DateTime.parse(json['scheduledTime']) 
          : null,
      completedTime: json['completedTime'] != null 
          ? DateTime.parse(json['completedTime']) 
          : null,
      round: json['round'],
      matchNumber: json['matchNumber'],
      results: Map<String, dynamic>.from(json['results'] ?? {}),
      replays: List<String>.from(json['replays'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'status': status.name,
      'winnerId': winnerId,
      'loserId': loserId,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'round': round,
      'matchNumber': matchNumber,
      'results': results,
      'replays': replays,
    };
  }

  bool get isCompleted => status == MatchStatus.completed;
  bool get isInProgress => status == MatchStatus.inProgress;
  bool get isScheduled => status == MatchStatus.scheduled;
  bool get isBye => player1Id.isEmpty || player2Id.isEmpty;

  TournamentMatch copyWith({
    String? id,
    String? tournamentId,
    String? player1Id,
    String? player2Id,
    MatchStatus? status,
    String? winnerId,
    String? loserId,
    DateTime? scheduledTime,
    DateTime? completedTime,
    int? round,
    int? matchNumber,
    Map<String, dynamic>? results,
    List<String>? replays,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      loserId: loserId ?? this.loserId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      completedTime: completedTime ?? this.completedTime,
      round: round ?? this.round,
      matchNumber: matchNumber ?? this.matchNumber,
      results: results ?? this.results,
      replays: replays ?? this.replays,
    );
  }
}

enum MatchStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  bye,
}

class TournamentBracket {
  final String id;
  final List<BracketRound> rounds;
  final Map<String, String> nextMatches;
  final Map<String, String> previousMatches;

  TournamentBracket({
    required this.id,
    required this.rounds,
    required this.nextMatches,
    required this.previousMatches,
  });

  factory TournamentBracket.fromJson(Map<String, dynamic> json) {
    return TournamentBracket(
      id: json['id'],
      rounds: (json['rounds'] as List)
          .map((r) => BracketRound.fromJson(r))
          .toList(),
      nextMatches: Map<String, String>.from(json['nextMatches']),
      previousMatches: Map<String, String>.from(json['previousMatches']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'nextMatches': nextMatches,
      'previousMatches': previousMatches,
    };
  }

  BracketRound? getCurrentRound() {
    return rounds.where((r) => r.isActive).firstOrNull;
  }

  List<BracketRound> getCompletedRounds() {
    return rounds.where((r) => r.isCompleted).toList();
  }
}

class BracketRound {
  final int roundNumber;
  final String name;
  final List<String> matchIds;
  final RoundStatus status;
  final DateTime? startTime;
  final DateTime? endTime;

  BracketRound({
    required this.roundNumber,
    required this.name,
    required this.matchIds,
    required this.status,
    this.startTime,
    this.endTime,
  });

  factory BracketRound.fromJson(Map<String, dynamic> json) {
    return BracketRound(
      roundNumber: json['roundNumber'],
      name: json['name'],
      matchIds: List<String>.from(json['matchIds']),
      status: RoundStatus.values.firstWhere((e) => e.name == json['status']),
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime']) 
          : null,
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'name': name,
      'matchIds': matchIds,
      'status': status.name,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  bool get isActive => status == RoundStatus.active;
  bool get isCompleted => status == RoundStatus.completed;
  bool get isPending => status == RoundStatus.pending;

  BracketRound copyWith({
    int? roundNumber,
    String? name,
    List<String>? matchIds,
    RoundStatus? status,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return BracketRound(
      roundNumber: roundNumber ?? this.roundNumber,
      name: name ?? this.name,
      matchIds: matchIds ?? this.matchIds,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

enum RoundStatus {
  pending,
  active,
  completed,
}

class TournamentPlayer {
  final String id;
  final String name;
  final int points;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;
  final List<String> matchHistory;
  final Map<String, dynamic> stats;
  final int rank;
  final bool isEliminated;

  TournamentPlayer({
    required this.id,
    required this.name,
    required this.points,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.matchHistory,
    required this.stats,
    required this.rank,
    required this.isEliminated,
  });

  factory TournamentPlayer.fromJson(Map<String, dynamic> json) {
    return TournamentPlayer(
      id: json['id'],
      name: json['name'],
      points: json['points'],
      wins: json['wins'],
      losses: json['losses'],
      draws: json['draws'],
      winRate: json['winRate']?.toDouble() ?? 0.0,
      matchHistory: List<String>.from(json['matchHistory']),
      stats: Map<String, dynamic>.from(json['stats']),
      rank: json['rank'],
      isEliminated: json['isEliminated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'winRate': winRate,
      'matchHistory': matchHistory,
      'stats': stats,
      'rank': rank,
      'isEliminated': isEliminated,
    };
  }

  int get totalMatches => wins + losses + draws;

  TournamentPlayer copyWith({
    String? id,
    String? name,
    int? points,
    int? wins,
    int? losses,
    int? draws,
    double? winRate,
    List<String>? matchHistory,
    Map<String, dynamic>? stats,
    int? rank,
    bool? isEliminated,
  }) {
    return TournamentPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      winRate: winRate ?? this.winRate,
      matchHistory: matchHistory ?? this.matchHistory,
      stats: stats ?? this.stats,
      rank: rank ?? this.rank,
      isEliminated: isEliminated ?? this.isEliminated,
    );
  }
}

class BattleTournamentService {
  static final Map<String, Tournament> _tournaments = {};
  static final Map<String, TournamentMatch> _matches = {};

  static Tournament createTournament({
    required String name,
    required String description,
    required TournamentType type,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> rules,
    required List<String> rewards,
  }) {
    String id = _generateId();
    
    Tournament tournament = Tournament(
      id: id,
      name: name,
      description: description,
      type: type,
      startDate: startDate,
      endDate: endDate,
      participants: [],
      matches: [],
      bracket: _createBracket(type, []),
      playerStats: {},
      status: TournamentStatus.registration,
      rules: rules,
      rewards: rewards,
    );

    _tournaments[id] = tournament;
    return tournament;
  }

  static TournamentBracket _createBracket(TournamentType type, List<String> participants) {
    switch (type) {
      case TournamentType.singleElimination:
        return _createSingleEliminationBracket(participants);
      case TournamentType.doubleElimination:
        return _createDoubleEliminationBracket(participants);
      case TournamentType.roundRobin:
        return _createRoundRobinBracket(participants);
      case TournamentType.swiss:
        return _createSwissBracket(participants);
      case TournamentType.battleRoyale:
        return _createBattleRoyaleBracket(participants);
    }
  }

  static TournamentBracket _createSingleEliminationBracket(List<String> participants) {
    List<BracketRound> rounds = [];
    Map<String, String> nextMatches = {};
    Map<String, String> previousMatches = {};

    // Calculate number of rounds needed
    int numRounds = (log(participants.length) / log(2)).ceil();
    
    // Create rounds
    for (int i = 0; i < numRounds; i++) {
      String roundName = i == 0 ? 'First Round' : 
                        i == numRounds - 1 ? 'Finals' : 
                        'Round ${i + 1}';
      
      List<String> matchIds = [];
      int matchesInRound = (participants.length / pow(2, i + 1)).ceil();
      
      for (int j = 0; j < matchesInRound; j++) {
        String matchId = _generateId();
        matchIds.add(matchId);
      }
      
      rounds.add(BracketRound(
        roundNumber: i + 1,
        name: roundName,
        matchIds: matchIds,
        status: i == 0 ? RoundStatus.pending : RoundStatus.pending,
      ));
    }

    return TournamentBracket(
      id: _generateId(),
      rounds: rounds,
      nextMatches: nextMatches,
      previousMatches: previousMatches,
    );
  }

  static TournamentBracket _createDoubleEliminationBracket(List<String> participants) {
    // Similar to single elimination but with losers bracket
    return _createSingleEliminationBracket(participants);
  }

  static TournamentBracket _createRoundRobinBracket(List<String> participants) {
    List<BracketRound> rounds = [];
    Map<String, String> nextMatches = {};
    Map<String, String> previousMatches = {};

    // Each participant plays against every other participant
    int numRounds = participants.length - 1;
    
    for (int i = 0; i < numRounds; i++) {
      List<String> matchIds = [];
      int matchesInRound = participants.length ~/ 2;
      
      for (int j = 0; j < matchesInRound; j++) {
        String matchId = _generateId();
        matchIds.add(matchId);
      }
      
      rounds.add(BracketRound(
        roundNumber: i + 1,
        name: 'Round ${i + 1}',
        matchIds: matchIds,
        status: RoundStatus.pending,
      ));
    }

    return TournamentBracket(
      id: _generateId(),
      rounds: rounds,
      nextMatches: nextMatches,
      previousMatches: previousMatches,
    );
  }

  static TournamentBracket _createSwissBracket(List<String> participants) {
    // Swiss system - players are paired against others with similar scores
    return _createRoundRobinBracket(participants);
  }

  static TournamentBracket _createBattleRoyaleBracket(List<String> participants) {
    // Battle royale - all participants in one match
    List<BracketRound> rounds = [];
    Map<String, String> nextMatches = {};
    Map<String, String> previousMatches = {};

    rounds.add(BracketRound(
      roundNumber: 1,
      name: 'Battle Royale',
      matchIds: [_generateId()],
      status: RoundStatus.pending,
    ));

    return TournamentBracket(
      id: _generateId(),
      rounds: rounds,
      nextMatches: nextMatches,
      previousMatches: previousMatches,
    );
  }

  static bool registerPlayer(String tournamentId, String playerId, String playerName) {
    Tournament? tournament = _tournaments[tournamentId];
    if (tournament == null || !tournament.isRegistrationOpen) {
      return false;
    }

    if (tournament.participants.contains(playerId)) {
      return false; // Already registered
    }

    // Add player to tournament
    tournament.participants.add(playerId);
    
    // Initialize player stats
    tournament.playerStats[playerId] = TournamentPlayer(
      id: playerId,
      name: playerName,
      points: 0,
      wins: 0,
      losses: 0,
      draws: 0,
      winRate: 0.0,
      matchHistory: [],
      stats: {},
      rank: tournament.participants.length,
      isEliminated: false,
    );

    return true;
  }

  static bool startTournament(String tournamentId) {
    Tournament? tournament = _tournaments[tournamentId];
    if (tournament == null || !tournament.isRegistrationOpen) {
      return false;
    }

    if (tournament.participants.length < 2) {
      return false; // Need at least 2 players
    }

    // Generate matches based on bracket
    List<TournamentMatch> matches = _generateMatches(tournament);
    
    // Create new tournament with updated data
    Tournament updatedTournament = tournament.copyWith(
      matches: matches,
      status: TournamentStatus.active,
    );
    
    // Update bracket with match IDs
    _updateBracketWithMatches(updatedTournament.bracket, matches);
    
    // Start first round
    if (updatedTournament.bracket.rounds.isNotEmpty) {
      updatedTournament.bracket.rounds.first = updatedTournament.bracket.rounds.first.copyWith(
        status: RoundStatus.active,
      );
    }

    _tournaments[tournamentId] = updatedTournament;
    return true;
  }

  static List<TournamentMatch> _generateMatches(Tournament tournament) {
    List<TournamentMatch> matches = [];
    List<String> participants = List.from(tournament.participants);
    
    // Shuffle participants for random seeding
    participants.shuffle();

    switch (tournament.type) {
      case TournamentType.singleElimination:
        matches = _generateSingleEliminationMatches(tournament, participants);
        break;
      case TournamentType.roundRobin:
        matches = _generateRoundRobinMatches(tournament, participants);
        break;
      case TournamentType.battleRoyale:
        matches = _generateBattleRoyaleMatches(tournament, participants);
        break;
      default:
        matches = _generateSingleEliminationMatches(tournament, participants);
    }

    return matches;
  }

  static List<TournamentMatch> _generateSingleEliminationMatches(
    Tournament tournament, 
    List<String> participants
  ) {
    List<TournamentMatch> matches = [];
    int round = 1;
    int matchNumber = 1;

    // Create first round matches
    for (int i = 0; i < participants.length; i += 2) {
      String player1 = participants[i];
      String player2 = i + 1 < participants.length ? participants[i + 1] : '';
      
      TournamentMatch match = TournamentMatch(
        id: _generateId(),
        tournamentId: tournament.id,
        player1Id: player1,
        player2Id: player2,
        status: player2.isEmpty ? MatchStatus.bye : MatchStatus.scheduled,
        round: round,
        matchNumber: matchNumber,
        results: {},
        replays: [],
      );

      matches.add(match);
      _matches[match.id] = match;
      matchNumber++;
    }

    return matches;
  }

  static List<TournamentMatch> _generateRoundRobinMatches(
    Tournament tournament, 
    List<String> participants
  ) {
    List<TournamentMatch> matches = [];
    int round = 1;
    int matchNumber = 1;

    // Generate all possible pairings
    for (int i = 0; i < participants.length; i++) {
      for (int j = i + 1; j < participants.length; j++) {
        TournamentMatch match = TournamentMatch(
          id: _generateId(),
          tournamentId: tournament.id,
          player1Id: participants[i],
          player2Id: participants[j],
          status: MatchStatus.scheduled,
          round: round,
          matchNumber: matchNumber,
          results: {},
          replays: [],
        );

        matches.add(match);
        _matches[match.id] = match;
        matchNumber++;
      }
    }

    return matches;
  }

  static List<TournamentMatch> _generateBattleRoyaleMatches(
    Tournament tournament, 
    List<String> participants
  ) {
    List<TournamentMatch> matches = [];
    
    // Single match with all participants
    TournamentMatch match = TournamentMatch(
      id: _generateId(),
      tournamentId: tournament.id,
      player1Id: participants.join(','), // All participants in one match
      player2Id: '',
      status: MatchStatus.scheduled,
      round: 1,
      matchNumber: 1,
      results: {},
      replays: [],
    );

    matches.add(match);
    _matches[match.id] = match;

    return matches;
  }

  static void _updateBracketWithMatches(TournamentBracket bracket, List<TournamentMatch> matches) {
    int matchIndex = 0;
    
    for (var round in bracket.rounds) {
      for (int i = 0; i < round.matchIds.length && matchIndex < matches.length; i++) {
        round.matchIds[i] = matches[matchIndex].id;
        matchIndex++;
      }
    }
  }

  static bool recordMatchResult(
    String tournamentId, 
    String matchId, 
    String winnerId, 
    String loserId,
    Map<String, dynamic> results,
    String replayId,
  ) {
    Tournament? tournament = _tournaments[tournamentId];
    TournamentMatch? match = _matches[matchId];
    
    if (tournament == null || match == null) {
      return false;
    }

    // Update match
    match.status = MatchStatus.completed;
    match.winnerId = winnerId;
    match.loserId = loserId;
    match.completedTime = DateTime.now();
    match.results.addAll(results);
    match.replays.add(replayId);

    // Update player stats
    _updatePlayerStats(tournament, winnerId, loserId, results);

    // Check if tournament is complete
    _checkTournamentCompletion(tournament);

    return true;
  }

  static void _updatePlayerStats(
    Tournament tournament, 
    String winnerId, 
    String loserId, 
    Map<String, dynamic> results
  ) {
    TournamentPlayer? winner = tournament.playerStats[winnerId];
    TournamentPlayer? loser = tournament.playerStats[loserId];

    if (winner != null) {
      winner.wins++;
      winner.points += 3; // Win points
      winner.matchHistory.add(results['replayId'] ?? '');
      winner.winRate = winner.wins / (winner.wins + winner.losses + winner.draws);
    }

    if (loser != null) {
      loser.losses++;
      loser.matchHistory.add(results['replayId'] ?? '');
      loser.winRate = loser.wins / (loser.wins + loser.losses + loser.draws);
    }

    // Update rankings
    _updateRankings(tournament);
  }

  static void _updateRankings(Tournament tournament) {
    List<TournamentPlayer> players = tournament.playerStats.values.toList();
    players.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.winRate != a.winRate) return b.winRate.compareTo(a.winRate);
      return b.wins.compareTo(a.wins);
    });

    for (int i = 0; i < players.length; i++) {
      players[i].rank = i + 1;
    }
  }

  static void _checkTournamentCompletion(Tournament tournament) {
    bool allMatchesCompleted = tournament.matches.every((m) => m.isCompleted);
    
    if (allMatchesCompleted) {
      tournament.status = TournamentStatus.completed;
      
      // Award rewards to winner
      TournamentPlayer? winner = tournament.getWinner();
      if (winner != null) {
        // Award rewards logic would go here
      }
    }
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  static Tournament? getTournament(String tournamentId) {
    return _tournaments[tournamentId];
  }

  static List<Tournament> getAllTournaments() {
    return _tournaments.values.toList();
  }

  static List<Tournament> getActiveTournaments() {
    return _tournaments.values.where((t) => t.isActive).toList();
  }

  static List<Tournament> getRegistrationOpenTournaments() {
    return _tournaments.values.where((t) => t.isRegistrationOpen).toList();
  }

  static TournamentMatch? getMatch(String matchId) {
    return _matches[matchId];
  }

  static List<TournamentMatch> getMatchesForTournament(String tournamentId) {
    return _matches.values.where((m) => m.tournamentId == tournamentId).toList();
  }

  static void deleteTournament(String tournamentId) {
    _tournaments.remove(tournamentId);
    _matches.removeWhere((key, value) => value.tournamentId == tournamentId);
  }
}

// Riverpod providers
final battleTournamentServiceProvider = Provider<BattleTournamentService>((ref) {
  return BattleTournamentService();
});

final activeTournamentsProvider = StateProvider<List<Tournament>>((ref) {
  return BattleTournamentService.getActiveTournaments();
});

final registrationOpenTournamentsProvider = StateProvider<List<Tournament>>((ref) {
  return BattleTournamentService.getRegistrationOpenTournaments();
});
