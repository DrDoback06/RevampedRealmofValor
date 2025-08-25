class BattleEntity {
  BattleEntity({required this.id, required this.name, required this.hp, required this.atk, required this.def});

  final String id;
  final String name;
  int hp;
  final int atk;
  final int def;
}

class BattleState {
  BattleState({required this.player, required this.enemy}) : turn = 0, ended = false, winnerId = null;

  final BattleEntity player;
  final BattleEntity enemy;
  int turn;
  bool ended;
  String? winnerId;
}
