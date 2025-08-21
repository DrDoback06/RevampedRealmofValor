import 'package:flutter_riverpod/flutter_riverpod.dart';

final inventoryItemsProvider = StateProvider<List<String>>((ref) => const []);
