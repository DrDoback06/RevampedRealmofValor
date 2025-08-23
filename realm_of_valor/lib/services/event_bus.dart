import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum EventPriority { critical, high, normal, low }

class Event {
  Event({
    required this.type,
    this.data,
    this.priority = EventPriority.normal,
    String? id,
    this.correlationId,
    this.expectsReply = false,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  final String id;
  final String type;
  final Map<String, dynamic>? data;
  final EventPriority priority;
  final String? correlationId;
  final bool expectsReply;
  final DateTime timestamp;
}

typedef EventHandler = FutureOr<void> Function(Event event, EventBus bus);

class _Subscriber {
  _Subscriber(this.type, this.handler);
  final String type;
  final EventHandler handler;
}

class EventBus {
  final List<_Subscriber> _subscribers = <_Subscriber>[];
  final List<Event> _queue = <Event>[];
  bool _draining = false;

  StreamController<Event> get _streamController => _controller ??= StreamController<Event>.broadcast();
  StreamController<Event>? _controller;

  void dispose() {
    _controller?.close();
  }

  Stream<Event> get stream => _streamController.stream;

  VoidCallback subscribe(String type, EventHandler handler) {
    final sub = _Subscriber(type, handler);
    _subscribers.add(sub);
    return () => _subscribers.remove(sub);
  }

  void publish(Event event) {
    _queue.add(event);
    _scheduleDrain();
  }

  Future<Event> request({
    required String type,
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final correlationId = const Uuid().v4();
    final completer = Completer<Event>();

    late VoidCallback cancel;
    cancel = subscribe('$type.response', (evt, bus) {
      if (evt.correlationId == correlationId && !completer.isCompleted) {
        completer.complete(evt);
        cancel();
      }
    });

    publish(Event(
      type: type,
      data: data,
      priority: EventPriority.high,
      correlationId: correlationId,
      expectsReply: true,
    ));

    return completer.future.timeout(timeout, onTimeout: () {
      cancel();
      throw TimeoutException('Request $type timed out');
    });
  }

  void replyTo(Event request, {Map<String, dynamic>? data}) {
    publish(Event(
      type: '${request.type}.response',
      data: data,
      correlationId: request.correlationId,
      priority: request.priority,
    ));
  }

  void _scheduleDrain() {
    if (_draining) return;
    _draining = true;
    scheduleMicrotask(_drain);
  }

  Future<void> _drain() async {
    try {
      // Sort by priority then timestamp (stable order for FIFO within priority)
      _queue.sort((a, b) {
        final p = a.priority.index.compareTo(b.priority.index);
        if (p != 0) return p;
        return a.timestamp.compareTo(b.timestamp);
      });

      while (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        // Deliver to matching subscribers
        for (final sub in List<_Subscriber>.from(_subscribers)) {
          if (sub.type == next.type) {
            try {
              await sub.handler(next, this);
            } catch (e, st) {
              // Also forward error to stream for optional global listeners
              _streamController.addError(e, st);
            }
          }
        }
        _streamController.add(next);
      }
    } finally {
      _draining = false;
      if (_queue.isNotEmpty) _scheduleDrain();
    }
  }
}