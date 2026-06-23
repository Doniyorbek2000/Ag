import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class HabitService {
  static const _uuid = Uuid();
  static const boxName = 'habits';

  Box get _box => Hive.box(boxName);

  /// Yangi odat yaratish
  Future<ActionResult> createHabit({required String name}) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Odat nomini kiriting',
      );
    }

    // Tekshirish: bu nomdagi odat allaqachon bormi
    final existing = _box.values.whereType<Map>().where(
          (h) =>
              (h['name']?.toString().toLowerCase() ?? '') ==
              name.toLowerCase(),
        );
    if (existing.isNotEmpty) {
      return ActionResult(
        success: false,
        message: '\'$name\' nomli odat allaqachon mavjud',
      );
    }

    final id = _uuid.v4();
    await _box.put(id, {
      'id': id,
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
      'logs': <String>[],
      'current_streak': 0,
      'best_streak': 0,
    });

    return ActionResult(
      success: true,
      message: '✅ \'$name\' odati yaratildi! Har kuni belgilang.',
      data: id,
    );
  }

  /// Bugungi kunni bajarilgan deb belgilash
  Future<ActionResult> logHabit({required String name}) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Odat nomini kiriting',
      );
    }

    final entry = _findHabit(name);
    if (entry == null) {
      return ActionResult(
        success: false,
        message: '\'$name\' nomli odat topilmadi',
      );
    }

    final key = entry.key;
    final habit = Map<String, dynamic>.from(entry.value as Map);
    final logs = List<String>.from(habit['logs'] ?? []);
    final todayStr = _dateStr(DateTime.now());

    // Bugun allaqachon belgilangan bo'lsa, takrorlamaslik
    if (logs.contains(todayStr)) {
      final currentStreak = habit['current_streak'] as int? ?? 0;
      return ActionResult(
        success: true,
        message: '✅ \'${habit['name']}\' bugun allaqachon belgilangan — $currentStreak kunlik streak! 🔥',
      );
    }

    logs.add(todayStr);
    habit['logs'] = logs;

    // Streakni hisoblash
    final currentStreak = _calculateStreak(logs);
    habit['current_streak'] = currentStreak;

    final bestStreak = habit['best_streak'] as int? ?? 0;
    if (currentStreak > bestStreak) {
      habit['best_streak'] = currentStreak;
    }

    await _box.put(key, habit);

    return ActionResult(
      success: true,
      message: '✅ \'${habit['name']}\' — $currentStreak kunlik streak! 🔥',
      data: {
        'current_streak': currentStreak,
        'best_streak': habit['best_streak'],
      },
    );
  }

  /// Barcha odatlarni ko'rish
  Future<ActionResult> getHabits() async {
    final habits = _box.values.whereType<Map>().toList();

    if (habits.isEmpty) {
      return const ActionResult(
        success: true,
        message: 'Hozircha odatlar yo\'q. Yangi odat qo\'shing!',
      );
    }

    final todayStr = _dateStr(DateTime.now());
    final lines = habits.map((h) {
      final name = h['name'] ?? 'Nomsiz';
      final logs = List<String>.from(h['logs'] ?? []);
      final isDone = logs.contains(todayStr);
      final streak = _calculateStreak(logs);
      final icon = isDone ? '✅' : '❌';
      final fire = streak > 0 ? ' 🔥' : '';
      return '$icon $name — $streak kun$fire';
    }).toList();

    return ActionResult(
      success: true,
      message: '📊 Odatlar:\n${lines.join('\n')}',
      data: habits.length,
    );
  }

  /// Bitta odat bo'yicha batafsil statistika
  Future<ActionResult> getHabitStats(String name) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Odat nomini kiriting',
      );
    }

    final entry = _findHabit(name);
    if (entry == null) {
      return ActionResult(
        success: false,
        message: '\'$name\' nomli odat topilmadi',
      );
    }

    final habit = Map<String, dynamic>.from(entry.value as Map);
    final logs = List<String>.from(habit['logs'] ?? []);
    final currentStreak = _calculateStreak(logs);
    final bestStreak = habit['best_streak'] as int? ?? 0;
    final totalDays = logs.length;

    // Oxirgi 30 kun uchun bajarilish foizi
    final now = DateTime.now();
    int last30Count = 0;
    for (int i = 0; i < 30; i++) {
      final checkDate = now.subtract(Duration(days: i));
      if (logs.contains(_dateStr(checkDate))) {
        last30Count++;
      }
    }
    final completionRate = (last30Count / 30 * 100).round();

    final createdAt = DateTime.tryParse(habit['created_at']?.toString() ?? '');
    final createdStr = createdAt != null
        ? '${createdAt.day}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}'
        : 'noma\'lum';

    final todayStr = _dateStr(now);
    final todayDone = logs.contains(todayStr) ? '✅ Bajarilgan' : '❌ Bajarilmagan';

    return ActionResult(
      success: true,
      message: '📊 \'${habit['name']}\' statistikasi:\n'
          '• Bugun: $todayDone\n'
          '• Joriy streak: $currentStreak kun\n'
          '• Eng yaxshi streak: $bestStreak kun\n'
          '• Jami kunlar: $totalDays\n'
          '• Oxirgi 30 kun: $completionRate%\n'
          '• Yaratilgan: $createdStr',
      data: {
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'total_days': totalDays,
        'completion_rate_30d': completionRate,
      },
    );
  }

  /// Odatni o'chirish
  Future<ActionResult> deleteHabit(String name) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Odat nomini kiriting',
      );
    }

    final entry = _findHabit(name);
    if (entry == null) {
      return ActionResult(
        success: false,
        message: '\'$name\' nomli odat topilmadi',
      );
    }

    final habitName = (entry.value as Map)['name'] ?? name;
    await _box.delete(entry.key);

    return ActionResult(
      success: true,
      message: '🗑️ \'$habitName\' odati o\'chirildi',
    );
  }

  /// Odat loglarini tozalash (reset)
  Future<ActionResult> resetHabit(String name) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Odat nomini kiriting',
      );
    }

    final entry = _findHabit(name);
    if (entry == null) {
      return ActionResult(
        success: false,
        message: '\'$name\' nomli odat topilmadi',
      );
    }

    final habit = Map<String, dynamic>.from(entry.value as Map);
    habit['logs'] = <String>[];
    habit['current_streak'] = 0;
    habit['best_streak'] = 0;
    await _box.put(entry.key, habit);

    return ActionResult(
      success: true,
      message: '🔄 \'${habit['name']}\' odati tozalandi. Qaytadan boshlang!',
    );
  }

  // ── Yordamchi metodlar ──────────────────────────────────────────────────────

  /// Odat nomini qidirish (case-insensitive)
  MapEntry<dynamic, dynamic>? _findHabit(String name) {
    final lower = name.toLowerCase();
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is Map) {
        final habitName = value['name']?.toString().toLowerCase() ?? '';
        if (habitName == lower || habitName.contains(lower)) {
          return MapEntry(key, value);
        }
      }
    }
    return null;
  }

  /// Streakni hisoblash — bugundan orqaga qarab ketma-ket kunlarni sanash
  int _calculateStreak(List<String> logs) {
    if (logs.isEmpty) return 0;

    final sorted = logs.toList()..sort((a, b) => b.compareTo(a)); // eng yangisi birinchi
    final today = DateTime.now();
    final todayStr = _dateStr(today);
    final yesterdayStr = _dateStr(today.subtract(const Duration(days: 1)));

    // Streak bugun yoki kechadan boshlangan bo'lishi kerak
    if (sorted.first != todayStr && sorted.first != yesterdayStr) return 0;

    int streak = 0;
    var checkDate =
        sorted.first == todayStr ? today : today.subtract(const Duration(days: 1));

    for (final log in sorted) {
      if (log == _dateStr(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// DateTime'ni YYYY-MM-DD formatiga o'tkazish
  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
