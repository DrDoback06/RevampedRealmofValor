import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inventory_model.g.dart';

@JsonSerializable()
class CardInstance extends Equatable {
  const CardInstance({
    required this.instanceId,
    required this.cardId,
    this.durability = 100,
    this.upgrades,
    this.flags,
  });

  final String instanceId;
  final String cardId;
  final int durability;
  final Map<String, num>? upgrades;
  final Map<String, dynamic>? flags;

  factory CardInstance.fromJson(Map<String, dynamic> json) => _$CardInstanceFromJson(json);
  Map<String, dynamic> toJson() => _$CardInstanceToJson(this);

  @override
  List<Object?> get props => [instanceId, cardId, durability, upgrades, flags];
}

@JsonSerializable()
class Inventory extends Equatable {
  const Inventory({
    required this.ownerUid,
    this.items = const <CardInstance>[],
    this.gold = 0,
  });

  final String ownerUid;
  final List<CardInstance> items;
  final int gold;

  factory Inventory.fromJson(Map<String, dynamic> json) => _$InventoryFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryToJson(this);

  @override
  List<Object?> get props => [ownerUid, items, gold];
}