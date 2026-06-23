import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'action_executor.dart';

class TodoService {
  static const _uuid = Uuid();

  static final TodoService _instance = TodoService._internal();
  factory TodoService() => _instance;
  TodoService._internal();

  // ── TODOS ───────────────────────────────────────────────────────────────────

  Box get _todosBox => Hive.box('todos');
  Box get _shoppingBox => Hive.box('shopping');
  Box get _goalsBox => Hive.box('goals');

  Future<ActionResult> createTodo({
    required String title,
    String? description,
    String priority = 'normal',
    String? dueDate,
  }) async {
    try {
      final id = _uuid.v4();
      final todo = {
        'id': id,
        'title': title,
        'description': description ?? '',
        'priority': priority.toLowerCase(),
        'dueDate': dueDate ?? '',
        'completed': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _todosBox.put(id, todo);
      return ActionResult(
        success: true,
        message: 'Vazifa qo\'shildi: $title',
        data: todo,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Vazifa qo\'shishda xato: $e');
    }
  }

  Future<ActionResult> getTodos() async {
    try {
      final todos = _todosBox.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((t) => t['completed'] != true)
          .toList();

      if (todos.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Hozircha vazifalar yo\'q',
        );
      }

      final priorityOrder = {'high': 0, 'normal': 1, 'low': 2};
      todos.sort((a, b) {
        final pa = priorityOrder[a['priority']] ?? 1;
        final pb = priorityOrder[b['priority']] ?? 1;
        if (pa != pb) return pa.compareTo(pb);
        return (a['created_at']?.toString() ?? '')
            .compareTo(b['created_at']?.toString() ?? '');
      });

      final lines = todos.map((t) {
        final p = t['priority'] ?? 'normal';
        final icon = p == 'high' ? '\u{1F534}' : p == 'low' ? '\u{1F7E2}' : '\u{1F7E1}';
        final due = (t['dueDate']?.toString() ?? '').isNotEmpty
            ? ' (${t['dueDate']})'
            : '';
        return '$icon $p: ${t['title']}$due';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '\u{1F4CB} Vazifalar (${todos.length} ta):\n$lines',
        data: todos,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Vazifalarni o\'qishda xato: $e');
    }
  }

  Future<ActionResult> completeTodo(String title) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Vazifa nomini ayting',
      );
    }
    try {
      final lowerTitle = title.toLowerCase();
      for (final key in _todosBox.keys) {
        final raw = _todosBox.get(key);
        if (raw is Map) {
          final todo = Map<String, dynamic>.from(raw);
          if ((todo['title']?.toString() ?? '').toLowerCase().contains(lowerTitle)) {
            todo['completed'] = true;
            await _todosBox.put(key, todo);
            return ActionResult(
              success: true,
              message: 'Vazifa bajarildi: ${todo['title']}',
            );
          }
        }
      }
      return ActionResult(
        success: false,
        message: '"$title" nomli vazifa topilmadi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Vazifani yakunlashda xato: $e');
    }
  }

  Future<ActionResult> deleteTodo(String title) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'O\'chirish uchun vazifa nomini ayting',
      );
    }
    try {
      final lowerTitle = title.toLowerCase();
      for (final key in _todosBox.keys.toList()) {
        final raw = _todosBox.get(key);
        if (raw is Map) {
          final todo = Map<String, dynamic>.from(raw);
          if ((todo['title']?.toString() ?? '').toLowerCase().contains(lowerTitle)) {
            await _todosBox.delete(key);
            return ActionResult(
              success: true,
              message: 'Vazifa o\'chirildi: ${todo['title']}',
            );
          }
        }
      }
      return ActionResult(
        success: false,
        message: '"$title" nomli vazifa topilmadi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Vazifani o\'chirishda xato: $e');
    }
  }

  // ── SHOPPING LIST ──────────────────────────────────────────────────────────

  Future<ActionResult> addShoppingItem({
    required String item,
    int quantity = 1,
    String? note,
  }) async {
    try {
      final id = _uuid.v4();
      final entry = {
        'id': id,
        'item': item,
        'quantity': quantity,
        'note': note ?? '',
        'bought': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _shoppingBox.put(id, entry);
      return ActionResult(
        success: true,
        message: 'Xarid ro\'yxatiga qo\'shildi: ${quantity}x $item',
        data: entry,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Xarid qo\'shishda xato: $e');
    }
  }

  Future<ActionResult> getShoppingList() async {
    try {
      final items = _shoppingBox.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((i) => i['bought'] != true)
          .toList();

      if (items.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Xarid ro\'yxati bo\'sh',
        );
      }

      items.sort((a, b) => (a['created_at']?.toString() ?? '')
          .compareTo(b['created_at']?.toString() ?? ''));

      final lines = items.map((i) {
        final qty = i['quantity'] ?? 1;
        final note = (i['note']?.toString() ?? '').isNotEmpty
            ? ' (${i['note']})'
            : '';
        return '\u{2022} ${qty}x ${i['item']}$note';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '\u{1F6D2} Xarid ro\'yxati (${items.length} ta):\n$lines',
        data: items,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Xarid ro\'yxatini o\'qishda xato: $e');
    }
  }

  Future<ActionResult> deleteShoppingItem(String item) async {
    if (item.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'O\'chirish uchun mahsulot nomini ayting',
      );
    }
    try {
      final lowerItem = item.toLowerCase();
      for (final key in _shoppingBox.keys.toList()) {
        final raw = _shoppingBox.get(key);
        if (raw is Map) {
          final entry = Map<String, dynamic>.from(raw);
          if ((entry['item']?.toString() ?? '').toLowerCase().contains(lowerItem)) {
            await _shoppingBox.delete(key);
            return ActionResult(
              success: true,
              message: 'Xarid ro\'yxatidan o\'chirildi: ${entry['item']}',
            );
          }
        }
      }
      return ActionResult(
        success: false,
        message: '"$item" xarid ro\'yxatida topilmadi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Mahsulotni o\'chirishda xato: $e');
    }
  }

  Future<ActionResult> clearShoppingList() async {
    try {
      await _shoppingBox.clear();
      return const ActionResult(
        success: true,
        message: 'Xarid ro\'yxati tozalandi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Xarid ro\'yxatini tozalashda xato: $e');
    }
  }

  Future<ActionResult> markShoppingItemBought(String item) async {
    if (item.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Mahsulot nomini ayting',
      );
    }
    try {
      final lowerItem = item.toLowerCase();
      for (final key in _shoppingBox.keys) {
        final raw = _shoppingBox.get(key);
        if (raw is Map) {
          final entry = Map<String, dynamic>.from(raw);
          if ((entry['item']?.toString() ?? '').toLowerCase().contains(lowerItem)) {
            entry['bought'] = true;
            await _shoppingBox.put(key, entry);
            return ActionResult(
              success: true,
              message: 'Sotib olindi: ${entry['item']}',
            );
          }
        }
      }
      return ActionResult(
        success: false,
        message: '"$item" xarid ro\'yxatida topilmadi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Mahsulotni belgilashda xato: $e');
    }
  }

  // ── GOALS ─────────────────────────────────────────────────────────────────

  Future<ActionResult> setGoal({
    required String title,
    String? target,
    String? deadline,
  }) async {
    try {
      final id = _uuid.v4();
      final goal = {
        'id': id,
        'title': title,
        'target': target ?? '',
        'deadline': deadline ?? '',
        'completed': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _goalsBox.put(id, goal);
      return ActionResult(
        success: true,
        message: 'Maqsad qo\'shildi: $title',
        data: goal,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Maqsad qo\'shishda xato: $e');
    }
  }

  Future<ActionResult> getGoals() async {
    try {
      final goals = _goalsBox.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((g) => g['completed'] != true)
          .toList();

      if (goals.isEmpty) {
        return const ActionResult(
          success: true,
          message: 'Hozircha maqsadlar yo\'q',
        );
      }

      goals.sort((a, b) => (a['created_at']?.toString() ?? '')
          .compareTo(b['created_at']?.toString() ?? ''));

      final lines = goals.map((g) {
        final target = (g['target']?.toString() ?? '').isNotEmpty
            ? ' (${g['target']})'
            : '';
        final deadline = (g['deadline']?.toString() ?? '').isNotEmpty
            ? ' - ${g['deadline']}'
            : '';
        return '\u{2022} ${g['title']}$target$deadline';
      }).join('\n');

      return ActionResult(
        success: true,
        message: '\u{1F3AF} Maqsadlar (${goals.length} ta):\n$lines',
        data: goals,
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Maqsadlarni o\'qishda xato: $e');
    }
  }

  Future<ActionResult> completeGoal(String title) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Maqsad nomini ayting',
      );
    }
    try {
      final lowerTitle = title.toLowerCase();
      for (final key in _goalsBox.keys) {
        final raw = _goalsBox.get(key);
        if (raw is Map) {
          final goal = Map<String, dynamic>.from(raw);
          if ((goal['title']?.toString() ?? '').toLowerCase().contains(lowerTitle)) {
            goal['completed'] = true;
            await _goalsBox.put(key, goal);
            return ActionResult(
              success: true,
              message: 'Maqsad bajarildi: ${goal['title']}',
            );
          }
        }
      }
      return ActionResult(
        success: false,
        message: '"$title" nomli maqsad topilmadi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Maqsadni yakunlashda xato: $e');
    }
  }

  Future<ActionResult> deleteGoal(String title) async {
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'O\'chirish uchun maqsad nomini ayting',
      );
    }
    try {
      final lowerTitle = title.toLowerCase();
      for (final key in _goalsBox.keys.toList()) {
        final raw = _goalsBox.get(key);
        if (raw is Map) {
          final goal = Map<String, dynamic>.from(raw);
          if ((goal['title']?.toString() ?? '').toLowerCase().contains(lowerTitle)) {
            await _goalsBox.delete(key);
            return ActionResult(
              success: true,
              message: 'Maqsad o\'chirildi: ${goal['title']}',
            );
          }
        }
      }
      return ActionResult(
        success: false,
        message: '"$title" nomli maqsad topilmadi',
      );
    } catch (e) {
      return ActionResult(success: false, message: 'Maqsadni o\'chirishda xato: $e');
    }
  }
}
