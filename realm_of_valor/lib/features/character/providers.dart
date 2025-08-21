import 'package:flutter_riverpod/flutter_riverpod.dart';

final characterStatsProvider = StateProvider<Map<String, int>>((ref) {
  return <String, int>{'level': 1, 'strength': 5, 'agility': 5, 'intelligence': 5};
});
