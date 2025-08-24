import '../base_agent.dart';
import '../event_bus.dart';
import '../../data/models/battle_model.dart';

class BattleSystemAgent extends BaseAgent {
  BattleSystemAgent(super.bus);

  BattleState? _state;

  @override
  String get name => 'BattleSystem';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('battle.start', _onStart);
    bus.subscribe('battle.command', _onCommand);
  }

  @override
  Future<void> onDispose() async {}

  void _onStart(Event evt, EventBus b) {
    final player = BattleEntity(
      id: 'player',
      name: evt.data?['player_name'] as String? ?? 'Hero',
      hp: (evt.data?['player_hp'] as num?)?.toInt() ?? 100,
      atk: (evt.data?['player_atk'] as num?)?.toInt() ?? 20,
      def: (evt.data?['player_def'] as num?)?.toInt() ?? 5,
    );
    final enemy = BattleEntity(
      id: 'enemy',
      name: evt.data?['enemy_name'] as String? ?? 'Slime',
      hp: (evt.data?['enemy_hp'] as num?)?.toInt() ?? 60,
      atk: (evt.data?['enemy_atk'] as num?)?.toInt() ?? 12,
      def: (evt.data?['enemy_def'] as num?)?.toInt() ?? 2,
    );
    _state = BattleState(player: player, enemy: enemy);
    b.publish(Event(type: 'battle_started'));
    _emitTurn();
  }

  void _onCommand(Event evt, EventBus b) {
    final s = _state;
    if (s == null || s.ended) return;
    final action = evt.data?['action'] as String? ?? 'attack';
    if (action == 'attack') {
      _applyAttack(attacker: s.player, defender: s.enemy, b: b);
    }
    if (!s.ended) {
      // Enemy simple AI: always attack
      _applyAttack(attacker: s.enemy, defender: s.player, b: b);
    }
    _emitTurn();
  }

  void _applyAttack({required BattleEntity attacker, required BattleEntity defender, required EventBus b}) {
    final damage = (attacker.atk - defender.def).clamp(0, 9999);
    if (damage > 0) defender.hp = (defender.hp - damage).clamp(0, 9999);
    b.publish(Event(type: 'battle_turn_resolved', data: {
      'attacker': attacker.id,
      'defender': defender.id,
      'damage': damage,
      'player_hp': _state?.player.hp,
      'enemy_hp': _state?.enemy.hp,
    }));
    _checkEnd(b);
  }

  void _checkEnd(EventBus b) {
    final s = _state!;
    if (s.player.hp <= 0 || s.enemy.hp <= 0) {
      s.ended = true;
      s.winnerId = s.player.hp > 0 ? s.player.id : s.enemy.id;
      b.publish(Event(type: 'battle_ended', data: {'winner': s.winnerId, 'xp': s.winnerId == 'player' ? 50 : 0}));
    }
  }

  void _emitTurn() {
    final s = _state!;
    s.turn += 1;
    bus.publish(Event(type: 'battle_state', data: {
      'turn': s.turn,
      'player_hp': s.player.hp,
      'enemy_hp': s.enemy.hp,
    }));
  }
}