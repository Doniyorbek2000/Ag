import 'package:hive_flutter/hive_flutter.dart';
import 'action_executor.dart';

class UsageStatsService {
  static const boxName = 'usage_stats';

  static final UsageStatsService _instance = UsageStatsService._internal();
  factory UsageStatsService() => _instance;
  UsageStatsService._internal();

  Box get _box => Hive.box(boxName);

  // ── FOYDALANISH LOGI ───────────────────────────────────────────────────────

  Future<void> logUsage(String actionType) async {
    try {
      // action_counts yangilash
      final countsRaw = _box.get('action_counts');
      final counts = countsRaw is Map
          ? Map<String, int>.from(
              countsRaw.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)))
          : <String, int>{};

      counts[actionType] = (counts[actionType] ?? 0) + 1;
      await _box.put('action_counts', counts);

      // daily_log yangilash
      final todayStr = _dateStr(DateTime.now());
      final dailyRaw = _box.get('daily_log');
      final daily = dailyRaw is Map
          ? Map<String, int>.from(
              dailyRaw.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)))
          : <String, int>{};

      daily[todayStr] = (daily[todayStr] ?? 0) + 1;
      await _box.put('daily_log', daily);
    } catch (_) {
      // Statistika xatoligi asosiy ishlashga ta'sir qilmasligi kerak
    }
  }

  // ── ENG KO'P ISHLATILGAN AMALLAR ──────────────────────────────────────────

  Future<ActionResult> getTopActions({int limit = 10}) async {
    try {
      final countsRaw = _box.get('action_counts');
      if (countsRaw == null || countsRaw is! Map) {
        return const ActionResult(
          success: true,
          message: '📊 Hali hech qanday amal bajarilmagan',
        );
      }

      final counts = Map<String, int>.from(
          countsRaw.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)));

      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top = sorted.take(limit).toList();

      if (top.isEmpty) {
        return const ActionResult(
          success: true,
          message: '📊 Hali hech qanday amal bajarilmagan',
        );
      }

      final lines = <String>[];
      for (int i = 0; i < top.length; i++) {
        lines.add('${i + 1}. ${top[i].key} — ${top[i].value} marta');
      }

      return ActionResult(
        success: true,
        message: '📊 Eng ko\'p ishlatilgan amallar:\n${lines.join('\n')}',
        data: Map.fromEntries(top),
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Statistikani o\'qishda xato: $e');
    }
  }

  // ── KUNLIK FAOLLIK ─────────────────────────────────────────────────────────

  Future<ActionResult> getDailyActivity() async {
    try {
      final dailyRaw = _box.get('daily_log');
      if (dailyRaw == null || dailyRaw is! Map) {
        return const ActionResult(
          success: true,
          message: '📊 Hali hech qanday faollik qayd etilmagan',
        );
      }

      final daily = Map<String, int>.from(
          dailyRaw.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)));

      final now = DateTime.now();
      final todayStr = _dateStr(now);
      final todayCount = daily[todayStr] ?? 0;

      // Shu hafta
      int weekCount = 0;
      for (int i = 0; i < 7; i++) {
        final dayStr = _dateStr(now.subtract(Duration(days: i)));
        weekCount += daily[dayStr] ?? 0;
      }

      // Shu oy
      int monthCount = 0;
      for (int i = 0; i < 30; i++) {
        final dayStr = _dateStr(now.subtract(Duration(days: i)));
        monthCount += daily[dayStr] ?? 0;
      }

      return ActionResult(
        success: true,
        message: '📊 Kunlik faollik:\n'
            '• Bugun: $todayCount ta amal\n'
            '• Shu hafta: $weekCount ta amal\n'
            '• Shu oy: $monthCount ta amal',
        data: {
          'today': todayCount,
          'week': weekCount,
          'month': monthCount,
        },
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Faollik ma\'lumotlarini o\'qishda xato: $e');
    }
  }

  // ── UMUMIY XULOSA ──────────────────────────────────────────────────────────

  Future<ActionResult> getUsageSummary() async {
    try {
      // Amallar soni
      final countsRaw = _box.get('action_counts');
      final counts = countsRaw is Map
          ? Map<String, int>.from(
              countsRaw.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)))
          : <String, int>{};

      final totalActions = counts.values.fold<int>(0, (sum, v) => sum + v);

      // Top 5 amallar
      final sortedActions = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5 = sortedActions.take(5).toList();

      // Kunlik log
      final dailyRaw = _box.get('daily_log');
      final daily = dailyRaw is Map
          ? Map<String, int>.from(
              dailyRaw.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)))
          : <String, int>{};

      // Kunlik o'rtacha
      final totalDays = daily.length;
      final dailyAvg = totalDays > 0 ? (totalActions / totalDays).round() : 0;

      // Eng faol hafta kuni
      final weekDayCounts = <int, int>{};
      for (final entry in daily.entries) {
        final date = DateTime.tryParse(entry.key);
        if (date != null) {
          final weekday = date.weekday;
          weekDayCounts[weekday] = (weekDayCounts[weekday] ?? 0) + entry.value;
        }
      }

      String mostActiveDay = 'noma\'lum';
      if (weekDayCounts.isNotEmpty) {
        final sortedDays = weekDayCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        mostActiveDay = _weekdayName(sortedDays.first.key);
      }

      // Bugun
      final now = DateTime.now();
      final todayStr = _dateStr(now);
      final todayCount = daily[todayStr] ?? 0;

      final buffer = StringBuffer('📊 Foydalanish xulosasi:\n');
      buffer.writeln('• Jami amallar: $totalActions');
      buffer.writeln('• Bugun: $todayCount ta amal');
      buffer.writeln('• Kunlik o\'rtacha: $dailyAvg ta amal');
      buffer.writeln('• Eng faol kun: $mostActiveDay');

      if (top5.isNotEmpty) {
        buffer.writeln('\n🏆 Top amallar:');
        for (int i = 0; i < top5.length; i++) {
          buffer.writeln('  ${i + 1}. ${top5[i].key} — ${top5[i].value} marta');
        }
      }

      return ActionResult(
        success: true,
        message: buffer.toString().trimRight(),
        data: {
          'total_actions': totalActions,
          'today': todayCount,
          'daily_average': dailyAvg,
          'most_active_day': mostActiveDay,
          'top_actions': Map.fromEntries(top5),
        },
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Xulosani yaratishda xato: $e');
    }
  }

  // ── TOZALASH ───────────────────────────────────────────────────────────────

  Future<ActionResult> resetStats() async {
    try {
      await _box.clear();
      return const ActionResult(
        success: true,
        message: '🗑️ Barcha statistika ma\'lumotlari tozalandi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Statistikani tozalashda xato: $e');
    }
  }

  // ── YORDAMCHI METODLAR ─────────────────────────────────────────────────────

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Dushanba';
      case 2:
        return 'Seshanba';
      case 3:
        return 'Chorshanba';
      case 4:
        return 'Payshanba';
      case 5:
        return 'Juma';
      case 6:
        return 'Shanba';
      case 7:
        return 'Yakshanba';
      default:
        return 'Noma\'lum';
    }
  }
}
