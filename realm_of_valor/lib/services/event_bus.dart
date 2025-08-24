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

typedef EventInterceptor = Event? Function(Event event);

typedef EventSchema = bool Function(Map<String, dynamic>? data);

class _Subscriber {
  _Subscriber(this.type, this.handler);
  final String type;
  final EventHandler handler;
}

class EventBusStats {
  EventBusStats({required this.queueLength, required this.droppedTotal, required this.droppedByType});
  final int queueLength;
  final int droppedTotal;
  final Map<String, int> droppedByType;
}

class EventBus {
  final List<_Subscriber> _subscribers = <_Subscriber>[];
  final List<Event> _queue = <Event>[];
  bool _draining = false;

  final List<EventInterceptor> _interceptors = <EventInterceptor>[];
  final Map<String, EventSchema> _schemas = <String, EventSchema>{};

  int _maxQueueSize = 1000;
  int _dropped = 0;
  final Map<String, int> _dropsByType = <String, int>{};

  StreamController<Event> get _streamController => _controller ??= StreamController<Event>.broadcast();
  StreamController<Event>? _controller;

  void dispose() {
    _controller?.close();
    _interceptors.clear();
    _subscribers.clear();
    _queue.clear();
    _schemas.clear();
  }

  Stream<Event> get stream => _streamController.stream;

  VoidCallback subscribe(String type, EventHandler handler) {
    final sub = _Subscriber(type, handler);
    _subscribers.add(sub);
    return () => _subscribers.remove(sub);
  }

  VoidCallback addInterceptor(EventInterceptor interceptor) {
    _interceptors.add(interceptor);
    return () => _interceptors.remove(interceptor);
  }

  void registerSchema(String type, EventSchema schema) {
    _schemas[type] = schema;
  }

  void setMaxQueueSize(int size) {
    _maxQueueSize = size.clamp(100, 100000);
  }

  EventBusStats getStats() => EventBusStats(
        queueLength: _queue.length,
        droppedTotal: _dropped,
        droppedByType: Map<String, int>.from(_dropsByType),
      );

  void publish(Event event) {
    var current = event;

    // Interceptors
    for (final interceptor in List<EventInterceptor>.from(_interceptors)) {
      final result = interceptor(current);
      if (result == null) {
        _recordDrop(current);
        return;
      }
      current = result;
    }

    // Optional schema validation
    final schema = _schemas[current.type];
    if (schema != null && !schema(current.data)) {
      _recordDrop(current);
      return;
    }

    // Backpressure: if queue is full, drop low-priority or oldest
    if (_queue.length >= _maxQueueSize) {
      final idxLow = _queue.indexWhere((e) => e.priority == EventPriority.low);
      if (idxLow != -1) {
        _recordDrop(_queue[idxLow]);
        _queue.removeAt(idxLow);
      } else if (current.priority == EventPriority.low) {
        _recordDrop(current);
        return;
      } else {
        // make room by dropping the oldest non-critical if possible
        final idxNonCritical = _queue.indexWhere((e) => e.priority != EventPriority.critical);
        final dropIdx = idxNonCritical != -1 ? idxNonCritical : 0;
        _recordDrop(_queue[dropIdx]);
        _queue.removeAt(dropIdx);
      }
    }

    _queue.add(current);
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

  void _recordDrop(Event e) {
    _dropped += 1;
    _dropsByType.update(e.type, (v) => v + 1, ifAbsent: () => 1);
  }

  void _scheduleDrain() {
    if (_draining) return;
    _draining = true;
    scheduleMicrotask(_drain);
  }

  Future<void> _drain() async {
    try {
      _queue.sort((a, b) {
        final p = a.priority.index.compareTo(b.priority.index);
        if (p != 0) return p;
        return a.timestamp.compareTo(b.timestamp);
      });

      while (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        for (final sub in List<_Subscriber>.from(_subscribers)) {
          if (sub.type == next.type) {
            try {
              await sub.handler(next, this);
            } catch (e, st) {
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