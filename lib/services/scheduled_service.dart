import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class ScheduledService {
  static const _uuid = Uuid();
  static const boxName = 'scheduled_actions';

  Box get _box => Hive.box(boxName);
  final _notifications = FlutterLocalNotificationsPlugin();

  /// Kelajakdagi amalni rejalashtirilish (SMS, Telegram xabar, eslatma va h.k.)
  /// Amalni Hive'ga saqlaydi va local notification o'rnatadi.
  Future<ActionResult> scheduleAction({
    required String actionType,
    required Map<String, dynamic> params,
    required DateTime triggerAt,
    String? description,
  }) async {
    final id = _uuid.v4();
    final notificationId =
        triggerAt.millisecondsSinceEpoch ~/ 1000 % 2147483647;

    final desc = description ?? '$actionType — ${_formatDateTime(triggerAt)}';

    await _box.put(id, {
      'id': id,
      'actionType': actionType,
      'params': Map<String, dynamic>.from(params),
      'triggerAt': triggerAt.toIso8601String(),
      'description': desc,
      'status': 'pending',
      'notificationId': notificationId,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Vaqt allaqachon o'tganligini tekshirish
    final delay = triggerAt.difference(DateTime.now());
    if (delay.isNegative) {
      return const ActionResult(
        success: false,
        message: 'Vaqt allaqachon o\'tgan',
      );
    }

    // Local notification orqali eslatma o'rnatish
    try {
      await _scheduleNotification(
        id: notificationId,
        title: '⏰ Rejalashtirilgan amal',
        body: desc,
        scheduledAt: triggerAt,
      );
    } catch (e) {
      // Notification o'rnatilmasa ham, amal Hive'da saqlanadi
      // App resume paytida checkPendingActions orqali bajariladi
    }

    return ActionResult(
      success: true,
      message: '⏰ Rejalashtirildi: $desc\n'
          'Vaqt: ${_formatDateTime(triggerAt)}',
      data: id,
    );
  }

  /// Barcha kutilayotgan rejalashtirilgan amallarni ko'rish
  Future<ActionResult> getScheduledActions() async {
    final now = DateTime.now();
    final pending = _box.values
        .whereType<Map>()
        .where((a) => a['status'] == 'pending')
        .toList();

    if (pending.isEmpty) {
      return const ActionResult(
        success: true,
        message: 'Rejalashtirilgan amallar yo\'q',
      );
    }

    pending.sort((a, b) => (a['triggerAt']?.toString() ?? '')
        .compareTo(b['triggerAt']?.toString() ?? ''));

    final lines = pending.map((a) {
      final trigger = DateTime.tryParse(a['triggerAt']?.toString() ?? '');
      final timeStr = trigger != null ? _formatDateTime(trigger) : '?';
      final isPast = trigger != null && trigger.isBefore(now);
      return '${isPast ? '⚠️' : '⏰'} $timeStr — ${a['description'] ?? a['actionType']}';
    }).toList();

    return ActionResult(
      success: true,
      message:
          'Rejalashtirilgan amallar (${pending.length} ta):\n${lines.join('\n')}',
      data: pending.length,
    );
  }

  /// Rejalashtirilgan amalni bekor qilish (tavsif bo'yicha qidirish)
  Future<ActionResult> cancelScheduledAction(String description) async {
    if (description.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Bekor qilish uchun amal tavsifini kiriting',
      );
    }

    final lower = description.toLowerCase();
    for (final key in _box.keys) {
      final action = _box.get(key);
      if (action is Map && action['status'] == 'pending') {
        final desc = action['description']?.toString().toLowerCase() ?? '';
        final type = action['actionType']?.toString().toLowerCase() ?? '';
        if (desc.contains(lower) || type.contains(lower)) {
          final updated = Map<String, dynamic>.from(action);
          updated['status'] = 'cancelled';
          await _box.put(key, updated);

          // Notificationni bekor qilish
          final notificationId = action['notificationId'] as int?;
          if (notificationId != null) {
            try {
              await _notifications.cancel(notificationId);
            } catch (_) {}
          }

          return ActionResult(
            success: true,
            message:
                '❌ Rejalashtirilgan amal bekor qilindi: ${action['description'] ?? action['actionType']}',
          );
        }
      }
    }

    return ActionResult(
      success: false,
      message: '"$description" nomli rejalashtirilgan amal topilmadi',
    );
  }

  /// ID bo'yicha rejalashtirilgan amalni bekor qilish
  Future<ActionResult> cancelScheduledActionById(String id) async {
    final action = _box.get(id);
    if (action == null || action is! Map) {
      return const ActionResult(
        success: false,
        message: 'Rejalashtirilgan amal topilmadi',
      );
    }

    if (action['status'] != 'pending') {
      return ActionResult(
        success: false,
        message:
            'Bu amal allaqachon ${action['status'] == 'executed' ? 'bajarilgan' : 'bekor qilingan'}',
      );
    }

    final updated = Map<String, dynamic>.from(action);
    updated['status'] = 'cancelled';
    await _box.put(id, updated);

    final notificationId = action['notificationId'] as int?;
    if (notificationId != null) {
      try {
        await _notifications.cancel(notificationId);
      } catch (_) {}
    }

    return ActionResult(
      success: true,
      message:
          '❌ Rejalashtirilgan amal bekor qilindi: ${action['description'] ?? action['actionType']}',
    );
  }

  /// Vaqti kelgan kutilayotgan amallarni tekshirish va qaytarish
  /// App resume yoki davriy tekshiruv paytida chaqiriladi
  Future<List<Map<String, dynamic>>> checkPendingActions() async {
    final now = DateTime.now();
    final ready = <Map<String, dynamic>>[];

    for (final key in _box.keys) {
      final action = _box.get(key);
      if (action is Map && action['status'] == 'pending') {
        final trigger =
            DateTime.tryParse(action['triggerAt']?.toString() ?? '');
        if (trigger != null && trigger.isBefore(now)) {
          ready.add(Map<String, dynamic>.from(action));
          final updated = Map<String, dynamic>.from(action);
          updated['status'] = 'executed';
          updated['executed_at'] = now.toIso8601String();
          await _box.put(key, updated);
        }
      }
    }

    return ready;
  }

  /// Bajarilgan amallar tarixini ko'rish
  Future<ActionResult> getHistory() async {
    final all = _box.values.whereType<Map>().where((a) {
      final status = a['status']?.toString() ?? '';
      return status == 'executed' || status == 'cancelled';
    }).toList();

    if (all.isEmpty) {
      return const ActionResult(
        success: true,
        message: 'Tarix bo\'sh',
      );
    }

    all.sort((a, b) => (b['created_at']?.toString() ?? '')
        .compareTo(a['created_at']?.toString() ?? ''));

    final lines = all.take(10).map((a) {
      final status = a['status'] == 'executed' ? '✅' : '❌';
      final desc = a['description'] ?? a['actionType'] ?? 'Noma\'lum';
      return '$status $desc';
    }).toList();

    return ActionResult(
      success: true,
      message: 'Tarix (oxirgi ${lines.length} ta):\n${lines.join('\n')}',
      data: all.length,
    );
  }

  /// Barcha kutilayotgan amallarni tozalash
  Future<ActionResult> clearPending() async {
    int count = 0;
    for (final key in _box.keys.toList()) {
      final action = _box.get(key);
      if (action is Map && action['status'] == 'pending') {
        final notificationId = action['notificationId'] as int?;
        if (notificationId != null) {
          try {
            await _notifications.cancel(notificationId);
          } catch (_) {}
        }
        await _box.delete(key);
        count++;
      }
    }

    if (count == 0) {
      return const ActionResult(
        success: true,
        message: 'Kutilayotgan amallar yo\'q',
      );
    }

    return ActionResult(
      success: true,
      message: '🗑️ $count ta rejalashtirilgan amal tozalandi',
    );
  }

  // ── Yordamchi metodlar ──────────────────────────────────────────────────────

  /// Local notification rejalashtirish
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'scheduled_actions',
      'Rejalashtirilgan amallar',
      channelDescription: 'Rejalashtirilgan amallar uchun bildirishnomalar',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    // Vaqt farqini hisoblash va Future.delayed yondashuvi
    // zonedSchedule timezone paketini talab qiladi, shuning uchun
    // oddiyroq yondashuv: amalni Hive'da saqlash va app resume'da tekshirish
    final delay = scheduledAt.difference(DateTime.now());
    if (delay.inSeconds > 0 && delay.inSeconds < 86400) {
      // 24 soat ichida bo'lsa, notification ko'rsatish uchun harakat qilish
      Future.delayed(delay, () async {
        try {
          await _notifications.show(id, title, body, details);
        } catch (_) {}
      });
    }
  }

  /// DateTime'ni o'qiladigan formatga o'tkazish
  String _formatDateTime(DateTime dt) =>
      '${dt.day}.${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
