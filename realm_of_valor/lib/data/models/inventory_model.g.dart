// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardInstance _$CardInstanceFromJson(Map<String, dynamic> json) => CardInstance(
      instanceId: json['instanceId'] as String,
      cardId: json['cardId'] as String,
      durability: (json['durability'] as num?)?.toInt() ?? 100,
      upgrades: (json['upgrades'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ),
      flags: json['flags'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CardInstanceToJson(CardInstance instance) =>
    <String, dynamic>{
      'instanceId': instance.instanceId,
      'cardId': instance.cardId,
      'durability': instance.durability,
      'upgrades': instance.upgrades,
      'flags': instance.flags,
    };

Inventory _$InventoryFromJson(Map<String, dynamic> json) => Inventory(
      ownerUid: json['ownerUid'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CardInstance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CardInstance>[],
      gold: (json['gold'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$InventoryToJson(Inventory instance) => <String, dynamic>{
      'ownerUid': instance.ownerUid,
      'items': instance.items,
      'gold': instance.gold,
    };
