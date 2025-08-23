import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card_model.g.dart';

enum CardType { weapon, armor, spell, consumable, misc }

enum CardRarity { common, uncommon, rare, epic, legendary }

enum EquipmentSlot { head, chest, legs, weapon, offhand, ring, amulet }

@JsonSerializable()
class GameCard extends Equatable {
  const GameCard({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    this.allowedClasses,
    this.stats,
    this.lore,
  });

  final String id;
  final String name;
  final CardType type;
  final CardRarity rarity;
  final List<String>? allowedClasses;
  final Map<String, num>? stats; // e.g., {"atk": 5, "def": 2}
  final String? lore;

  factory GameCard.fromJson(Map<String, dynamic> json) => _$GameCardFromJson(json);
  Map<String, dynamic> toJson() => _$GameCardToJson(this);

  @override
  List<Object?> get props => [id, name, type, rarity, allowedClasses, stats, lore];
}