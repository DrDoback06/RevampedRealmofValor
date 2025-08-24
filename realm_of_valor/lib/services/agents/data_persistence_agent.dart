import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/sources/firebase_service.dart';
import '../../data/sources/firestore_paths.dart';
import '../../data/sources/local_store.dart';
import '../base_agent.dart';
import '../event_bus.dart';

class DataPersistenceAgent extends BaseAgent {
  DataPersistenceAgent(super.bus, {required this.firebase, required this.local});

  final PersistenceStore firebase;
  final LocalStore local;

  bool _online = true;

  @override
  String get name => 'DataPersistence';

  @override
  Future<void> onInitialize() async {
    bus.subscribe('data.save', _onSave);
    bus.subscribe('data.save_batch', _onSaveBatch);
    bus.subscribe('data.load', _onLoad);
    _replayOfflineQueue();
  }

  @override
  Future<void> onDispose() async {}

  Future<void> _onSave(Event evt, EventBus b) async {
    try {
      final entity = evt.data?['entity'] as String?;
      if (entity == null) return;

      if (entity == 'character') {
        final uid = evt.data?['uid'] as String? ?? 'me';
        final id = evt.data?['id'] as String?;
        final payload = evt.data?['payload'] as Map<String, dynamic>? ?? {};
        if (id == null) return;

        // Versioning
        final version = (payload['version'] as int?) ?? 0;
        final next = {...payload, 'version': version + 1};

        await local.setJson('character:$id', next);

        if (_online && firebase is FirebaseService) {
          try {
            await (firebase as FirebaseService).setData(path: FirestorePaths.characterDoc(uid, id), data: next);
          } on FirebaseException {
            _setOffline();
            await _enqueueOffline({'type': 'data.save', 'data': evt.data});
          }
        } else {
          await _enqueueOffline({'type': 'data.save', 'data': evt.data});
        }

        b.publish(Event(type: 'data.save.completed', data: {'entity': entity, 'id': id}));
      }
    } catch (_) {
      _setOffline();
      await _enqueueOffline({'type': 'data.save', 'data': evt.data});
    }
  }

  Future<void> _onSaveBatch(Event evt, EventBus b) async {
    if (firebase is! FirebaseService) return;
    final ops = List<Map<String, dynamic>>.from(evt.data?['ops'] as List? ?? const []);
    if (ops.isEmpty) return;
    final typed = <({String path, Map<String, dynamic> data, bool merge})>[];
    for (final op in ops) {
      typed.add((path: op['path'] as String, data: Map<String, dynamic>.from(op['data'] as Map), merge: (op['merge'] as bool?) ?? true));
    }
    try {
      await (firebase as FirebaseService).batchSet(typed);
      b.publish(Event(type: 'data.save.completed', data: {'batch': true}));
    } on FirebaseException {
      _setOffline();
      await _enqueueOffline({'type': 'data.save_batch', 'data': evt.data});
    }
  }

  Future<void> _onLoad(Event evt, EventBus b) async {
    final entity = evt.data?['entity'] as String?;
    if (entity == null) return;

    if (entity == 'character') {
      final uid = evt.data?['uid'] as String? ?? 'me';
      final id = evt.data?['id'] as String?;
      if (id == null) return;

      Map<String, dynamic>? data;

      if (_online) {
        try {
          data = await firebase.getDocument(path: FirestorePaths.characterDoc(uid, id));
        } on FirebaseException {
          _setOffline();
        }
      }

      data ??= local.getJson('character:$id');

      if (evt.expectsReply) {
        b.replyTo(evt, data: {'data': data});
      } else {
        b.publish(Event(type: 'data.loaded', data: {'entity': entity, 'id': id, 'data': data}));
      }
    }
  }

  void _setOffline() {
    if (_online) {
      _online = false;
      bus.publish(Event(type: 'persistence.offline'));
    }
  }

  Future<void> _enqueueOffline(Map<String, dynamic> e) async {
    final q = List<Map<String, dynamic>>.from(local.getJson('offline_queue')?['items'] as List? ?? const []);
    q.add(e);
    await local.setJson('offline_queue', {'items': q});
  }

  Future<void> _replayOfflineQueue() async {
    final json = local.getJson('offline_queue');
    final items = List<Map<String, dynamic>>.from(json?['items'] as List? ?? const []);
    if (items.isEmpty) return;
    for (final e in items) {
      final type = e['type'] as String;
      final data = Map<String, dynamic>.from(e['data'] as Map);
      bus.publish(Event(type: type, data: data));
    }
    await local.setJson('offline_queue', {'items': []});
  }

  void setOnlineForTests() {
    _online = true;
    bus.publish(Event(type: 'persistence.online'));
  }
}