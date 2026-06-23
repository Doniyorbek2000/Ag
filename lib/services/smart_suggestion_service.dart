import 'package:hive_flutter/hive_flutter.dart';
import 'action_executor.dart';

class SmartSuggestionService {
  static final SmartSuggestionService _instance = SmartSuggestionService._internal();
  factory SmartSuggestionService() => _instance;
  SmartSuggestionService._internal();

  Future<ActionResult> getSuggestions() async {
    try {
      final now = DateTime.now();
      final hour = now.hour;
      final todayStr = _dateStr(now);
      final suggestions = <String>[];

      // Vaqtga asoslangan tavsiyalar
      if (hour >= 5 && hour < 11) {
        suggestions.add('🌅 Xayrli tong! Kundalik rejangizni ko\'rib chiqing');
        _checkHabitsNotDone(suggestions, todayStr);
        suggestions.add('💧 Ertalabki suv ichishni unutmang');
      } else if (hour >= 11 && hour < 14) {
        suggestions.add('🍽️ Tushlik tanaffus vaqti — dam oling');
        suggestions.add('💧 Suv ichishni unutmang');
        _checkPendingTodos(suggestions);
      } else if (hour >= 14 && hour < 18) {
        _checkPendingTodos(suggestions);
        _checkExercise(suggestions, todayStr);
      } else if (hour >= 18 && hour < 22) {
        suggestions.add('📝 Kundalikka bugungi kuni haqida yozing');
        _checkDayAchievements(suggestions, todayStr);
        suggestions.add('😴 Uyqu vaqtiga tayyorlaning');
      } else {
        suggestions.add('⏰ Ertaga uchun budilnik qo\'ying');
        suggestions.add('🧘 Dam olish vaqti — tinchlanish mashqlarini qiling');
      }

      // Xarid ro'yxatini tekshirish
      _checkShoppingList(suggestions);

      // Eslatmalarni tekshirish
      _checkReminders(suggestions);

      // Byudjetni tekshirish
      _checkBudget(suggestions, now);

      // 3-5 ta tavsiyani tanlash
      if (suggestions.length > 5) {
        suggestions.removeRange(5, suggestions.length);
      }

      final timeOfDay = _getTimeOfDayName(hour);
      final message = '💡 $timeOfDay tavsiyalar:\n${suggestions.map((s) => '  $s').join('\n')}';

      return ActionResult(
        success: true,
        message: message,
        data: suggestions,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Tavsiyalarni olishda xato: $e');
    }
  }

  // ── YORDAMCHI METODLAR ────────────────────────────────────────────────────

  String _getTimeOfDayName(int hour) {
    if (hour >= 5 && hour < 11) return 'Ertalabki';
    if (hour >= 11 && hour < 14) return 'Tushlik vaqti';
    if (hour >= 14 && hour < 18) return 'Kunduzi';
    if (hour >= 18 && hour < 22) return 'Kechki';
    return 'Tungi';
  }

  void _checkHabitsNotDone(List<String> suggestions, String todayStr) {
    try {
      final box = Hive.box('habits');
      final habits = box.values.whereType<Map>().toList();
      final notDone = <String>[];
      for (final h in habits) {
        final logs = List<String>.from(h['logs'] ?? []);
        if (!logs.contains(todayStr)) {
          notDone.add(h['name']?.toString() ?? '');
        }
      }
      if (notDone.isNotEmpty) {
        final names = notDone.where((n) => n.isNotEmpty).take(3).join(', ');
        suggestions.add('🔥 Bajarilmagan odatlar: $names');
      }
    } catch (_) {}
  }

  void _checkPendingTodos(List<String> suggestions) {
    try {
      final box = Hive.box('todos');
      final pending = box.values
          .whereType<Map>()
          .where((t) => t['completed'] != true)
          .toList();
      if (pending.isNotEmpty) {
        final highPriority = pending.where((t) => t['priority'] == 'high').length;
        if (highPriority > 0) {
          suggestions.add('🔴 $highPriority ta muhim vazifa kutmoqda');
        } else {
          suggestions.add('📋 ${pending.length} ta vazifa bajarilmagan');
        }
      }
    } catch (_) {}
  }

  void _checkExercise(List<String> suggestions, String todayStr) {
    try {
      final box = Hive.box('health_log');
      final todayExercise = box.values
          .whereType<Map>()
          .where((e) =>
              e['type'] == 'exercise' &&
              (e['date']?.toString() ?? '').startsWith(todayStr))
          .toList();
      if (todayExercise.isEmpty) {
        suggestions.add('🏃 Bugun hali mashq qilmadingiz — harakat qiling!');
      }
    } catch (_) {}
  }

  void _checkDayAchievements(List<String> suggestions, String todayStr) {
    try {
      final box = Hive.box('todos');
      final completedToday = box.values
          .whereType<Map>()
          .where((t) => t['completed'] == true)
          .length;
      if (completedToday > 0) {
        suggestions.add('✅ Bugun $completedToday ta vazifani bajardingiz — ajoyib!');
      }
    } catch (_) {}
  }

  void _checkShoppingList(List<String> suggestions) {
    try {
      final box = Hive.box('shopping');
      final items = box.values
          .whereType<Map>()
          .where((s) => s['bought'] != true)
          .length;
      if (items > 0) {
        suggestions.add('🛒 Xarid ro\'yxatida $items ta mahsulot bor');
      }
    } catch (_) {}
  }

  void _checkReminders(List<String> suggestions) {
    try {
      final box = Hive.box('journal');
      // Kundalik yozuvi borligini tekshirish
      final todayStr = _dateStr(DateTime.now());
      final todayEntries = box.values
          .whereType<Map>()
          .where((e) => e['date'] == todayStr)
          .toList();
      if (todayEntries.isEmpty) {
        suggestions.add('📝 Bugun kundalikka hali yozmadingiz');
      }
    } catch (_) {}
  }

  void _checkBudget(List<String> suggestions, DateTime now) {
    try {
      final budgetBox = Hive.box('budget');
      if (budgetBox.isEmpty) return;

      final bookkeepingBox = Hive.box('bookkeeping');
      final monthStart = DateTime(now.year, now.month, 1);
      double monthExpense = 0;
      for (final raw in bookkeepingBox.values) {
        if (raw is! Map) continue;
        final date = DateTime.tryParse(raw['date']?.toString() ?? '');
        if (date == null || date.isBefore(monthStart)) continue;
        if (raw['type'] == 1) {
          monthExpense += (raw['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      final budget = budgetBox.values.first;
      if (budget is Map) {
        final budgetAmount = (budget['amount'] as num?)?.toDouble() ?? 0;
        if (budgetAmount > 0) {
          final ratio = monthExpense / budgetAmount;
          if (ratio >= 0.9) {
            suggestions.add('⚠️ Byudjet limitiga yaqinlashyapsiz! (${(ratio * 100).toStringAsFixed(0)}% ishlatildi)');
          } else if (ratio >= 0.75) {
            suggestions.add('💰 Byudjetning ${(ratio * 100).toStringAsFixed(0)}% ishlatildi — ehtiyot bo\'ling');
          }
        }
      }
    } catch (_) {}
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
