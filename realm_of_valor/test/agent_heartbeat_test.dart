import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/services/base_agent.dart';
import 'package:realm_of_valor/services/event_bus.dart';

class TestAgent extends BaseAgent {
  TestAgent(super.bus) : super(heartbeatInterval: const Duration(milliseconds: 100));
  @override
  String get name => 'TestAgent';
  @override
  Future<void> onInitialize() async {}
  @override
  Future<void> onDispose() async {}
}

void main() {
  test('Agent emits heartbeat events', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);

    final agent = TestAgent(bus);
    await agent.initialize();

    final completer = Completer<void>();
    final sub = bus.stream.listen((evt) {
      if (evt.type == 'agent.heartbeat' && evt.data?['agent'] == 'TestAgent') {
        completer.complete();
      }
    });
    addTearDown(sub.cancel);

    await completer.future.timeout(const Duration(seconds: 2));
  });
}