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
    bus.subscribe('data.load', _onLoad);
  }

  @override
  Future<void> onDispose() async {}

  Future<void> _onSave(Event evt, EventBus b) async {
    try {
      final entity = evt.data?['entity'] as String?;
      if (entity == null) return;

      if (entity == 'character') {
        final uid = evt.data?['uid'] as String?;
        final id = evt.data?['id'] as String?;
        final payload = evt.data?['payload'] as Map<String, dynamic>?;
        if (id == null) return;

        if (payload != null) {
          await local.setJson('character:$id', payload);
        }

        if (_online) {
          try {
            await firebase.setData(path: FirestorePaths.characterDoc(uid ?? 'me', id), data: payload ?? {});
          } on FirebaseException {
            _setOffline();
          }
        }

        b.publish(Event(type: 'data.save.completed', data: {'entity': entity, 'id': id}));
      }
    } catch (_) {
      _setOffline();
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

  void setOnlineForTests() {
    _online = true;
    bus.publish(Event(type: 'persistence.online'));
  }
}