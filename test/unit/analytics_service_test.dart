import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:adm_ai/services/analytics_service.dart';

void main() {
  late Directory tempDir;
  late AnalyticsService analytics;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('adm_ai_analytics_test');
    Hive.init(tempDir.path);
    analytics = AnalyticsService();
    await analytics.ensureInitialized();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  // [_dispatch] persists fire-and-forget so tests give the write a tick to land.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('AnalyticsService', () {
    test('track persists an event with its properties', () async {
      analytics.track('message_sent', {'isVoice': true});
      await settle();

      final events = analytics.recentEvents();
      expect(events, hasLength(1));
      expect(events.single['event'], 'message_sent');
      expect(events.single['properties'], {'isVoice': true});
      expect(events.single['ts'], isA<String>());
    });

    test('screenView records a screen_view event with the screen name', () async {
      analytics.screenView('chat');
      await settle();

      final events = analytics.recentEvents();
      expect(events.single['event'], 'screen_view');
      expect(events.single['properties'], {'screen': 'chat'});
    });

    test('recentEvents returns events in chronological order, capped at limit', () async {
      for (var i = 0; i < 5; i++) {
        analytics.track('event_$i');
        await settle();
      }

      final events = analytics.recentEvents(limit: 3);
      expect(events, hasLength(3));
      expect(events.map((e) => e['event']), ['event_2', 'event_3', 'event_4']);
    });

    test('clear removes all stored events', () async {
      analytics.track('a');
      analytics.track('b');
      await settle();

      await analytics.clear();

      expect(analytics.recentEvents(), isEmpty);
    });
  });
}
