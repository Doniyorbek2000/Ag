import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class HealthTrackerService {
  static const _uuid = Uuid();
  static const boxName = 'health_log';

  static final HealthTrackerService _instance = HealthTrackerService._internal();
  factory HealthTrackerService() => _instance;
  HealthTrackerService._internal();

  Box get _box => Hive.box(boxName);

  // ── WATER ─────────────────────────────────────────────────────────────────

  Future<ActionResult> logWater({int glasses = 1}) async {
    try {
      final id = _uuid.v4();
      final entry = {
        'id': id,
        'type': 'water',
        'value': glasses,
        'date': DateTime.now().toIso8601String(),
      };
      await _box.put(id, entry);

      final todayTotal = _getTodayEntries('water')
          .fold<int>(0, (sum, e) => sum + ((e['value'] as int?) ?? 0));

      return ActionResult(
        success: true,
        message: '\u{1F4A7} $glasses stakan suv yozildi. Bugungi jami: $todayTotal stakan',
        data: entry,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Suv yozishda xato: $e');
    }
  }

  Future<ActionResult> getWaterLog() async {
    try {
      final todayEntries = _getTodayEntries('water');
      final todayTotal = todayEntries.fold<int>(
          0, (sum, e) => sum + ((e['value'] as int?) ?? 0));

      final recentEntries = _getRecentEntries('water', 7);
      final dailyTotals = <String, int>{};
      for (final e in recentEntries) {
        final day = (e['date']?.toString() ?? '').substring(0, 10);
        dailyTotals[day] = (dailyTotals[day] ?? 0) + ((e['value'] as int?) ?? 0);
      }

      final lines = dailyTotals.entries
          .map((e) => '  ${e.key}: ${e.value} stakan')
          .join('\n');

      return ActionResult(
        success: true,
        message: '\u{1F4A7} Bugun: $todayTotal stakan\n'
            'So\'nggi 7 kun:\n$lines',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Suv ma\'lumotlarini o\'qishda xato: $e');
    }
  }

  // ── WEIGHT ────────────────────────────────────────────────────────────────

  Future<ActionResult> logWeight({required double kg}) async {
    try {
      final id = _uuid.v4();
      final entry = {
        'id': id,
        'type': 'weight',
        'value': kg,
        'date': DateTime.now().toIso8601String(),
      };
      await _box.put(id, entry);

      final previous = _getRecentEntries('weight', 365);
      String changeText = '';
      if (previous.length > 1) {
        final lastValue = (previous[1]['value'] as num?)?.toDouble();
        if (lastValue != null) {
          final diff = kg - lastValue;
          final sign = diff >= 0 ? '+' : '';
          changeText = ' O\'tgan: ${_formatNum(lastValue)} kg ($sign${_formatNum(diff)} kg)';
        }
      }

      return ActionResult(
        success: true,
        message: '\u{2696}\u{FE0F} ${_formatNum(kg)} kg yozildi.$changeText',
        data: entry,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Vazn yozishda xato: $e');
    }
  }

  Future<ActionResult> getWeightLog() async {
    try {
      final entries = _getRecentEntries('weight', 365).take(10).toList();
      if (entries.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Vazn ma\'lumotlari yo\'q',
        );
      }

      final lines = entries.map((e) {
        final date = (e['date']?.toString() ?? '').substring(0, 10);
        final val = (e['value'] as num?)?.toDouble() ?? 0;
        return '  $date: ${_formatNum(val)} kg';
      }).join('\n');

      final first = (entries.last['value'] as num?)?.toDouble() ?? 0;
      final last = (entries.first['value'] as num?)?.toDouble() ?? 0;
      final totalDiff = last - first;
      final sign = totalDiff >= 0 ? '+' : '';
      final trend = entries.length > 1
          ? '\nUmumiy o\'zgarish: $sign${_formatNum(totalDiff)} kg'
          : '';

      return ActionResult(
        success: true,
        message: '\u{2696}\u{FE0F} Vazn tarixi (so\'nggi ${entries.length} ta):\n$lines$trend',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Vazn ma\'lumotlarini o\'qishda xato: $e');
    }
  }

  // ── SLEEP ─────────────────────────────────────────────────────────────────

  Future<ActionResult> logSleep({required double hours, String? quality}) async {
    try {
      final id = _uuid.v4();
      final entry = {
        'id': id,
        'type': 'sleep',
        'value': hours,
        'quality': quality ?? 'o\'rtacha',
        'date': DateTime.now().toIso8601String(),
      };
      await _box.put(id, entry);

      final qualityText = (quality?.isNotEmpty ?? false) ? ' (${quality})' : '';
      return ActionResult(
        success: true,
        message: '\u{1F634} ${_formatNum(hours)} soat uyqu yozildi$qualityText',
        data: entry,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Uyqu yozishda xato: $e');
    }
  }

  Future<ActionResult> getSleepLog() async {
    try {
      final entries = _getRecentEntries('sleep', 7);
      if (entries.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Uyqu ma\'lumotlari yo\'q',
        );
      }

      final totalHours = entries.fold<double>(
          0, (sum, e) => sum + ((e['value'] as num?)?.toDouble() ?? 0));
      final average = totalHours / entries.length;

      final lines = entries.map((e) {
        final date = (e['date']?.toString() ?? '').substring(0, 10);
        final val = (e['value'] as num?)?.toDouble() ?? 0;
        final q = e['quality']?.toString() ?? '';
        final qualityText = q.isNotEmpty ? ' ($q)' : '';
        return '  $date: ${_formatNum(val)} soat$qualityText';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '\u{1F634} So\'nggi 7 kun uyqu:\n$lines\n'
            'O\'rtacha: ${_formatNum(average)} soat/kun',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Uyqu ma\'lumotlarini o\'qishda xato: $e');
    }
  }

  // ── MOOD ──────────────────────────────────────────────────────────────────

  static const _moodEmojis = {
    'ajoyib': '\u{1F604}',
    'yaxshi': '\u{1F642}',
    'normal': '\u{1F610}',
    'yomon': '\u{1F614}',
    'dahshat': '\u{1F622}',
  };

  Future<ActionResult> logMood({required String mood, String? note}) async {
    try {
      final normalizedMood = mood.toLowerCase();
      final emoji = _moodEmojis[normalizedMood] ?? '\u{1F610}';
      final id = _uuid.v4();
      final entry = {
        'id': id,
        'type': 'mood',
        'value': normalizedMood,
        'note': note ?? '',
        'date': DateTime.now().toIso8601String(),
      };
      await _box.put(id, entry);

      final noteText = (note?.isNotEmpty ?? false) ? ': $note' : '';
      return ActionResult(
        success: true,
        message: '$emoji Kayfiyat yozildi: $normalizedMood$noteText',
        data: entry,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kayfiyat yozishda xato: $e');
    }
  }

  Future<ActionResult> getMoodLog() async {
    try {
      final entries = _getRecentEntries('mood', 7);
      if (entries.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Kayfiyat ma\'lumotlari yo\'q',
        );
      }

      final lines = entries.map((e) {
        final date = (e['date']?.toString() ?? '').substring(0, 10);
        final mood = e['value']?.toString() ?? 'normal';
        final emoji = _moodEmojis[mood] ?? '\u{1F610}';
        final note = (e['note']?.toString() ?? '').isNotEmpty
            ? ' - ${e['note']}'
            : '';
        return '  $date: $emoji $mood$note';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '\u{1F3AD} So\'nggi 7 kun kayfiyat:\n$lines',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kayfiyat ma\'lumotlarini o\'qishda xato: $e');
    }
  }

  // ── EXERCISE ──────────────────────────────────────────────────────────────

  Future<ActionResult> logExercise({
    required String type,
    required int minutes,
    int? calories,
  }) async {
    try {
      final id = _uuid.v4();
      final entry = {
        'id': id,
        'type': 'exercise',
        'exercise_type': type,
        'value': minutes,
        'calories': calories ?? 0,
        'date': DateTime.now().toIso8601String(),
      };
      await _box.put(id, entry);

      final caloriesText = (calories != null && calories > 0)
          ? ' ($calories kkal)'
          : '';
      return ActionResult(
        success: true,
        message: '\u{1F3C3} $minutes daqiqa $type yozildi$caloriesText',
        data: entry,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Mashq yozishda xato: $e');
    }
  }

  Future<ActionResult> getExerciseLog() async {
    try {
      final entries = _getRecentEntries('exercise', 7);
      if (entries.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Bu hafta mashq ma\'lumotlari yo\'q',
        );
      }

      final totalMinutes = entries.fold<int>(
          0, (sum, e) => sum + ((e['value'] as int?) ?? 0));
      final totalCalories = entries.fold<int>(
          0, (sum, e) => sum + ((e['calories'] as int?) ?? 0));

      final typeSummary = <String, int>{};
      for (final e in entries) {
        final t = e['exercise_type']?.toString() ?? 'boshqa';
        typeSummary[t] = (typeSummary[t] ?? 0) + ((e['value'] as int?) ?? 0);
      }

      final lines = typeSummary.entries
          .map((e) => '  \u{2022} ${e.key}: ${e.value} daqiqa')
          .join('\n');

      final caloriesText = totalCalories > 0
          ? '\nJami kaloriya: $totalCalories kkal'
          : '';

      return ActionResult(
        success: true,
        message: '\u{1F3C3} Bu hafta mashqlar:\n$lines\n'
            'Jami: $totalMinutes daqiqa$caloriesText',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Mashq ma\'lumotlarini o\'qishda xato: $e');
    }
  }

  // ── DAILY SUMMARY ─────────────────────────────────────────────────────────

  Future<ActionResult> getDailyHealthSummary() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final parts = <String>[];

      // Water
      final waterEntries = _getTodayEntries('water');
      final waterTotal = waterEntries.fold<int>(
          0, (sum, e) => sum + ((e['value'] as int?) ?? 0));
      if (waterTotal > 0) {
        parts.add('\u{1F4A7} Suv: $waterTotal stakan');
      }

      // Sleep
      final sleepEntries = _getTodayEntries('sleep');
      if (sleepEntries.isNotEmpty) {
        final sleepHours = (sleepEntries.last['value'] as num?)?.toDouble() ?? 0;
        final quality = sleepEntries.last['quality']?.toString() ?? '';
        final qualityText = quality.isNotEmpty ? ' ($quality)' : '';
        parts.add('\u{1F634} Uyqu: ${_formatNum(sleepHours)} soat$qualityText');
      }

      // Mood
      final moodEntries = _getTodayEntries('mood');
      if (moodEntries.isNotEmpty) {
        final mood = moodEntries.last['value']?.toString() ?? 'normal';
        final emoji = _moodEmojis[mood] ?? '\u{1F610}';
        parts.add('$emoji Kayfiyat: $mood');
      }

      // Exercise
      final exerciseEntries = _getTodayEntries('exercise');
      if (exerciseEntries.isNotEmpty) {
        final totalMin = exerciseEntries.fold<int>(
            0, (sum, e) => sum + ((e['value'] as int?) ?? 0));
        parts.add('\u{1F3C3} Mashq: $totalMin daqiqa');
      }

      // Weight
      final weightEntries = _getTodayEntries('weight');
      if (weightEntries.isNotEmpty) {
        final w = (weightEntries.last['value'] as num?)?.toDouble() ?? 0;
        parts.add('\u{2696}\u{FE0F} Vazn: ${_formatNum(w)} kg');
      }

      if (parts.isEmpty) {
        return ActionResult(
          success: true,
          message: '\u{1F4CA} Bugun ($today) hali ma\'lumot yozilmagan',
        );
      }

      return ActionResult(
        success: true,
        message: '\u{1F4CA} Bugungi salomatlik xulosasi ($today):\n${parts.join('\n')}',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kunlik xulosani olishda xato: $e');
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  List<Map> _getTodayEntries(String type) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _box.values
        .whereType<Map>()
        .where((e) =>
            e['type'] == type &&
            (e['date']?.toString() ?? '').startsWith(today))
        .toList();
  }

  List<Map> _getRecentEntries(String type, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _box.values
        .whereType<Map>()
        .where((e) =>
            e['type'] == type &&
            (DateTime.tryParse(e['date']?.toString() ?? '') ?? DateTime(2000))
                .isAfter(cutoff))
        .toList()
      ..sort((a, b) => (b['date']?.toString() ?? '')
          .compareTo(a['date']?.toString() ?? ''));
  }

  String _formatNum(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    final fixed = value.toStringAsFixed(1);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
