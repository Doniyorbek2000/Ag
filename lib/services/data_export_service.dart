import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'action_executor.dart';

class DataExportService {
  /// Export bookkeeping data to CSV
  Future<ActionResult> exportBookkeeping() async {
    final box = Hive.box('bookkeeping');
    if (box.isEmpty) return const ActionResult(success: false, message: 'Buxgalteriya ma\'lumotlari yo\'q');

    final lines = <String>['Sana,Turi,Nomi,Summa,Kategoriya,Izoh'];
    for (final raw in box.values) {
      if (raw is! Map) continue;
      final date = raw['date']?.toString() ?? '';
      final type = (raw['type'] as int?) == 0 ? 'Kirim' : 'Chiqim';
      final title = _escapeCsv(raw['title']?.toString() ?? '');
      final amount = (raw['amount'] as num?)?.toString() ?? '0';
      final category = _escapeCsv(raw['category']?.toString() ?? '');
      final note = _escapeCsv(raw['note']?.toString() ?? '');
      lines.add('$date,$type,$title,$amount,$category,$note');
    }

    return _saveFile('buxgalteriya', lines.join('\n'));
  }

  /// Export health log to CSV
  Future<ActionResult> exportHealthLog() async {
    final box = Hive.box('health_log');
    if (box.isEmpty) return const ActionResult(success: false, message: 'Sog\'liq ma\'lumotlari yo\'q');

    final lines = <String>['Sana,Turi,Qiymat,Izoh'];
    final entries = box.values.whereType<Map>().toList()
      ..sort((a, b) => (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? ''));

    for (final e in entries) {
      final date = e['date']?.toString() ?? '';
      final type = e['type']?.toString() ?? '';
      String value;
      switch (type) {
        case 'water': value = '${e['glasses']} stakan'; break;
        case 'weight': value = '${e['kg']} kg'; break;
        case 'sleep': value = '${e['hours']} soat'; break;
        case 'mood': value = e['mood']?.toString() ?? ''; break;
        case 'exercise': value = '${e['exercise_type']} ${e['minutes']}min'; break;
        default: value = '';
      }
      final note = _escapeCsv(e['note']?.toString() ?? e['quality']?.toString() ?? '');
      lines.add('$date,$type,$value,$note');
    }

    return _saveFile('sogliq', lines.join('\n'));
  }

  /// Export notes to CSV
  Future<ActionResult> exportNotes() async {
    final box = Hive.box('notes');
    if (box.isEmpty) return const ActionResult(success: false, message: 'Qaydlar yo\'q');

    final lines = <String>['Sana,Sarlavha,Matn'];
    for (final raw in box.values) {
      if (raw is! Map) continue;
      final date = raw['created_at']?.toString() ?? '';
      final title = _escapeCsv(raw['title']?.toString() ?? '');
      final content = _escapeCsv(raw['content']?.toString() ?? '');
      lines.add('$date,$title,$content');
    }

    return _saveFile('qaydlar', lines.join('\n'));
  }

  /// Export todos to CSV
  Future<ActionResult> exportTodos() async {
    final box = Hive.box('todos');
    if (box.isEmpty) return const ActionResult(success: false, message: 'Vazifalar yo\'q');

    final lines = <String>['Sana,Vazifa,Tavsif,Muhimlik,Holat'];
    for (final raw in box.values) {
      if (raw is! Map) continue;
      final date = raw['created_at']?.toString() ?? '';
      final title = _escapeCsv(raw['title']?.toString() ?? '');
      final desc = _escapeCsv(raw['description']?.toString() ?? '');
      final priority = raw['priority']?.toString() ?? 'normal';
      final status = raw['completed'] == true ? 'Bajarildi' : 'Kutilmoqda';
      lines.add('$date,$title,$desc,$priority,$status');
    }

    return _saveFile('vazifalar', lines.join('\n'));
  }

  /// Export all data in one go
  Future<ActionResult> exportAll() async {
    final results = <String>[];

    final bk = await exportBookkeeping();
    if (bk.success) results.add('✅ Buxgalteriya');

    final hl = await exportHealthLog();
    if (hl.success) results.add('✅ Sog\'liq');

    final nt = await exportNotes();
    if (nt.success) results.add('✅ Qaydlar');

    final td = await exportTodos();
    if (td.success) results.add('✅ Vazifalar');

    if (results.isEmpty) {
      return const ActionResult(success: false, message: 'Eksport qilish uchun ma\'lumot yo\'q');
    }

    return ActionResult(
      success: true,
      message: '📁 Eksport tayyor:\n${results.join('\n')}\n\nFayllar: Documents/ADM_AI/ papkasida',
    );
  }

  Future<ActionResult> _saveFile(String name, String content) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/ADM_AI');
      if (!await exportDir.exists()) await exportDir.create(recursive: true);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final file = File('${exportDir.path}/${name}_$timestamp.csv');
      await file.writeAsString(content);

      return ActionResult(
        success: true,
        message: '📁 Saqlandi: ${file.path}',
        data: file.path,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Faylni saqlashda xato: $e');
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
