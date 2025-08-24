import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quest_model.g.dart';

enum QuestType { story, daily, weekly, location, fitness, battle }

enum QuestStatus { notStarted, inProgress, completed, claimed }

@JsonSerializable()
class QuestObjective extends Equatable {
  const QuestObjective({
    required this.id,
    required this.description,
    this.target = 1,
    this.progress = 0,
  });

  final String id;
  final String description;
  final int target;
  final int progress;

  factory QuestObjective.fromJson(Map<String, dynamic> json) => _$QuestObjectiveFromJson(json);
  Map<String, dynamic> toJson() => _$QuestObjectiveToJson(this);

  @override
  List<Object?> get props => [id, description, target, progress];
}

@JsonSerializable()
class Quest extends Equatable {
  const Quest({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    this.objectives = const <QuestObjective>[],
    this.rewardXp = 0,
  });

  final String id;
  final String title;
  final QuestType type;
  final QuestStatus status;
  final List<QuestObjective> objectives;
  final int rewardXp;

  factory Quest.fromJson(Map<String, dynamic> json) => _$QuestFromJson(json);
  Map<String, dynamic> toJson() => _$QuestToJson(this);

  @override
  List<Object?> get props => [id, title, type, status, objectives, rewardXp];
}