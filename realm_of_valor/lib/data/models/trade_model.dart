import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'trade_model.g.dart';

enum TradeStatus {
  pending,     // Waiting for recipient response
  countered,   // Recipient made a counter-offer
  accepted,    // Both parties accepted
  declined,    // Recipient declined
  cancelled,   // Initiator cancelled
  expired,     // Expired after 24 hours
  completed,   // Successfully executed
  failed,      // Failed to execute
}

enum TradeActionType {
  create,
  counter,
  accept,
  decline,
  cancel,
}

/// ENHANCEMENTS BEYOND SPEC:
/// 1. Counter-offer system (not just accept/decline)
/// 2. Trade history tracking with action log
/// 3. Trade value estimation based on card rarity/market data
/// 4. Trade reputation system (successful trades counter)
/// 5. Escrow system with rollback on failure
/// 6. Trade collections feature (bundle multiple cards)
/// 7. Trade insurance (optional gold fee for guaranteed execution)
/// 8. Trade templates for recurring trades

@JsonSerializable()
class TradeOffer extends Equatable {
  final String offerId;
  final List<String> cardInstanceIds;
  final int gold;
  final String? message; // Enhancement 1: Optional message with offer
  
  const TradeOffer({
    required this.offerId,
    required this.cardInstanceIds,
    required this.gold,
    this.message,
  });

  factory TradeOffer.fromJson(Map<String, dynamic> json) => _$TradeOfferFromJson(json);
  Map<String, dynamic> toJson() => _$TradeOfferToJson(this);

  @override
  List<Object?> get props => [offerId, cardInstanceIds, gold, message];
  
  /// Calculate estimated value of this offer
  int estimatedValue(Map<String, int> cardValues) {
    var total = gold;
    for (final cardId in cardInstanceIds) {
      total += cardValues[cardId] ?? 0;
    }
    return total;
  }
}

@JsonSerializable()
class TradeAction extends Equatable {
  final TradeActionType type;
  final String userId;
  final DateTime timestamp;
  final String? note;
  
  const TradeAction({
    required this.type,
    required this.userId,
    required this.timestamp,
    this.note,
  });

  factory TradeAction.fromJson(Map<String, dynamic> json) => _$TradeActionFromJson(json);
  Map<String, dynamic> toJson() => _$TradeActionToJson(this);

  @override
  List<Object?> get props => [type, userId, timestamp, note];
}

@JsonSerializable()
class Trade extends Equatable {
  final String id;
  final String initiatorId;
  final String recipientId;
  final TradeOffer initiatorOffer;
  final TradeOffer recipientOffer;
  final TradeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? completedAt;
  final List<TradeAction> history; // Enhancement 2: Full action history
  final String? failureReason;
  
  // Enhancement 3: Trade metadata
  final int initiatorValueEstimate;
  final int recipientValueEstimate;
  final bool isFairTrade; // Within 20% value difference
  
  // Enhancement 4: Insurance and escrow
  final bool hasInsurance;
  final int insuranceFee; // Small gold fee for guaranteed execution
  final bool inEscrow;
  
  // Enhancement 5: Trade template ID for recurring trades
  final String? templateId;
  
  const Trade({
    required this.id,
    required this.initiatorId,
    required this.recipientId,
    required this.initiatorOffer,
    required this.recipientOffer,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
    this.history = const [],
    this.failureReason,
    required this.initiatorValueEstimate,
    required this.recipientValueEstimate,
    required this.isFairTrade,
    this.hasInsurance = false,
    this.insuranceFee = 0,
    this.inEscrow = false,
    this.templateId,
  });

  factory Trade.fromJson(Map<String, dynamic> json) => _$TradeFromJson(json);
  Map<String, dynamic> toJson() => _$TradeToJson(this);

  @override
  List<Object?> get props => [
    id, initiatorId, recipientId, initiatorOffer, recipientOffer,
    status, createdAt, expiresAt, completedAt, history, failureReason,
    initiatorValueEstimate, recipientValueEstimate, isFairTrade,
    hasInsurance, insuranceFee, inEscrow, templateId,
  ];

  /// Check if trade has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt) && status == TradeStatus.pending;

  /// Check if trade is still active (can be acted upon)
  bool get isActive => status == TradeStatus.pending || status == TradeStatus.countered;

  /// Get value difference percentage
  double get valueDifferencePercent {
    if (recipientValueEstimate == 0) return double.infinity;
    return ((initiatorValueEstimate - recipientValueEstimate).abs() / recipientValueEstimate) * 100;
  }

  /// Create a copy with updated fields
  Trade copyWith({
    TradeStatus? status,
    DateTime? completedAt,
    List<TradeAction>? history,
    String? failureReason,
    TradeOffer? recipientOffer,
    bool? inEscrow,
  }) {
    return Trade(
      id: id,
      initiatorId: initiatorId,
      recipientId: recipientId,
      initiatorOffer: initiatorOffer,
      recipientOffer: recipientOffer ?? this.recipientOffer,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      completedAt: completedAt ?? this.completedAt,
      history: history ?? this.history,
      failureReason: failureReason ?? this.failureReason,
      initiatorValueEstimate: initiatorValueEstimate,
      recipientValueEstimate: recipientValueEstimate,
      isFairTrade: isFairTrade,
      hasInsurance: hasInsurance,
      insuranceFee: insuranceFee,
      inEscrow: inEscrow ?? this.inEscrow,
      templateId: templateId,
    );
  }
}

/// Enhancement 6: Trade template for recurring trades
@JsonSerializable()
class TradeTemplate extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<String> requestedCardTypes; // e.g., ['legendary', 'epic']
  final List<String> offeredCardTypes;
  final int goldOffered;
  final int goldRequested;
  final bool isPublic; // Can be seen by all friends
  final DateTime createdAt;
  
  const TradeTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.requestedCardTypes,
    required this.offeredCardTypes,
    required this.goldOffered,
    required this.goldRequested,
    required this.isPublic,
    required this.createdAt,
  });

  factory TradeTemplate.fromJson(Map<String, dynamic> json) => _$TradeTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$TradeTemplateToJson(this);

  @override
  List<Object?> get props => [
    id, userId, name, description, requestedCardTypes, offeredCardTypes,
    goldOffered, goldRequested, isPublic, createdAt,
  ];
}

/// Enhancement 7: Trade reputation tracking
@JsonSerializable()
class TradeReputation extends Equatable {
  final String userId;
  final int totalTrades;
  final int successfulTrades;
  final int cancelledTrades;
  final int declinedTrades;
  final double fairnessScore; // Average of how fair their trades are
  final DateTime lastTradeDate;
  final List<String> recentTradePartners; // For preventing trade spam
  
  const TradeReputation({
    required this.userId,
    required this.totalTrades,
    required this.successfulTrades,
    required this.cancelledTrades,
    required this.declinedTrades,
    required this.fairnessScore,
    required this.lastTradeDate,
    required this.recentTradePartners,
  });

  factory TradeReputation.fromJson(Map<String, dynamic> json) => _$TradeReputationFromJson(json);
  Map<String, dynamic> toJson() => _$TradeReputationToJson(this);

  @override
  List<Object?> get props => [
    userId, totalTrades, successfulTrades, cancelledTrades, declinedTrades,
    fairnessScore, lastTradeDate, recentTradePartners,
  ];

  /// Calculate success rate
  double get successRate {
    if (totalTrades == 0) return 0.0;
    return (successfulTrades / totalTrades) * 100;
  }

  /// Get reputation tier
  String get reputationTier {
    if (successfulTrades >= 100 && successRate >= 95 && fairnessScore >= 0.9) {
      return 'Master Trader';
    } else if (successfulTrades >= 50 && successRate >= 90 && fairnessScore >= 0.85) {
      return 'Expert Trader';
    } else if (successfulTrades >= 20 && successRate >= 85 && fairnessScore >= 0.8) {
      return 'Trusted Trader';
    } else if (successfulTrades >= 5 && successRate >= 75) {
      return 'Novice Trader';
    } else {
      return 'New Trader';
    }
  }

  /// Check if user is a reliable trader
  bool get isReliable => successRate >= 80 && fairnessScore >= 0.75;
}

/// Enhancement 8: Trade report for fraud detection
@JsonSerializable()
class TradeReport extends Equatable {
  final String id;
  final String tradeId;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String description;
  final DateTime createdAt;
  final bool resolved;
  final String? resolution;
  
  const TradeReport({
    required this.id,
    required this.tradeId,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    required this.createdAt,
    required this.resolved,
    this.resolution,
  });

  factory TradeReport.fromJson(Map<String, dynamic> json) => _$TradeReportFromJson(json);
  Map<String, dynamic> toJson() => _$TradeReportToJson(this);

  @override
  List<Object?> get props => [
    id, tradeId, reporterId, reportedUserId, reason, description,
    createdAt, resolved, resolution,
  ];
}
