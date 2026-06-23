import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class PasswordVaultService {
  static const _uuid = Uuid();
  static const boxName = 'vault';
  static const _obfuscationKey = 'AdmAi2024SecretKey!@#\$%';

  static final PasswordVaultService _instance = PasswordVaultService._internal();
  factory PasswordVaultService() => _instance;
  PasswordVaultService._internal();

  Box get _box => Hive.box(boxName);

  // ── PAROL QO'SHISH ───────────────────────────────────────────────────────

  Future<ActionResult> addPassword({
    required String service,
    required String username,
    required String password,
  }) async {
    if (service.isEmpty || username.isEmpty || password.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Xizmat nomi, foydalanuvchi nomi va parol kiritilishi shart',
      );
    }

    try {
      // Tekshirish: bu xizmat allaqachon bormi
      final existing = _findEntry(service);
      if (existing != null) {
        return ActionResult(
          success: false,
          message: '\'$service\' uchun parol allaqachon saqlangan. Yangilash uchun parolni yangilang',
        );
      }

      final id = _uuid.v4();
      final obfuscated = _obfuscate(password);
      final entry = {
        'id': id,
        'service': service,
        'username': username,
        'password': obfuscated,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _box.put(id, entry);

      return ActionResult(
        success: true,
        message: '🔐 \'$service\' uchun parol saqlandi (foydalanuvchi: $username)',
        data: {'id': id, 'service': service, 'username': username},
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Parolni saqlashda xato: $e');
    }
  }

  // ── PAROLNI OLISH ─────────────────────────────────────────────────────────

  Future<ActionResult> getPassword(String service) async {
    if (service.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Xizmat nomini kiriting',
      );
    }

    try {
      final entry = _findEntry(service);
      if (entry == null) {
        return ActionResult(
          success: false,
          message: '\'$service\' uchun parol topilmadi',
        );
      }

      final data = Map<String, dynamic>.from(entry.value as Map);
      final deobfuscated = _deobfuscate(data['password']?.toString() ?? '');

      return ActionResult(
        success: true,
        message: '🔑 \'${data['service']}\' paroli:\n'
            '• Foydalanuvchi: ${data['username']}\n'
            '• Parol: $deobfuscated',
        data: {
          'service': data['service'],
          'username': data['username'],
          'password': deobfuscated,
        },
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Parolni olishda xato: $e');
    }
  }

  // ── BARCHA PAROLLARNI KO'RISH ─────────────────────────────────────────────

  Future<ActionResult> listPasswords() async {
    try {
      final entries = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      if (entries.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Saqlangan parollar yo\'q',
        );
      }

      entries.sort((a, b) => (a['service']?.toString() ?? '')
          .compareTo(b['service']?.toString() ?? ''));

      final lines = entries.map((e) {
        final service = e['service'] ?? '';
        final username = e['username'] ?? '';
        final createdAt = e['created_at']?.toString() ?? '';
        final date = createdAt.length >= 10 ? createdAt.substring(0, 10) : '';
        return '🔐 $service — $username ($date)';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '🗝️ Saqlangan parollar (${entries.length} ta):\n$lines',
        data: entries.map((e) => {
          'service': e['service'],
          'username': e['username'],
        }).toList(),
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Parollarni o\'qishda xato: $e');
    }
  }

  // ── PAROLNI O'CHIRISH ─────────────────────────────────────────────────────

  Future<ActionResult> deletePassword(String service) async {
    if (service.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Xizmat nomini kiriting',
      );
    }

    try {
      final entry = _findEntry(service);
      if (entry == null) {
        return ActionResult(
          success: false,
          message: '\'$service\' uchun parol topilmadi',
        );
      }

      final data = Map<String, dynamic>.from(entry.value as Map);
      await _box.delete(entry.key);

      return ActionResult(
        success: true,
        message: '🗑️ \'${data['service']}\' paroli o\'chirildi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Parolni o\'chirishda xato: $e');
    }
  }

  // ── PAROLNI YANGILASH ─────────────────────────────────────────────────────

  Future<ActionResult> updatePassword({
    required String service,
    required String newPassword,
  }) async {
    if (service.isEmpty || newPassword.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Xizmat nomi va yangi parolni kiriting',
      );
    }

    try {
      final entry = _findEntry(service);
      if (entry == null) {
        return ActionResult(
          success: false,
          message: '\'$service\' uchun parol topilmadi',
        );
      }

      final data = Map<String, dynamic>.from(entry.value as Map);
      data['password'] = _obfuscate(newPassword);
      data['updated_at'] = DateTime.now().toIso8601String();
      await _box.put(entry.key, data);

      return ActionResult(
        success: true,
        message: '🔄 \'${data['service']}\' paroli yangilandi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Parolni yangilashda xato: $e');
    }
  }

  // ── TASODIFIY PAROL YARATISH VA SAQLASH ───────────────────────────────────

  Future<ActionResult> generateAndSave({
    required String service,
    required String username,
    int length = 16,
  }) async {
    if (service.isEmpty || username.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Xizmat nomi va foydalanuvchi nomini kiriting',
      );
    }

    try {
      final password = _generatePassword(length);
      final result = await addPassword(
        service: service,
        username: username,
        password: password,
      );

      if (result.success) {
        return ActionResult(
          success: true,
          message: '🔐 \'$service\' uchun $length belgili parol yaratildi va saqlandi\n'
              '• Foydalanuvchi: $username\n'
              '• Parol: $password',
          data: {
            'service': service,
            'username': username,
            'password': password,
          },
        );
      }

      return result;
    } catch (e) {
      return ActionResult(success: false, message: 'Parol yaratishda xato: $e');
    }
  }

  // ── YORDAMCHI METODLAR ────────────────────────────────────────────────────

  /// Xizmat nomini qidirish (case-insensitive)
  MapEntry<dynamic, dynamic>? _findEntry(String service) {
    final lower = service.toLowerCase();
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is Map) {
        final serviceName = value['service']?.toString().toLowerCase() ?? '';
        if (serviceName == lower) {
          return MapEntry(key, value);
        }
      }
    }
    return null;
  }

  /// XOR obfuskatsiya — parol belgilarini kalit bilan XOR qilib, base64 kodlash
  String _obfuscate(String input) {
    final keyChars = _obfuscationKey.codeUnits;
    final inputChars = input.codeUnits;
    final obfuscated = List<int>.generate(
      inputChars.length,
      (i) => inputChars[i] ^ keyChars[i % keyChars.length],
    );
    return base64Encode(obfuscated);
  }

  /// XOR deobfuskatsiya — base64 dekodlash va kalit bilan XOR
  String _deobfuscate(String encoded) {
    try {
      final keyChars = _obfuscationKey.codeUnits;
      final decoded = base64Decode(encoded);
      final original = List<int>.generate(
        decoded.length,
        (i) => decoded[i] ^ keyChars[i % keyChars.length],
      );
      return String.fromCharCodes(original);
    } catch (_) {
      return '';
    }
  }

  /// Tasodifiy parol generatsiya qilish
  String _generatePassword(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
