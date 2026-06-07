import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:adm_ai/services/memory_service.dart';

void main() {
  late Directory tempDir;
  late MemoryService memory;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('adm_ai_memory_test');
    Hive.init(tempDir.path);
    await Hive.openBox(MemoryService.boxName);
    memory = MemoryService();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('MemoryService', () {
    test('remembers a fact and returns it from getAll', () async {
      await memory.remember('Tug\'ilgan kun', '14-may');

      expect(memory.getAll(), {'tug\'ilgan kun': '14-may'});
    });

    test('normalizes keys and trims values so lookups are case-insensitive', () async {
      await memory.remember('  Sevimli Rang  ', '  ko\'k  ');

      expect(memory.getAll(), {'sevimli rang': 'ko\'k'});
    });

    test('ignores empty keys or values', () async {
      await memory.remember('', 'qiymat');
      await memory.remember('kalit', '   ');

      expect(memory.getAll(), isEmpty);
    });

    test('forget removes a single fact, forgetAll clears everything', () async {
      await memory.remember('ism', 'Aziz');
      await memory.remember('shahar', 'Toshkent');

      await memory.forget('Ism');
      expect(memory.getAll(), {'shahar': 'Toshkent'});

      await memory.forgetAll();
      expect(memory.getAll(), isEmpty);
    });

    test('buildContextSummary is empty with no facts and lists facts otherwise', () async {
      expect(memory.buildContextSummary(), '');

      await memory.remember('kasb', 'dasturchi');
      final summary = memory.buildContextSummary();

      expect(summary, contains('uzoq muddatli xotira'));
      expect(summary, contains('- kasb: dasturchi'));
    });
  });
}
