import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class MapClusteringService {
  static const double _clusterRadius = 0.01; // ~1km radius
  static const int _maxClusterSize = 10;

  static List<ClusterMarker> clusterMarkers(List<QuestMarker> markers, double zoom) {
    if (zoom > 15) {
      // At high zoom, show individual markers
      return markers.map((marker) => ClusterMarker(
        position: marker.position,
        markers: [marker],
        isCluster: false,
      )).toList();
    }

    final clusters = <ClusterMarker>[];
    final processed = <String>{};

    for (final marker in markers) {
      if (processed.contains(marker.questId)) continue;

      final nearbyMarkers = <QuestMarker>[marker];
      processed.add(marker.questId);

      // Find nearby markers
      for (final otherMarker in markers) {
        if (processed.contains(otherMarker.questId)) continue;

        final distance = _calculateDistance(marker.position, otherMarker.position);
        if (distance <= _clusterRadius) {
          nearbyMarkers.add(otherMarker);
          processed.add(otherMarker.questId);
        }
      }

      if (nearbyMarkers.length == 1) {
        // Single marker
        clusters.add(ClusterMarker(
          position: marker.position,
          markers: [marker],
          isCluster: false,
        ));
      } else {
        // Cluster
        final clusterPosition = _calculateClusterCenter(nearbyMarkers);
        clusters.add(ClusterMarker(
          position: clusterPosition,
          markers: nearbyMarkers,
          isCluster: true,
        ));
      }
    }

    return clusters;
  }

  static double _calculateDistance(LatLng pos1, LatLng pos2) {
    final lat1 = pos1.latitude * pi / 180;
    final lat2 = pos2.latitude * pi / 180;
    final dLat = (pos2.latitude - pos1.latitude) * pi / 180;
    final dLng = (pos2.longitude - pos1.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return 6371000 * c; // Earth's radius in meters
  }

  static LatLng _calculateClusterCenter(List<QuestMarker> markers) {
    double totalLat = 0;
    double totalLng = 0;

    for (final marker in markers) {
      totalLat += marker.position.latitude;
      totalLng += marker.position.longitude;
    }

    return LatLng(
      totalLat / markers.length,
      totalLng / markers.length,
    );
  }
}

class QuestMarker {
  final String questId;
  final LatLng position;
  final QuestType questType;
  final String title;
  final int level;

  QuestMarker({
    required this.questId,
    required this.position,
    required this.questType,
    required this.title,
    required this.level,
  });
}

class ClusterMarker {
  final LatLng position;
  final List<QuestMarker> markers;
  final bool isCluster;

  ClusterMarker({
    required this.position,
    required this.markers,
    required this.isCluster,
  });

  String get displayText {
    if (!isCluster) return markers.first.title;
    return '${markers.length} Quests';
  }

  Color get clusterColor {
    if (!isCluster) return _getQuestTypeColor(markers.first.questType);
    
    // Mix colors for clusters
    final colors = markers.map((m) => _getQuestTypeColor(m.questType)).toList();
    return _blendColors(colors);
  }

  Color _getQuestTypeColor(QuestType type) {
    switch (type) {
      case QuestType.battle:
        return Colors.red;
      case QuestType.treasure:
        return Colors.blue;
      case QuestType.location:
        return Colors.green;
      case QuestType.story:
        return Colors.purple;
      case QuestType.fitness:
        return Colors.orange;
      case QuestType.social:
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  Color _blendColors(List<Color> colors) {
    if (colors.isEmpty) return Colors.grey;
    if (colors.length == 1) return colors.first;

    int totalR = 0, totalG = 0, totalB = 0;
    for (final color in colors) {
      totalR += color.red;
      totalG += color.green;
      totalB += color.blue;
    }

    return Color.fromARGB(
      255,
      totalR ~/ colors.length,
      totalG ~/ colors.length,
      totalB ~/ colors.length,
    );
  }
}
