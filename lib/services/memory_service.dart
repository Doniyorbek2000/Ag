import 'package:hive_flutter/hive_flutter.dart';

/// Long-term assistant memory: simple key/value facts the user explicitly
/// asks ADM AI to remember (e.g. "Mening tug'ilgan kunim 14-may ekanini
/// es ket"), persisted in the `memory` Hive box and re-injected into every
/// future AI request as context -- so the assistant keeps "knowing" things
/// across app restarts and conversations, not just within a single chat.
class MemoryService {
  static const boxName = 'memory';

  Box get _box => Hive.box(boxName);

  Future<void> remember(String key, String value) async {
    final normalized = key.trim().toLowerCase();
    if (normalized.isEmpty || value.trim().isEmpty) return;
    await _box.put(normalized, value.trim());
  }

  Future<void> forget(String key) async {
    await _box.delete(key.trim().toLowerCase());
  }

  Future<void> forgetAll() async {
    await _box.clear();
  }

  Map<String, String> getAll() {
    return _box.toMap().map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  /// Renders stored facts as a context block the AI system prompt can use.
  /// Returns an empty string when there is nothing to remember.
  String buildContextSummary() {
    final facts = getAll();
    if (facts.isEmpty) return '';
    final lines = facts.entries.map((e) => '- ${e.key}: ${e.value}').join('\n');
    return 'FOYDALANUVCHI HAQIDA ESLAB QOLINGAN MA\'LUMOTLAR (uzoq muddatli xotira):\n$lines';
  }
}
