import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class JournalService {
  static const _uuid = Uuid();
  static const boxName = 'journal';

  static final JournalService _instance = JournalService._internal();
  factory JournalService() => _instance;
  JournalService._internal();

  Box get _box => Hive.box(boxName);

  // ── YOZUV QO'SHISH ──────────────────────────────────────────────────────

  Future<ActionResult> addEntry({
    required String content,
    String? mood,
    String? tags,
  }) async {
    if (content.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Kundalik yozuvi bo\'sh bo\'lishi mumkin emas',
      );
    }

    try {
      final now = DateTime.now();
      final id = _uuid.v4();
      final date = _dateStr(now);
      final tagList = (tags != null && tags.isNotEmpty)
          ? tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
          : <String>[];

      final entry = {
        'id': id,
        'content': content,
        'mood': mood ?? '',
        'tags': tagList,
        'created_at': now.toIso8601String(),
        'date': date,
      };
      await _box.put(id, entry);

      final moodText = (mood != null && mood.isNotEmpty) ? ' | Kayfiyat: $mood' : '';
      final tagsText = tagList.isNotEmpty ? ' | Teglar: ${tagList.join(', ')}' : '';
      return ActionResult(
        success: true,
        message: '📝 Kundalik yozuvi saqlandi ($date)$moodText$tagsText',
        data: entry,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kundalik yozuvini saqlashda xato: $e');
    }
  }

  // ── SO'NGI YOZUVLARNI KO'RISH ────────────────────────────────────────────

  Future<ActionResult> getEntries({int limit = 10}) async {
    try {
      final entries = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      if (entries.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Kundalikda hali yozuvlar yo\'q',
        );
      }

      entries.sort((a, b) => (b['created_at']?.toString() ?? '')
          .compareTo(a['created_at']?.toString() ?? ''));

      final limited = entries.take(limit).toList();
      final lines = limited.map((e) {
        final date = e['date'] ?? '';
        final mood = (e['mood']?.toString() ?? '').isNotEmpty ? ' ${e['mood']}' : '';
        final content = e['content']?.toString() ?? '';
        final preview = content.length > 50
            ? '${content.substring(0, 50)}...'
            : content;
        return '📅 $date$mood — $preview';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '📔 Kundalik yozuvlari (${limited.length} ta):\n$lines',
        data: limited,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Kundalik yozuvlarini o\'qishda xato: $e');
    }
  }

  // ── SANAGA KO'RA YOZUV OLISH ─────────────────────────────────────────────

  Future<ActionResult> getEntryByDate(String date) async {
    if (date.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Sanani kiriting (YYYY-MM-DD)',
      );
    }

    try {
      final entries = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((e) => e['date'] == date)
          .toList();

      if (entries.isEmpty) {
        return ActionResult(
          success: false,
          message: '$date sanasida kundalik yozuvi topilmadi',
        );
      }

      entries.sort((a, b) => (a['created_at']?.toString() ?? '')
          .compareTo(b['created_at']?.toString() ?? ''));

      final lines = entries.map((e) {
        final mood = (e['mood']?.toString() ?? '').isNotEmpty ? ' | Kayfiyat: ${e['mood']}' : '';
        final tagList = List<String>.from(e['tags'] ?? []);
        final tagsText = tagList.isNotEmpty ? ' | Teglar: ${tagList.join(', ')}' : '';
        return '${e['content']}$mood$tagsText';
      }).join('\n---\n');

      return ActionResult(
        success: true,
        message: '📅 $date kundalik yozuvi:\n$lines',
        data: entries,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Yozuvni o\'qishda xato: $e');
    }
  }

  // ── YOZUVNI O'CHIRISH ─────────────────────────────────────────────────────

  Future<ActionResult> deleteEntry(String date) async {
    if (date.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'O\'chirish uchun sanani kiriting (YYYY-MM-DD)',
      );
    }

    try {
      final keysToDelete = <dynamic>[];
      for (final key in _box.keys) {
        final raw = _box.get(key);
        if (raw is Map && raw['date'] == date) {
          keysToDelete.add(key);
        }
      }

      if (keysToDelete.isEmpty) {
        return ActionResult(
          success: false,
          message: '$date sanasida kundalik yozuvi topilmadi',
        );
      }

      for (final key in keysToDelete) {
        await _box.delete(key);
      }

      return ActionResult(
        success: true,
        message: '🗑️ $date sanasidagi ${keysToDelete.length} ta yozuv o\'chirildi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Yozuvni o\'chirishda xato: $e');
    }
  }

  // ── QIDIRUV ───────────────────────────────────────────────────────────────

  Future<ActionResult> searchJournal(String query) async {
    if (query.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Qidiruv so\'zini kiriting',
      );
    }

    try {
      final lowerQuery = query.toLowerCase();
      final results = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((e) {
        final content = (e['content']?.toString() ?? '').toLowerCase();
        final tagList = List<String>.from(e['tags'] ?? []);
        final tagsStr = tagList.join(' ').toLowerCase();
        return content.contains(lowerQuery) || tagsStr.contains(lowerQuery);
      }).toList();

      if (results.isEmpty) {
        return ActionResult(
          success: true,
          message: '"$query" bo\'yicha natija topilmadi',
        );
      }

      results.sort((a, b) => (b['created_at']?.toString() ?? '')
          .compareTo(a['created_at']?.toString() ?? ''));

      final lines = results.take(10).map((e) {
        final date = e['date'] ?? '';
        final content = e['content']?.toString() ?? '';
        final preview = content.length > 50
            ? '${content.substring(0, 50)}...'
            : content;
        return '📅 $date — $preview';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '🔍 "$query" bo\'yicha ${results.length} ta natija:\n$lines',
        data: results,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Qidiruvda xato: $e');
    }
  }

  // ── STATISTIKA ────────────────────────────────────────────────────────────

  Future<ActionResult> getJournalStats() async {
    try {
      final entries = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      if (entries.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Kundalikda hali yozuvlar yo\'q',
        );
      }

      final totalEntries = entries.length;

      // Streak hisoblash — ketma-ket kunlarni sanash
      final dates = entries
          .map((e) => e['date']?.toString() ?? '')
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      int streak = 0;
      if (dates.isNotEmpty) {
        final today = DateTime.now();
        final todayStr = _dateStr(today);
        final yesterdayStr = _dateStr(today.subtract(const Duration(days: 1)));

        if (dates.contains(todayStr) || dates.contains(yesterdayStr)) {
          var checkDate = dates.contains(todayStr)
              ? today
              : today.subtract(const Duration(days: 1));

          while (dates.contains(_dateStr(checkDate))) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          }
        }
      }

      // Eng ko'p ishlatiladigan kayfiyat
      final moodCounts = <String, int>{};
      for (final e in entries) {
        final mood = e['mood']?.toString() ?? '';
        if (mood.isNotEmpty) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        }
      }
      String mostCommonMood = 'noma\'lum';
      if (moodCounts.isNotEmpty) {
        final sorted = moodCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        mostCommonMood = '${sorted.first.key} (${sorted.first.value} marta)';
      }

      // Shu oydagi yozuvlar
      final now = DateTime.now();
      final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final thisMonthCount = entries
          .where((e) => (e['date']?.toString() ?? '').startsWith(monthPrefix))
          .length;

      return ActionResult(
        success: true,
        message: '📊 Kundalik statistikasi:\n'
            '• Jami yozuvlar: $totalEntries ta\n'
            '• Joriy streak: $streak kun\n'
            '• Eng ko\'p kayfiyat: $mostCommonMood\n'
            '• Shu oydagi yozuvlar: $thisMonthCount ta',
        data: {
          'total_entries': totalEntries,
          'streak': streak,
          'most_common_mood': mostCommonMood,
          'this_month_count': thisMonthCount,
        },
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Statistikani olishda xato: $e');
    }
  }

  // ── YORDAMCHI METODLAR ────────────────────────────────────────────────────

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
