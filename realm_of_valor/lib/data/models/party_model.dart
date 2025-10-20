import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'party_model.g.dart';

/// PARTY SYSTEM for Boss Raids & Team Content
/// Following motto: "Don't Remove, Only Improve!"
/// 
/// ENHANCEMENTS (10+):
/// 1. Flexible party size (1-4 players)
/// 2. Party roles based on character (no enforcement)
/// 3. Party chat with quick messages
/// 4. Loot distribution system
/// 5. Party finder/matchmaking
/// 6. Party buffs (slight bonuses for full party)
/// 7. Kick/leave protection (vote system)
/// 8. Party ready checks
/// 9. Party invites with expiry
/// 10. Party achievements tracking
/// 11. Cross-region parties
/// 12. Party power level balancing

enum PartyRole {
  tank,    // High HP/Defense characters
  dps,     // High Attack characters
  support, // Healing/Buff characters
  flex,    // Balanced characters
}

enum PartyInviteStatus {
  pending,
  accepted,
  declined,
  expired,
}

enum PartyMemberStatus {
  online,
  ready,
  inBattle,
  offline,
}

@JsonSerializable()
class Party extends Equatable {
  final String partyId;
  final String leaderId;
  final List<PartyMember> members;
  final DateTime createdAt;
  final String? currentBossId; // If in boss raid
  final Map<String, dynamic> settings;
  
  // Enhancement 1: Party buffs
  final double partyBonusMultiplier; // 1.05 for 2 players, 1.1 for 3, 1.15 for 4
  
  // Enhancement 2: Party finder visibility
  final bool isPublic; // Can anyone join?
  final int minLevel; // Minimum level to join
  final int maxLevel; // Maximum level to join
  
  // Enhancement 3: Loot settings
  final LootDistribution lootMode;
  
  const Party({
    required this.partyId,
    required this.leaderId,
    required this.members,
    required this.createdAt,
    this.currentBossId,
    this.settings = const {},
    this.partyBonusMultiplier = 1.0,
    this.isPublic = false,
    this.minLevel = 1,
    this.maxLevel = 100,
    this.lootMode = LootDistribution.personal,
  });

  factory Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);
  Map<String, dynamic> toJson() => _$PartyToJson(this);

  @override
  List<Object?> get props => [
    partyId, leaderId, members, createdAt, currentBossId, settings,
    partyBonusMultiplier, isPublic, minLevel, maxLevel, lootMode,
  ];

  // Helper getters
  bool get isFull => members.length >= 4;
  bool get isEmpty => members.isEmpty;
  int get size => members.length;
  bool get isInBattle => currentBossId != null;
  
  bool get allReady => members.every((m) => m.status == PartyMemberStatus.ready);
  
  /// Get party power level (average of all members)
  int get powerLevel {
    if (members.isEmpty) return 0;
    return members.map((m) => m.level).reduce((a, b) => a + b) ~/ members.length;
  }
  
  /// Calculate party bonus based on size
  double getPartyBonus() {
    switch (members.length) {
      case 2: return 1.05; // +5%
      case 3: return 1.10; // +10%
      case 4: return 1.15; // +15%
      default: return 1.0;
    }
  }
  
  /// Check if user is party leader
  bool isLeader(String userId) => userId == leaderId;
  
  /// Check if user is in party
  bool hasMember(String userId) => members.any((m) => m.userId == userId);
  
  /// Get member by user ID
  PartyMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (e) {
      return null;
    }
  }
  
  /// Copy with method for updates
  Party copyWith({
    String? partyId,
    String? leaderId,
    List<PartyMember>? members,
    DateTime? createdAt,
    String? currentBossId,
    Map<String, dynamic>? settings,
    double? partyBonusMultiplier,
    bool? isPublic,
    int? minLevel,
    int? maxLevel,
    LootDistribution? lootMode,
  }) {
    return Party(
      partyId: partyId ?? this.partyId,
      leaderId: leaderId ?? this.leaderId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      currentBossId: currentBossId ?? this.currentBossId,
      settings: settings ?? this.settings,
      partyBonusMultiplier: partyBonusMultiplier ?? this.partyBonusMultiplier,
      isPublic: isPublic ?? this.isPublic,
      minLevel: minLevel ?? this.minLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      lootMode: lootMode ?? this.lootMode,
    );
  }
}

@JsonSerializable()
class PartyMember extends Equatable {
  final String userId;
  final String characterName;
  final int level;
  final PartyRole role; // Determined by character stats
  final PartyMemberStatus status;
  final DateTime joinedAt;
  
  // Enhancement 4: Character info for UI
  final int hp;
  final int maxHp;
  final int attack;
  final int defense;
  
  const PartyMember({
    required this.userId,
    required this.characterName,
    required this.level,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
  });

  factory PartyMember.fromJson(Map<String, dynamic> json) => _$PartyMemberFromJson(json);
  Map<String, dynamic> toJson() => _$PartyMemberToJson(this);

  @override
  List<Object?> get props => [
    userId, characterName, level, role, status, joinedAt,
    hp, maxHp, attack, defense,
  ];
  
  /// Determine role from character stats
  static PartyRole determineRole({
    required int vitality,
    required int strength,
    required int intelligence,
    required int agility,
  }) {
    // Tank: High vitality
    if (vitality > strength && vitality > intelligence) {
      return PartyRole.tank;
    }
    
    // DPS: High strength or agility
    if (strength > intelligence && strength > vitality) {
      return PartyRole.dps;
    }
    
    // Support: High intelligence
    if (intelligence > strength && intelligence > vitality) {
      return PartyRole.support;
    }
    
    // Flex: Balanced stats
    return PartyRole.flex;
  }
  
  /// Copy with method
  PartyMember copyWith({
    String? userId,
    String? characterName,
    int? level,
    PartyRole? role,
    PartyMemberStatus? status,
    DateTime? joinedAt,
    int? hp,
    int? maxHp,
    int? attack,
    int? defense,
  }) {
    return PartyMember(
      userId: userId ?? this.userId,
      characterName: characterName ?? this.characterName,
      level: level ?? this.level,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
    );
  }
}

@JsonSerializable()
class PartyInvite extends Equatable {
  final String inviteId;
  final String partyId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final PartyInviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  
  const PartyInvite({
    required this.inviteId,
    required this.partyId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory PartyInvite.fromJson(Map<String, dynamic> json) => _$PartyInviteFromJson(json);
  Map<String, dynamic> toJson() => _$PartyInviteToJson(this);

  @override
  List<Object?> get props => [
    inviteId, partyId, fromUserId, fromUserName, toUserId,
    status, createdAt, expiresAt,
  ];
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == PartyInviteStatus.pending && !isExpired;
}

/// Enhancement 5: Loot distribution modes
enum LootDistribution {
  personal,      // Everyone gets own loot (RECOMMENDED)
  equalSplit,    // Equal gold/XP for all
  contribution,  // Based on damage/healing done
  needGreed,     // Roll for items
}

/// Enhancement 6: Quick chat messages for parties
enum QuickChatMessage {
  // Combat
  attack,
  defend,
  heal,
  retreat,
  
  // Coordination
  ready,
  wait,
  go,
  help,
  
  // Reactions
  thanks,
  sorry,
  niceWork,
  almostThere,
  
  // Status
  lowHealth,
  lowMana,
  needHealing,
  enemyLowHP,
  
  // Strategy
  focusBoss,
  avoidAttack,
  useCombo,
  saveAbility,
}

/// Enhancement 7: Party emotes
enum PartyEmote {
  wave,
  cheer,
  thumbsUp,
  thumbsDown,
  laugh,
  cry,
  angry,
  shocked,
  thinking,
  sleep,
  fire,
  star,
  heart,
  skull,
  sword,
  shield,
}

/// Helper class for quick chat
class QuickChat {
  static String getMessage(QuickChatMessage message) {
    switch (message) {
      case QuickChatMessage.attack:
        return '⚔️ Attack!';
      case QuickChatMessage.defend:
        return '🛡️ Defend!';
      case QuickChatMessage.heal:
        return '💚 Heal!';
      case QuickChatMessage.retreat:
        return '🏃 Retreat!';
      case QuickChatMessage.ready:
        return '✅ Ready!';
      case QuickChatMessage.wait:
        return '✋ Wait!';
      case QuickChatMessage.go:
        return '▶️ Go!';
      case QuickChatMessage.help:
        return '🆘 Help!';
      case QuickChatMessage.thanks:
        return '🙏 Thanks!';
      case QuickChatMessage.sorry:
        return '😅 Sorry!';
      case QuickChatMessage.niceWork:
        return '👏 Nice work!';
      case QuickChatMessage.almostThere:
        return '🎯 Almost there!';
      case QuickChatMessage.lowHealth:
        return '❤️ Low health!';
      case QuickChatMessage.lowMana:
        return '💙 Low mana!';
      case QuickChatMessage.needHealing:
        return '💊 Need healing!';
      case QuickChatMessage.enemyLowHP:
        return '💀 Enemy low HP!';
      case QuickChatMessage.focusBoss:
        return '🎯 Focus boss!';
      case QuickChatMessage.avoidAttack:
        return '⚠️ Avoid attack!';
      case QuickChatMessage.useCombo:
        return '✨ Use combo!';
      case QuickChatMessage.saveAbility:
        return '⏸️ Save ability!';
    }
  }
}

/// Helper class for emotes
class EmoteHelper {
  static String getEmoteIcon(PartyEmote emote) {
    switch (emote) {
      case PartyEmote.wave:
        return '👋';
      case PartyEmote.cheer:
        return '🎉';
      case PartyEmote.thumbsUp:
        return '👍';
      case PartyEmote.thumbsDown:
        return '👎';
      case PartyEmote.laugh:
        return '😂';
      case PartyEmote.cry:
        return '😭';
      case PartyEmote.angry:
        return '😠';
      case PartyEmote.shocked:
        return '😱';
      case PartyEmote.thinking:
        return '🤔';
      case PartyEmote.sleep:
        return '😴';
      case PartyEmote.fire:
        return '🔥';
      case PartyEmote.star:
        return '⭐';
      case PartyEmote.heart:
        return '❤️';
      case PartyEmote.skull:
        return '💀';
      case PartyEmote.sword:
        return '⚔️';
      case PartyEmote.shield:
        return '🛡️';
    }
  }
}
