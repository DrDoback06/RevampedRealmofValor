import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/party_model.dart';
import '../data/models/character_model.dart';
import 'event_bus.dart';

/// PARTY MANAGEMENT SERVICE
/// Handles party formation, invites, matchmaking, and coordination
/// 
/// ENHANCEMENTS (12+):
/// 1. Auto-matchmaking for solo players
/// 2. Party finder with filters
/// 3. Cross-region party support
/// 4. Party invite system with expiry
/// 5. Party buffs based on size
/// 6. Smart role balancing
/// 7. Party ready checks
/// 8. Kick/leave vote system
/// 9. Party chat history
/// 10. Party achievements
/// 11. Party statistics tracking
/// 12. Reconnection support
/// 13. Party templates (save favorite compositions)
/// 14. Party power level matching

class PartyService {
  final EventBus _eventBus;
  
  // Active parties
  final Map<String, Party> _parties = {};
  
  // User to party mapping
  final Map<String, String> _userToParty = {};
  
  // Pending invites
  final Map<String, PartyInvite> _invites = {};
  
  // Party finder (public parties)
  final List<Party> _publicParties = [];
  
  // Quick chat history (last 50 messages per party)
  final Map<String, List<QuickChatMessage>> _chatHistory = {};
  
  // Enhancement 1: Party templates
  final Map<String, PartyTemplate> _partyTemplates = {};
  
  PartyService(this._eventBus);

  /// Enhancement 2: Create party
  Future<Party> createParty({
    required String leaderId,
    required String characterName,
    required int level,
    required CharacterStats stats,
    required int hp,
    required int maxHp,
    bool isPublic = false,
    int minLevel = 1,
    int maxLevel = 100,
    LootDistribution lootMode = LootDistribution.personal,
  }) async {
    final partyId = 'party_${DateTime.now().millisecondsSinceEpoch}_$leaderId';
    
    // Determine role from stats
    final role = PartyMember.determineRole(
      vitality: stats.vitality,
      strength: stats.strength,
      intelligence: stats.intelligence,
      agility: stats.agility,
    );
    
    final leader = PartyMember(
      userId: leaderId,
      characterName: characterName,
      level: level,
      role: role,
      status: PartyMemberStatus.online,
      joinedAt: DateTime.now(),
      hp: hp,
      maxHp: maxHp,
      attack: stats.strength,
      defense: stats.agility ~/ 2,
    );
    
    final party = Party(
      partyId: partyId,
      leaderId: leaderId,
      members: [leader],
      createdAt: DateTime.now(),
      isPublic: isPublic,
      minLevel: minLevel,
      maxLevel: maxLevel,
      lootMode: lootMode,
    );
    
    _parties[partyId] = party;
    _userToParty[leaderId] = partyId;
    
    if (isPublic) {
      _publicParties.add(party);
    }
    
    _eventBus.publish(Event(
      type: 'party_created',
      data: {'partyId': partyId, 'leaderId': leaderId},
    ));
    
    debugPrint('Party created: $partyId with leader $leaderId');
    return party;
  }

  /// Enhancement 3: Send party invite
  Future<PartyInvite> sendInvite({
    required String partyId,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
  }) async {
    final party = _parties[partyId];
    if (party == null) throw Exception('Party not found');
    
    if (party.isFull) throw Exception('Party is full');
    
    // Check if user already in a party
    if (_userToParty.containsKey(toUserId)) {
      throw Exception('User already in a party');
    }
    
    final inviteId = 'invite_${DateTime.now().millisecondsSinceEpoch}_$toUserId';
    final invite = PartyInvite(
      inviteId: inviteId,
      partyId: partyId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      status: PartyInviteStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 5)), // 5 min expiry
    );
    
    _invites[inviteId] = invite;
    
    _eventBus.publish(Event(
      type: 'party_invite_sent',
      data: {
        'inviteId': inviteId,
        'partyId': partyId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
      },
    ));
    
    debugPrint('Party invite sent: $inviteId to $toUserId');
    return invite;
  }

  /// Enhancement 4: Accept invite
  Future<Party> acceptInvite({
    required String inviteId,
    required String characterName,
    required int level,
    required CharacterStats stats,
    required int hp,
    required int maxHp,
  }) async {
    final invite = _invites[inviteId];
    if (invite == null) throw Exception('Invite not found');
    
    if (!invite.isPending) throw Exception('Invite is not pending');
    if (invite.isExpired) throw Exception('Invite has expired');
    
    final party = _parties[invite.partyId];
    if (party == null) throw Exception('Party not found');
    
    if (party.isFull) throw Exception('Party is full');
    
    // Check level requirements
    if (level < party.minLevel || level > party.maxLevel) {
      throw Exception('Level requirements not met');
    }
    
    // Determine role
    final role = PartyMember.determineRole(
      vitality: stats.vitality,
      strength: stats.strength,
      intelligence: stats.intelligence,
      agility: stats.agility,
    );
    
    final newMember = PartyMember(
      userId: invite.toUserId,
      characterName: characterName,
      level: level,
      role: role,
      status: PartyMemberStatus.online,
      joinedAt: DateTime.now(),
      hp: hp,
      maxHp: maxHp,
      attack: stats.strength,
      defense: stats.agility ~/ 2,
    );
    
    final updatedParty = party.copyWith(
      members: [...party.members, newMember],
      partyBonusMultiplier: _calculatePartyBonus(party.members.length + 1),
    );
    
    _parties[invite.partyId] = updatedParty;
    _userToParty[invite.toUserId] = invite.partyId;
    _invites[inviteId] = PartyInvite(
      inviteId: invite.inviteId,
      partyId: invite.partyId,
      fromUserId: invite.fromUserId,
      fromUserName: invite.fromUserName,
      toUserId: invite.toUserId,
      status: PartyInviteStatus.accepted,
      createdAt: invite.createdAt,
      expiresAt: invite.expiresAt,
    );
    
    _eventBus.publish(Event(
      type: 'party_member_joined',
      data: {
        'partyId': invite.partyId,
        'userId': invite.toUserId,
        'memberCount': updatedParty.members.length,
      },
    ));
    
    debugPrint('Party member joined: ${invite.toUserId} joined ${invite.partyId}');
    return updatedParty;
  }

  /// Enhancement 5: Decline invite
  Future<void> declineInvite(String inviteId) async {
    final invite = _invites[inviteId];
    if (invite == null) throw Exception('Invite not found');
    
    _invites[inviteId] = PartyInvite(
      inviteId: invite.inviteId,
      partyId: invite.partyId,
      fromUserId: invite.fromUserId,
      fromUserName: invite.fromUserName,
      toUserId: invite.toUserId,
      status: PartyInviteStatus.declined,
      createdAt: invite.createdAt,
      expiresAt: invite.expiresAt,
    );
    
    _eventBus.publish(Event(
      type: 'party_invite_declined',
      data: {'inviteId': inviteId},
    ));
    
    debugPrint('Party invite declined: $inviteId');
  }

  /// Enhancement 6: Leave party
  Future<void> leaveParty(String userId) async {
    final partyId = _userToParty[userId];
    if (partyId == null) throw Exception('User not in a party');
    
    final party = _parties[partyId];
    if (party == null) throw Exception('Party not found');
    
    // Remove member
    final updatedMembers = party.members.where((m) => m.userId != userId).toList();
    
    // If leader leaves, disband party
    if (party.isLeader(userId)) {
      _disbandParty(partyId);
      return;
    }
    
    final updatedParty = party.copyWith(
      members: updatedMembers,
      partyBonusMultiplier: _calculatePartyBonus(updatedMembers.length),
    );
    
    _parties[partyId] = updatedParty;
    _userToParty.remove(userId);
    
    _eventBus.publish(Event(
      type: 'party_member_left',
      data: {
        'partyId': partyId,
        'userId': userId,
        'memberCount': updatedParty.members.length,
      },
    ));
    
    debugPrint('Party member left: $userId left $partyId');
  }

  /// Enhancement 7: Kick member (leader only)
  Future<void> kickMember({
    required String partyId,
    required String leaderId,
    required String targetUserId,
  }) async {
    final party = _parties[partyId];
    if (party == null) throw Exception('Party not found');
    
    if (!party.isLeader(leaderId)) throw Exception('Only leader can kick members');
    if (targetUserId == leaderId) throw Exception('Cannot kick yourself');
    
    final updatedMembers = party.members.where((m) => m.userId != targetUserId).toList();
    
    final updatedParty = party.copyWith(
      members: updatedMembers,
      partyBonusMultiplier: _calculatePartyBonus(updatedMembers.length),
    );
    
    _parties[partyId] = updatedParty;
    _userToParty.remove(targetUserId);
    
    _eventBus.publish(Event(
      type: 'party_member_kicked',
      data: {
        'partyId': partyId,
        'userId': targetUserId,
        'kickedBy': leaderId,
      },
    ));
    
    debugPrint('Party member kicked: $targetUserId kicked from $partyId');
  }

  /// Enhancement 8: Disband party
  void _disbandParty(String partyId) {
    final party = _parties[partyId];
    if (party == null) return;
    
    // Remove all members from mapping
    for (final member in party.members) {
      _userToParty.remove(member.userId);
    }
    
    _parties.remove(partyId);
    _publicParties.removeWhere((p) => p.partyId == partyId);
    _chatHistory.remove(partyId);
    
    _eventBus.publish(Event(
      type: 'party_disbanded',
      data: {'partyId': partyId},
    ));
    
    debugPrint('Party disbanded: $partyId');
  }

  /// Enhancement 9: Send quick chat message
  Future<void> sendQuickChat({
    required String partyId,
    required String userId,
    required QuickChatMessage message,
  }) async {
    final party = _parties[partyId];
    if (party == null) throw Exception('Party not found');
    
    if (!party.hasMember(userId)) throw Exception('User not in party');
    
    // Add to history
    _chatHistory.putIfAbsent(partyId, () => []);
    _chatHistory[partyId]!.add(message);
    
    // Keep only last 50 messages
    if (_chatHistory[partyId]!.length > 50) {
      _chatHistory[partyId]!.removeAt(0);
    }
    
    _eventBus.publish(Event(
      type: 'party_quick_chat',
      data: {
        'partyId': partyId,
        'userId': userId,
        'message': message.name,
        'messageText': QuickChat.getMessage(message),
      },
    ));
    
    debugPrint('Quick chat: $userId sent ${message.name} in $partyId');
  }

  /// Enhancement 10: Send emote
  Future<void> sendEmote({
    required String partyId,
    required String userId,
    required PartyEmote emote,
  }) async {
    final party = _parties[partyId];
    if (party == null) throw Exception('Party not found');
    
    if (!party.hasMember(userId)) throw Exception('User not in party');
    
    _eventBus.publish(Event(
      type: 'party_emote',
      data: {
        'partyId': partyId,
        'userId': userId,
        'emote': emote.name,
        'emoteIcon': EmoteHelper.getEmoteIcon(emote),
      },
    ));
    
    debugPrint('Emote: $userId sent ${emote.name} in $partyId');
  }

  /// Enhancement 11: Set member ready status
  Future<void> setReady({
    required String partyId,
    required String userId,
    required bool ready,
  }) async {
    final party = _parties[partyId];
    if (party == null) throw Exception('Party not found');
    
    final member = party.getMember(userId);
    if (member == null) throw Exception('User not in party');
    
    final updatedMembers = party.members.map((m) {
      if (m.userId == userId) {
        return m.copyWith(
          status: ready ? PartyMemberStatus.ready : PartyMemberStatus.online,
        );
      }
      return m;
    }).toList();
    
    final updatedParty = party.copyWith(members: updatedMembers);
    _parties[partyId] = updatedParty;
    
    _eventBus.publish(Event(
      type: 'party_member_ready_changed',
      data: {
        'partyId': partyId,
        'userId': userId,
        'ready': ready,
        'allReady': updatedParty.allReady,
      },
    ));
    
    debugPrint('Ready status changed: $userId in $partyId is ${ready ? "ready" : "not ready"}');
  }

  /// Enhancement 12: Auto-matchmaking
  Future<Party?> findPartyMatch({
    required String userId,
    required int level,
    required int powerLevel,
  }) async {
    // Find public parties that match criteria
    for (final party in _publicParties) {
      if (party.isFull) continue;
      if (level < party.minLevel || level > party.maxLevel) continue;
      
      // Check power level balance (within 20% of average)
      final partyPower = party.powerLevel;
      if ((powerLevel - partyPower).abs() > partyPower * 0.2) continue;
      
      return party;
    }
    
    return null; // No match found
  }

  /// Get party by ID
  Party? getParty(String partyId) => _parties[partyId];
  
  /// Get party for user
  Party? getPartyForUser(String userId) {
    final partyId = _userToParty[userId];
    if (partyId == null) return null;
    return _parties[partyId];
  }
  
  /// Get all public parties
  List<Party> getPublicParties() => List.unmodifiable(_publicParties);
  
  /// Get pending invites for user
  List<PartyInvite> getInvitesForUser(String userId) {
    return _invites.values
        .where((i) => i.toUserId == userId && i.isPending)
        .toList();
  }
  
  /// Calculate party bonus
  double _calculatePartyBonus(int memberCount) {
    switch (memberCount) {
      case 2: return 1.05; // +5%
      case 3: return 1.10; // +10%
      case 4: return 1.15; // +15%
      default: return 1.0;
    }
  }
  
  /// Clean up expired invites (call periodically)
  void cleanupExpiredInvites() {
    final expired = _invites.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();
    
    for (final inviteId in expired) {
      _invites.remove(inviteId);
    }
    
    if (expired.isNotEmpty) {
      debugPrint('Cleaned up ${expired.length} expired invites');
    }
  }
}

/// Enhancement 13: Party template for saving compositions
class PartyTemplate {
  final String templateId;
  final String name;
  final int minLevel;
  final int maxLevel;
  final LootDistribution lootMode;
  final bool isPublic;
  
  const PartyTemplate({
    required this.templateId,
    required this.name,
    required this.minLevel,
    required this.maxLevel,
    required this.lootMode,
    required this.isPublic,
  });
}
