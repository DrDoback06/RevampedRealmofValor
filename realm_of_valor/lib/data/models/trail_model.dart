import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TrailDifficulty { easy, moderate, hard, expert }
enum TrailType { hiking, running, cycling, walking, mountainBiking }

class Trail {
  final String id;
  final String name;
  final String description;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng> waypoints;
  final double distance; // in meters
  final double elevationGain; // in meters
  final TrailDifficulty difficulty;
  final TrailType type;
  final List<String> tags; // e.g., ['scenic', 'forest', 'mountain']
  final String region;
  final String country;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
  final Map<String, dynamic> metadata; // Additional data

  const Trail({
    required this.id,
    required this.name,
    required this.description,
    required this.startLocation,
    required this.endLocation,
    required this.waypoints,
    required this.distance,
    required this.elevationGain,
    required this.difficulty,
    required this.type,
    required this.tags,
    required this.region,
    required this.country,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.imageUrl,
    this.metadata = const {},
  });

  factory Trail.fromJson(Map<String, dynamic> json) {
    return Trail(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startLocation: LatLng(
        json['startLocation']['latitude'] as double,
        json['startLocation']['longitude'] as double,
      ),
      endLocation: LatLng(
        json['endLocation']['latitude'] as double,
        json['endLocation']['longitude'] as double,
      ),
      waypoints: (json['waypoints'] as List)
          .map((point) => LatLng(
                point['latitude'] as double,
                point['longitude'] as double,
              ))
          .toList(),
      distance: json['distance'] as double,
      elevationGain: json['elevationGain'] as double,
      difficulty: TrailDifficulty.values.firstWhere(
        (e) => e.toString() == 'TrailDifficulty.${json['difficulty']}',
      ),
      type: TrailType.values.firstWhere(
        (e) => e.toString() == 'TrailType.${json['type']}',
      ),
      tags: List<String>.from(json['tags']),
      region: json['region'] as String,
      country: json['country'] as String,
      rating: json['rating'] as double? ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startLocation': {
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
      },
      'endLocation': {
        'latitude': endLocation.latitude,
        'longitude': endLocation.longitude,
      },
      'waypoints': waypoints
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(),
      'distance': distance,
      'elevationGain': elevationGain,
      'difficulty': difficulty.toString().split('.').last,
      'type': type.toString().split('.').last,
      'tags': tags,
      'region': region,
      'country': country,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  Trail copyWith({
    String? id,
    String? name,
    String? description,
    LatLng? startLocation,
    LatLng? endLocation,
    List<LatLng>? waypoints,
    double? distance,
    double? elevationGain,
    TrailDifficulty? difficulty,
    TrailType? type,
    List<String>? tags,
    String? region,
    String? country,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Trail(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      waypoints: waypoints ?? this.waypoints,
      distance: distance ?? this.distance,
      elevationGain: elevationGain ?? this.elevationGain,
      difficulty: difficulty ?? this.difficulty,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      region: region ?? this.region,
      country: country ?? this.country,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}
