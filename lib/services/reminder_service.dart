import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class Reminder {
  final String id;
  final String title;
  final String message;
  final DateTime triggerAt;
  final bool fired;

  const Reminder({
    required this.id,
    required this.title,
    required this.message,
    required this.triggerAt,
    this.fired = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'message': message,
    'triggerAt': triggerAt.toIso8601String(),
    'fired': fired,
  };

  factory Reminder.fromMap(Map m) => Reminder(
    id: m['id'] as String,
    title: m['title'] as String,
    message: m['message'] as String,
    triggerAt: DateTime.parse(m['triggerAt'] as String),
    fired: m['fired'] as bool? ?? false,
  );
}

class ReminderService {
  static const boxName = 'reminders';
  static const _uuid = Uuid();

  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  Box get _box => Hive.box(boxName);

  List<Reminder> getAll() {
    return _box.values
        .whereType<Map>()
        .map((m) => Reminder.fromMap(m))
        .toList()
      ..sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
  }

  List<Reminder> getUpcoming() {
    final now = DateTime.now();
    return getAll().where((r) => !r.fired && r.triggerAt.isAfter(now)).toList();
  }

  Future<Reminder> add({
    required String title,
    required String message,
    required int minutesFromNow,
  }) async {
    final reminder = Reminder(
      id: _uuid.v4(),
      title: title,
      message: message,
      triggerAt: DateTime.now().add(Duration(minutes: minutesFromNow)),
    );

    await _box.put(reminder.id, reminder.toMap());
    _scheduleNotification(reminder);
    return reminder;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> markFired(String id) async {
    final raw = _box.get(id);
    if (raw is Map) {
      final updated = Map<String, dynamic>.from(raw);
      updated['fired'] = true;
      await _box.put(id, updated);
    }
  }

  void _scheduleNotification(Reminder reminder) {
    final delay = reminder.triggerAt.difference(DateTime.now());
    if (delay.isNegative) {
      markFired(reminder.id);
      return;
    }

    final plugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      'adm_reminders',
      'Eslatmalar',
      channelDescription: 'ADM AI eslatmalari',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notifId = reminder.id.hashCode & 0x7FFFFFFF;

    Future.delayed(delay, () async {
      await plugin.show(
        notifId,
        reminder.title,
        reminder.message,
        const NotificationDetails(android: androidDetails),
      );
      await markFired(reminder.id);
    });
  }

  void rescheduleAll() {
    for (final r in getUpcoming()) {
      _scheduleNotification(r);
    }
  }
}
