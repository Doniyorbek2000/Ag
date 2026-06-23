import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class FavoritesService {
  static const _uuid = Uuid();
  static const boxName = 'favorites';

  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  Box get _box => Hive.box(boxName);

  static const _validTypes = ['contact', 'place', 'command', 'link', 'app'];

  // ── SEVIMLILAR ─────────────────────────────────────────────────────────────

  Future<ActionResult> addFavorite({
    required String name,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Sevimli nomini kiriting',
      );
    }

    final lowerType = type.toLowerCase();
    if (!_validTypes.contains(lowerType)) {
      return ActionResult(
        success: false,
        message: 'Noto\'g\'ri tur: $type. Mavjud turlar: ${_validTypes.join(', ')}',
      );
    }

    // Bir xil nomdagi sevimli borligini tekshirish
    final existing = _box.values.whereType<Map>().where(
          (f) => (f['name']?.toString().toLowerCase() ?? '') == name.toLowerCase(),
        );
    if (existing.isNotEmpty) {
      return ActionResult(
        success: false,
        message: '\'$name\' nomli sevimli allaqachon mavjud',
      );
    }

    try {
      final id = _uuid.v4();
      final favorite = {
        'id': id,
        'name': name,
        'type': lowerType,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _box.put(id, favorite);

      return ActionResult(
        success: true,
        message: '⭐ Sevimliga qo\'shildi: $name ($lowerType)',
        data: favorite,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Sevimli qo\'shishda xato: $e');
    }
  }

  Future<ActionResult> getFavorites({String? type}) async {
    try {
      var favorites = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      if (type != null && type.isNotEmpty) {
        final lowerType = type.toLowerCase();
        favorites = favorites.where((f) => f['type'] == lowerType).toList();
      }

      if (favorites.isEmpty) {
        final typeMsg = type != null ? ' ($type turidagi)' : '';
        return ActionResult(
          success: true,
          message: 'Hozircha$typeMsg sevimlilar yo\'q',
        );
      }

      favorites.sort((a, b) => (a['created_at']?.toString() ?? '')
          .compareTo(b['created_at']?.toString() ?? ''));

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final f in favorites) {
        final t = f['type']?.toString() ?? 'boshqa';
        grouped.putIfAbsent(t, () => []).add(f);
      }

      final buffer = StringBuffer('⭐ Sevimlilar (${favorites.length} ta):\n');
      for (final entry in grouped.entries) {
        final typeIcon = _typeIcon(entry.key);
        buffer.writeln('$typeIcon ${entry.key.toUpperCase()}:');
        for (final f in entry.value) {
          buffer.writeln('  • ${f['name']}');
        }
      }

      return ActionResult(
        success: true,
        message: buffer.toString().trimRight(),
        data: favorites,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Sevimlilarni o\'qishda xato: $e');
    }
  }

  Future<ActionResult> removeFavorite(String name) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Sevimli nomini kiriting',
      );
    }

    try {
      final lowerName = name.toLowerCase();
      for (final key in _box.keys.toList()) {
        final raw = _box.get(key);
        if (raw is Map) {
          final favorite = Map<String, dynamic>.from(raw);
          if ((favorite['name']?.toString().toLowerCase() ?? '').contains(lowerName)) {
            await _box.delete(key);
            return ActionResult(
              success: true,
              message: '🗑️ Sevimlilardan o\'chirildi: ${favorite['name']}',
            );
          }
        }
      }
      return ActionResult(
        success: false,
        message: '\'$name\' nomli sevimli topilmadi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Sevimli o\'chirishda xato: $e');
    }
  }

  Future<ActionResult> executeFavorite(String name) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Sevimli nomini kiriting',
      );
    }

    try {
      final lowerName = name.toLowerCase();
      for (final key in _box.keys) {
        final raw = _box.get(key);
        if (raw is Map) {
          final favorite = Map<String, dynamic>.from(raw);
          if ((favorite['name']?.toString().toLowerCase() ?? '').contains(lowerName)) {
            return ActionResult(
              success: true,
              message: '▶️ Sevimli bajarilmoqda: ${favorite['name']} (${favorite['type']})',
              data: {
                'name': favorite['name'],
                'type': favorite['type'],
                'data': favorite['data'],
              },
            );
          }
        }
      }
      return ActionResult(
        success: false,
        message: '\'$name\' nomli sevimli topilmadi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Sevimli bajarishda xato: $e');
    }
  }

  // ── TEZKOR BUYRUQLAR ───────────────────────────────────────────────────────

  Future<ActionResult> addQuickCommand({
    required String name,
    required String actionType,
    required Map<String, dynamic> params,
  }) async {
    if (name.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Tezkor buyruq nomini kiriting',
      );
    }

    if (actionType.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Amal turini kiriting',
      );
    }

    try {
      final id = _uuid.v4();
      final command = {
        'id': id,
        'name': name,
        'action_type': actionType,
        'params': params,
        'created_at': DateTime.now().toIso8601String(),
        'is_quick_command': true,
      };
      await _box.put('qc_$id', command);

      return ActionResult(
        success: true,
        message: '⚡ Tezkor buyruq saqlandi: $name → $actionType',
        data: command,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Tezkor buyruq qo\'shishda xato: $e');
    }
  }

  Future<ActionResult> getQuickCommands() async {
    try {
      final commands = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((c) => c['is_quick_command'] == true)
          .toList();

      if (commands.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Hozircha tezkor buyruqlar yo\'q',
        );
      }

      commands.sort((a, b) => (a['created_at']?.toString() ?? '')
          .compareTo(b['created_at']?.toString() ?? ''));

      final lines = commands.map((c) {
        return '⚡ ${c['name']} → ${c['action_type']}';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '⚡ Tezkor buyruqlar (${commands.length} ta):\n$lines',
        data: commands,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Tezkor buyruqlarni o\'qishda xato: $e');
    }
  }

  // ── YORDAMCHI ──────────────────────────────────────────────────────────────

  String _typeIcon(String type) {
    switch (type) {
      case 'contact':
        return '👤';
      case 'place':
        return '📍';
      case 'command':
        return '⚡';
      case 'link':
        return '🔗';
      case 'app':
        return '📱';
      default:
        return '⭐';
    }
  }
}
