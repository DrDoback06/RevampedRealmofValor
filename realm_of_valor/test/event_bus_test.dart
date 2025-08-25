import 'package:flutter_test/flutter_test.dart';
import 'package:realm_of_valor/services/event_bus.dart';

void main() {
  test('EventBus request/response works', () async {
    final bus = EventBus();
    addTearDown(bus.dispose);

    bus.subscribe('ping', (evt, b) {
      b.replyTo(evt, data: {'pong': true});
    });

    final resp = await bus.request(type: 'ping');
    expect(resp.type, 'ping.response');
    expect(resp.data?['pong'], true);
  });
}
