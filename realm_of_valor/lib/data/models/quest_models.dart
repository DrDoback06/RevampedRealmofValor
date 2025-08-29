import 'package:equatable/equatable.dart';

class Quest extends Equatable {
  final String id;
  final String title;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final List<String> tags;
  final Map<String, dynamic> rewards;
  final String difficulty;
  final DateTime? timeLimit;
  final bool isCompleted;
  final DateTime createdAt;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.tags,
    required this.rewards,
    required this.difficulty,
    this.timeLimit,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      tags: List<String>.from(json['tags'] ?? []),
      rewards: Map<String, dynamic>.from(json['rewards'] ?? {}),
      difficulty: json['difficulty'] ?? 'normal',
      timeLimit: json['timeLimit'] != null 
          ? DateTime.parse(json['timeLimit']) 
          : null,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'rewards': rewards,
      'difficulty': difficulty,
      'timeLimit': timeLimit?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Quest copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? tags,
    Map<String, dynamic>? rewards,
    String? difficulty,
    DateTime? timeLimit,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      rewards: rewards ?? this.rewards,
      difficulty: difficulty ?? this.difficulty,
      timeLimit: timeLimit ?? this.timeLimit,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id, 
    title, 
    description, 
    location, 
    latitude, 
    longitude, 
    tags, 
    rewards, 
    difficulty, 
    timeLimit, 
    isCompleted, 
    createdAt
  ];
}
