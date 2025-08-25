import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/data/sources/firebase_service.dart';
import 'package:realm_of_valor/data/sources/local_store.dart';
import 'package:realm_of_valor/services/agents/data_persistence_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

class FakeStore implements PersistenceStore {
  Map<String, Map<String, dynamic>> store = {};
  @override
  Future<Map<String, dynamic>?> getDocument({required String path}) async => store[path];
  @override
  Future<void> setData({required String path, required Map<String, dynamic> data, bool merge = true}) async {
    store[path] = data;
  }
}

class MemoryLocalStore extends LocalStore {
  MemoryLocalStore(this.map) : super(null);
  final Map<String, String> map;
  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    map[key] = jsonEncode(value);
  }
  @override
  Map<String, dynamic>? getJson(String key) {
    final v = map[key];
    return v == null ? null : Map<String, dynamic>.from(jsonDecode(v) as Map);
  }
}

void main() {
  test('Save writes to cache and cloud; load falls back to cache when offline', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);

    final fake = FakeStore();
    final mem = <String, String>{};
    final local = MemoryLocalStore(mem);
    final agent = DataPersistenceAgent(bus, firebase: fake, local: local);
    await agent.initialize();

    bus.publish(Event(type: 'data.save', data: {'entity': 'character', 'id': 'c1', 'payload': {'xp': 10}}));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(mem.containsKey('character:c1'), true);

    bus.publish(Event(type: 'persistence.offline'));

    final resp = await bus.request(type: 'data.load', data: {'entity': 'character', 'id': 'c1'});
    expect(resp.data?['data'], isNotNull);
  });
}
