import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import 'crash_reporting_service.dart';

/// Lightweight, provider-agnostic event tracking.
///
/// Hooking up a hosted analytics platform (Mixpanel, Amplitude, PostHog,
/// Firebase Analytics, ...) requires creating a project there and wiring in
/// its SDK + write key -- something only the product owner can do, and a
/// decision best made once you know which platform you'll actually pay for.
///
/// Until that's decided, [AnalyticsService] still gives you real value:
/// - every tracked event becomes a Sentry breadcrumb (via
///   [CrashReportingService]), so crash reports show what the user was
///   doing right before the crash
/// - events are also persisted to a local Hive box (capped, rolling) and
///   logged, so they can be inspected on-device or exported for later
///   import into whichever platform you choose
///
/// Swapping in a real provider later only means changing [_dispatch] --
/// every call site (`AnalyticsService().track('...')`) stays the same.
class AnalyticsService {
  static const boxName = 'analytics_events';
  static const _maxStoredEvents = 500;

  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final Logger _logger = Logger();

  Box? get _box => Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null;

  Future<void> ensureInitialized() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  void track(String event, [Map<String, Object?> properties = const {}]) {
    _dispatch(event, properties);
  }

  void screenView(String screenName) {
    _dispatch('screen_view', {'screen': screenName});
  }

  void _dispatch(String event, Map<String, Object?> properties) {
    final entry = {
      'event': event,
      'properties': properties,
      'ts': DateTime.now().toIso8601String(),
    };

    _logger.d('[analytics] $event $properties');
    CrashReportingService.breadcrumb(
      properties.isEmpty ? event : '$event ${properties.toString()}',
      category: 'analytics',
    );
    _persist(entry);
  }

  Future<void> _persist(Map<String, Object?> entry) async {
    final box = _box;
    if (box == null) return;
    await box.add(entry);
    if (box.length > _maxStoredEvents) {
      final extra = box.length - _maxStoredEvents;
      for (final key in box.keys.take(extra).toList()) {
        await box.delete(key);
      }
    }
  }

  /// Recent events in chronological order -- useful for an in-app debug
  /// view or for exporting to whichever analytics platform you settle on.
  List<Map<String, Object?>> recentEvents({int limit = 100}) {
    final box = _box;
    if (box == null) return const [];
    final values = box.values.cast<Map>().toList();
    final tail = values.length > limit ? values.sublist(values.length - limit) : values;
    return tail.map((m) => m.cast<String, Object?>()).toList();
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}
