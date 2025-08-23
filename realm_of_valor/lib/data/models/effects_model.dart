import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'effects_model.g.dart';

enum EffectType { buff, debuff, dot, hot, shield }

@JsonSerializable()
class Effect extends Equatable {
  const Effect({
    required this.id,
    required this.type,
    required this.modifiers,
    this.durationTurns,
  });

  final String id;
  final EffectType type;
  final Map<String, num> modifiers; // e.g., {"atk%": 10}
  final int? durationTurns;

  factory Effect.fromJson(Map<String, dynamic> json) => _$EffectFromJson(json);
  Map<String, dynamic> toJson() => _$EffectToJson(this);

  @override
  List<Object?> get props => [id, type, modifiers, durationTurns];
}