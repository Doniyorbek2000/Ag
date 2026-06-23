import 'package:hive_flutter/hive_flutter.dart';
import 'action_executor.dart';
import 'reminder_service.dart';

class DailyBriefingService {
  static const _uzbekDays = ['Dushanba','Seshanba','Chorshanba','Payshanba','Juma','Shanba','Yakshanba'];
  static const _uzbekMonths = ['Yanvar','Fevral','Mart','Aprel','May','Iyun','Iyul','Avgust','Sentabr','Oktabr','Noyabr','Dekabr'];

  /// Generate a comprehensive daily briefing
  Future<ActionResult> getDailyBriefing() async {
    final now = DateTime.now();
    final dayName = _uzbekDays[now.weekday - 1];
    final monthName = _uzbekMonths[now.month - 1];
    final lines = <String>[];

    lines.add('🌅 Xayrli tong! Bugun $dayName, ${now.day}-$monthName ${now.year}');
    lines.add('');

    // 1. Pending todos
    try {
      final todoBox = Hive.box('todos');
      final pendingTodos = todoBox.values.whereType<Map>()
          .where((t) => t['completed'] != true)
          .toList();
      if (pendingTodos.isNotEmpty) {
        lines.add('📋 Vazifalar (${pendingTodos.length} ta):');
        for (final todo in pendingTodos.take(5)) {
          final priority = todo['priority'] ?? 'normal';
          final emoji = priority == 'high' ? '🔴' : priority == 'low' ? '🟢' : '🟡';
          lines.add('  $emoji ${todo['title']}');
        }
        if (pendingTodos.length > 5) lines.add('  ... va yana ${pendingTodos.length - 5} ta');
        lines.add('');
      }
    } catch (_) {}

    // 2. Shopping list
    try {
      final shopBox = Hive.box('shopping');
      final items = shopBox.values.whereType<Map>()
          .where((s) => s['bought'] != true)
          .toList();
      if (items.isNotEmpty) {
        lines.add('🛒 Xarid ro\'yxati: ${items.length} ta mahsulot');
        lines.add('');
      }
    } catch (_) {}

    // 3. Upcoming reminders
    try {
      final reminders = ReminderService().getUpcoming();
      if (reminders.isNotEmpty) {
        lines.add('⏰ Eslatmalar:');
        for (final r in reminders.take(3)) {
          final time = '${r.triggerAt.hour.toString().padLeft(2, '0')}:${r.triggerAt.minute.toString().padLeft(2, '0')}';
          lines.add('  $time — ${r.title}');
        }
        lines.add('');
      }
    } catch (_) {}

    // 4. Goals progress
    try {
      final goalBox = Hive.box('goals');
      final activeGoals = goalBox.values.whereType<Map>()
          .where((g) => g['completed'] != true)
          .toList();
      if (activeGoals.isNotEmpty) {
        lines.add('🎯 Faol maqsadlar: ${activeGoals.length} ta');
        lines.add('');
      }
    } catch (_) {}

    // 5. Health yesterday summary
    try {
      final healthBox = Hive.box('health_log');
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final yesterdayEntries = healthBox.values.whereType<Map>()
          .where((e) => (e['date']?.toString() ?? '').startsWith(yesterdayStr))
          .toList();
      if (yesterdayEntries.isNotEmpty) {
        final waterCount = yesterdayEntries.where((e) => e['type'] == 'water').fold<int>(0, (sum, e) => sum + ((e['glasses'] as num?)?.toInt() ?? 0));
        final sleepEntry = yesterdayEntries.where((e) => e['type'] == 'sleep').lastOrNull;
        final parts = <String>[];
        if (waterCount > 0) parts.add('💧 $waterCount stakan suv');
        if (sleepEntry != null) parts.add('😴 ${sleepEntry['hours']} soat uyqu');
        if (parts.isNotEmpty) {
          lines.add('📊 Kechagi sog\'liq: ${parts.join(', ')}');
          lines.add('');
        }
      }
    } catch (_) {}

    // 6. Habits streaks
    try {
      final habitBox = Hive.box('habits');
      final habits = habitBox.values.whereType<Map>().toList();
      if (habits.isNotEmpty) {
        final activeStreaks = habits.where((h) {
          final logs = (h['logs'] as List?)?.cast<String>() ?? [];
          return logs.isNotEmpty;
        }).toList();
        if (activeStreaks.isNotEmpty) {
          lines.add('🔥 Odatlar:');
          for (final h in activeStreaks.take(5)) {
            final streak = h['current_streak'] ?? 0;
            lines.add('  ${streak > 0 ? "✅" : "❌"} ${h['name']} — $streak kun');
          }
          lines.add('');
        }
      }
    } catch (_) {}

    // 7. Budget status (if set)
    try {
      final budgetBox = Hive.box('budget');
      if (budgetBox.isNotEmpty) {
        final bookkeepingBox = Hive.box('bookkeeping');
        final monthStart = DateTime(now.year, now.month, 1);
        double monthExpense = 0;
        for (final raw in bookkeepingBox.values) {
          if (raw is! Map) continue;
          final date = DateTime.tryParse(raw['date']?.toString() ?? '');
          if (date == null || date.isBefore(monthStart)) continue;
          if (raw['type'] == 1) monthExpense += (raw['amount'] as num?)?.toDouble() ?? 0;
        }
        final budget = budgetBox.values.first;
        if (budget is Map) {
          final budgetAmount = (budget['amount'] as num?)?.toDouble() ?? 0;
          final remaining = budgetAmount - monthExpense;
          final emoji = remaining > 0 ? '✅' : '⚠️';
          lines.add('💰 Byudjet: ${_fmt(monthExpense)} / ${_fmt(budgetAmount)} so\'m $emoji');
          lines.add('');
        }
      }
    } catch (_) {}

    // 8. Scheduled actions
    try {
      final schedBox = Hive.box('scheduled_actions');
      final pending = schedBox.values.whereType<Map>()
          .where((a) => a['status'] == 'pending')
          .toList();
      if (pending.isNotEmpty) {
        lines.add('📅 Rejalashtirilgan: ${pending.length} ta amal');
        lines.add('');
      }
    } catch (_) {}

    // Motivational closing
    lines.add('💪 Bugun ham ajoyib kun bo\'ladi! Boshlang!');

    return ActionResult(
      success: true,
      message: lines.join('\n'),
    );
  }

  /// Get a quick status summary (shorter than full briefing)
  Future<ActionResult> getQuickStatus() async {
    final now = DateTime.now();
    final parts = <String>[];

    try {
      final todoBox = Hive.box('todos');
      final count = todoBox.values.whereType<Map>().where((t) => t['completed'] != true).length;
      if (count > 0) parts.add('📋 $count vazifa');
    } catch (_) {}

    try {
      final reminders = ReminderService().getUpcoming();
      if (reminders.isNotEmpty) parts.add('⏰ ${reminders.length} eslatma');
    } catch (_) {}

    try {
      final shopBox = Hive.box('shopping');
      final count = shopBox.values.whereType<Map>().where((s) => s['bought'] != true).length;
      if (count > 0) parts.add('🛒 $count xarid');
    } catch (_) {}

    if (parts.isEmpty) return const ActionResult(success: true, message: '✨ Hozircha hech narsa kutilmayapti. Yaxshi!');
    return ActionResult(success: true, message: '📊 Holat: ${parts.join(' | ')}');
  }

  String _fmt(double v) {
    final intPart = v.truncate().toString();
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(' ');
      buf.write(intPart[i]);
    }
    return '$buf';
  }
}
