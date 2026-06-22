import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/action_executor.dart';
import '../services/memory_service.dart';
import '../services/offline_command_service.dart';
import '../services/analytics_service.dart';
import '../services/backend_sync_service.dart';
import '../services/crash_reporting_service.dart';
import '../models/bookkeeping_entry.dart';
import '../screens/bookkeeping_screen.dart';
import '../services/reminder_service.dart';
import 'auth_provider.dart';
import 'locale_provider.dart';

/// Maximum number of past messages kept in Hive and restored on launch --
/// enough for useful continuity without the box growing unbounded.
const _maxStoredMessages = 200;
/// How many recent messages are sent to the AI as conversation context.
const _maxContextMessages = 20;

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final ActionResult? lastActionResult;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.lastActionResult,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    ActionResult? lastActionResult,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastActionResult: lastActionResult ?? this.lastActionResult,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final AiService _aiService = AiService();
  final ActionExecutor _executor = ActionExecutor();
  final MemoryService _memory = MemoryService();
  final BackendSyncService _sync = BackendSyncService();
  final _uuid = const Uuid();

  Box get _box => Hive.box('chats');

  ChatNotifier(this._ref) : super(const ChatState()) {
    _loadHistory();
  }

  /// Restores the persisted conversation so the assistant "remembers" what
  /// was discussed across app restarts -- previously every launch started
  /// from a blank slate even though messages were stored in Hive.
  Future<void> _loadHistory() async {
    final stored = _box.values.whereType<ChatMessage>().toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (stored.isNotEmpty) {
      state = state.copyWith(messages: stored.skip(
        stored.length > _maxStoredMessages ? stored.length - _maxStoredMessages : 0,
      ).toList());
    }
  }

  Future<void> _persist(ChatMessage message) async {
    await _box.put(message.id, message);
    if (_box.length > _maxStoredMessages) {
      final extra = _box.length - _maxStoredMessages;
      final oldestKeys = _box.values
          .whereType<ChatMessage>()
          .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final m in oldestKeys.take(extra)) {
        await _box.delete(m.id);
      }
    }
  }

  Future<void> sendMessage(String text, {bool isVoice = false}) async {
    final user = _ref.read(authProvider);

    if (!user.canMakeAiCall) {
      state = state.copyWith(
        error: 'Kunlik so\'rovlar limitiga yetdingiz. '
            'Tarif rejasini yangilang.',
      );
      return;
    }

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
      type: isVoice ? MessageType.voice : MessageType.text,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );
    await _persist(userMsg);
    _sync.reportMessage(
      role: 'user',
      content: text,
      source: isVoice ? 'voice' : 'mobile',
    );
    AnalyticsService().track('message_sent', {'isVoice': isVoice});

    final online = await _isOnline();
    if (!online) {
      await _handleOfflineMessage(text);
      return;
    }

    try {
      final history = state.messages
          .where((m) => m != userMsg)
          .toList()
          .reversed
          .take(_maxContextMessages)
          .toList()
          .reversed
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final apiKey = user.apiKey;
      if (apiKey != null && apiKey.isNotEmpty) {
        _aiService.setApiKey(apiKey);
      }

      final memorySummary = _memory.buildContextSummary();
      final bookkeepingSummary = _buildBookkeepingSummary();
      final contextParts = [memorySummary, bookkeepingSummary].where((s) => s.isNotEmpty);
      final fullContext = contextParts.isEmpty ? null : contextParts.join('\n\n');

      final response = await _aiService.sendMessage(
        message: text,
        conversationHistory: history,
        contextInfo: fullContext,
        responseLanguage: _ref.read(appLanguageProvider).code,
      );

      final aiMsg = ChatMessage(
        id: _uuid.v4(),
        content: response.text,
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      );

      ActionResult? actionResult;
      if (response.action != null) {
        actionResult = await _handleAction(response.action!);
        AnalyticsService().track('action_executed', {
          'type': response.action!.type,
          'success': actionResult.success,
        });
        _sync.reportToolAction(
          type: response.action!.type,
          payload: response.action!.params,
          success: actionResult.success,
          resultMessage: actionResult.message,
        );
      }

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
        lastActionResult: actionResult,
      );
      await _persist(aiMsg);
      _sync.reportMessage(
        role: 'assistant',
        content: response.text,
        source: isVoice ? 'voice' : 'mobile',
      );

      await _ref.read(authProvider.notifier).incrementDailyCall();
    } on AiException catch (e, stackTrace) {
      state = state.copyWith(isLoading: false, error: e.message);
      await CrashReportingService.recordError(e, stackTrace, context: 'chat_send_message');
    } catch (e, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        error: 'Xato yuz berdi: ${e.toString()}',
      );
      await CrashReportingService.recordError(e, stackTrace, context: 'chat_send_message');
    }
  }

  Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Offline fallback: tries to fulfil the request entirely on-device via
  /// [OfflineCommandService] (open app, place call, send SMS, ...). If the
  /// phrase isn't one of those, the user is told the assistant needs a
  /// connection -- rather than silently failing or queuing the request.
  Future<void> _handleOfflineMessage(String text) async {
    final offlineCommand = OfflineCommandService.parse(text);

    String replyText;
    ActionResult? actionResult;
    if (offlineCommand != null) {
      actionResult = await _executor.execute(offlineCommand.type, offlineCommand.params);
      replyText = actionResult.success
          ? offlineCommand.replyText
          : 'Internet aloqasi yo\'q va bu buyruqni offlayn bajarib bo\'lmadi: ${actionResult.message}';
    } else {
      replyText = 'Hozir internet aloqasi yo\'q. Offlayn rejimda faqat qo\'ng\'iroq '
          'qilish, SMS yuborish va ilovalarni ochish kabi buyruqlarni bajara olaman — '
          'AI suhbat va internet talab qiladigan amallar uchun ulanish tiklanishini kuting.';
    }

    final offlineMsg = ChatMessage(
      id: _uuid.v4(),
      content: replyText,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.system,
    );

    state = state.copyWith(
      messages: [...state.messages, offlineMsg],
      isLoading: false,
      lastActionResult: actionResult,
    );
    await _persist(offlineMsg);
  }

  /// Memory actions (REMEMBER_FACT / FORGET_FACT) are local data operations
  /// handled here rather than by [ActionExecutor], which only knows about
  /// device-facing actions (calls, apps, etc).
  Future<ActionResult> _handleAction(ActionCommand action) async {
    switch (action.type) {
      case 'REMEMBER_FACT':
        final key = action.params['key']?.toString() ?? '';
        final value = action.params['value']?.toString() ?? '';
        await _memory.remember(key, value);
        return const ActionResult(success: true, message: 'Eslab qoldim.');
      case 'FORGET_FACT':
        final key = action.params['key']?.toString() ?? '';
        await _memory.forget(key);
        return const ActionResult(success: true, message: 'Unutdim.');
      case 'ADD_EXPENSE':
      case 'ADD_INCOME':
        return _addBookkeepingEntry(action);
      case 'GET_REPORT':
        return _generateReport(action);
      case 'GET_REMINDERS':
        return _listReminders();
      case 'TAKE_NOTE':
        return _takeNote(action);
      case 'GET_NOTES':
        return _getNotes();
      case 'DELETE_NOTE':
        return _deleteNote(action);
      default:
        return _executor.execute(action.type, action.params);
    }
  }

  Future<ActionResult> _addBookkeepingEntry(ActionCommand action) async {
    final title = action.params['title']?.toString() ?? '';
    final rawAmount = action.params['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '');
    final rawCategory = action.params['category']?.toString() ?? 'Boshqa';
    final note = action.params['note']?.toString();

    if (title.isEmpty || amount == null || amount <= 0) {
      return const ActionResult(
        success: false,
        message: 'Kirim/chiqim uchun nom va summani ayting',
      );
    }

    final type = action.type == 'ADD_INCOME' ? EntryType.income : EntryType.expense;
    final validCategories = type == EntryType.income ? incomeCategories : expenseCategories;
    final category = validCategories.contains(rawCategory) ? rawCategory : 'Boshqa';
    await _ref.read(bookkeepingProvider.notifier).addEntry(
      title: title,
      amount: amount,
      type: type,
      category: category,
      note: note,
    );

    final typeLabel = type == EntryType.income ? 'Kirim' : 'Chiqim';
    return ActionResult(
      success: true,
      message: '$typeLabel qo\'shildi: $title — ${amount.toStringAsFixed(0)} so\'m',
    );
  }

  Future<ActionResult> _generateReport(ActionCommand action) async {
    final period = action.params['period']?.toString() ?? 'month';
    final box = Hive.box('bookkeeping');
    if (box.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Hali hech qanday kirim yoki chiqim yozilmagan',
      );
    }

    final now = DateTime.now();
    DateTime startDate;
    String periodLabel;

    switch (period) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        periodLabel = 'So\'nggi 7 kun';
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        periodLabel = '${now.year}-yil';
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        periodLabel = 'Bu oy';
    }

    double income = 0;
    double expense = 0;
    final categoryTotals = <String, double>{};
    int count = 0;

    for (final raw in box.values) {
      if (raw is! Map) continue;
      final date = DateTime.tryParse(raw['date']?.toString() ?? '');
      if (date == null || date.isBefore(startDate)) continue;

      final amount = (raw['amount'] as num?)?.toDouble() ?? 0;
      final type = raw['type'] as int?;
      final category = raw['category']?.toString() ?? 'Boshqa';
      count++;

      if (type == 0) {
        income += amount;
      } else {
        expense += amount;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }

    if (count == 0) {
      return ActionResult(
        success: false,
        message: '$periodLabel uchun yozuvlar topilmadi',
      );
    }

    final lines = <String>[
      '📊 $periodLabel hisoboti:',
      '',
      '💰 Kirim: ${income.toStringAsFixed(0)} so\'m',
      '💸 Chiqim: ${expense.toStringAsFixed(0)} so\'m',
      '📈 Balans: ${(income - expense).toStringAsFixed(0)} so\'m',
      '📝 Jami yozuvlar: $count',
    ];

    if (categoryTotals.isNotEmpty) {
      lines.add('');
      lines.add('Xarajat kategoriyalari:');
      final sorted = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted.take(5)) {
        lines.add('  • ${e.key}: ${e.value.toStringAsFixed(0)} so\'m');
      }
    }

    return ActionResult(
      success: true,
      message: lines.join('\n'),
    );
  }

  Future<ActionResult> _listReminders() async {
    final reminders = ReminderService().getUpcoming();
    if (reminders.isEmpty) {
      return const ActionResult(
        success: true,
        message: 'Hozircha kutilayotgan eslatmalar yo\'q',
      );
    }

    final lines = reminders.take(10).map((r) {
      final time = '${r.triggerAt.hour.toString().padLeft(2, '0')}:${r.triggerAt.minute.toString().padLeft(2, '0')}';
      final date = '${r.triggerAt.day}.${r.triggerAt.month}';
      return '⏰ $date $time — ${r.title}';
    }).toList();

    return ActionResult(
      success: true,
      message: 'Kutilayotgan eslatmalar:\n${lines.join('\n')}',
    );
  }

  Future<ActionResult> _takeNote(ActionCommand action) async {
    final title = action.params['title']?.toString() ?? '';
    final content = action.params['content']?.toString() ?? title;

    if (title.isEmpty && content.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Qayd matni bo\'sh — nima yozib qo\'yay?',
      );
    }

    final box = Hive.box('notes');
    final id = _uuid.v4();
    await box.put(id, {
      'id': id,
      'title': title.isNotEmpty ? title : content.substring(0, content.length.clamp(0, 50)),
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });

    return ActionResult(
      success: true,
      message: 'Qayd saqlandi: ${title.isNotEmpty ? title : content.substring(0, content.length.clamp(0, 50))}',
    );
  }

  Future<ActionResult> _getNotes() async {
    final box = Hive.box('notes');
    if (box.isEmpty) {
      return const ActionResult(
        success: true,
        message: 'Hozircha hech qanday qayd yo\'q',
      );
    }

    final notes = box.values.whereType<Map>().toList();
    notes.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    final lines = notes.take(10).map((n) {
      final title = n['title']?.toString() ?? 'Nomsiz';
      final date = DateTime.tryParse(n['created_at']?.toString() ?? '');
      final dateStr = date != null ? '${date.day}.${date.month.toString().padLeft(2, '0')}' : '';
      return '📝 $dateStr — $title';
    }).toList();

    return ActionResult(
      success: true,
      message: 'Qaydlar (${notes.length} ta):\n${lines.join('\n')}',
    );
  }

  Future<ActionResult> _deleteNote(ActionCommand action) async {
    final title = action.params['title']?.toString().toLowerCase() ?? '';
    if (title.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'Qaysi qaydni o\'chirishim kerak?',
      );
    }

    final box = Hive.box('notes');
    String? keyToDelete;
    for (final key in box.keys) {
      final note = box.get(key);
      if (note is Map) {
        final noteTitle = note['title']?.toString().toLowerCase() ?? '';
        if (noteTitle.contains(title)) {
          keyToDelete = key.toString();
          break;
        }
      }
    }

    if (keyToDelete == null) {
      return ActionResult(
        success: false,
        message: '"$title" nomli qayd topilmadi',
      );
    }

    await box.delete(keyToDelete);
    return const ActionResult(
      success: true,
      message: 'Qayd o\'chirildi',
    );
  }

  String _buildBookkeepingSummary() {
    final box = Hive.box('bookkeeping');
    if (box.isEmpty) return '';

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    double monthIncome = 0;
    double monthExpense = 0;
    final recentItems = <String>[];

    for (final raw in box.values) {
      if (raw is! Map) continue;
      final date = DateTime.tryParse(raw['date']?.toString() ?? '');
      if (date == null || date.isBefore(monthStart)) continue;

      final amount = (raw['amount'] as num?)?.toDouble() ?? 0;
      final type = raw['type'] as int?;
      final title = raw['title']?.toString() ?? '';

      if (type == 0) {
        monthIncome += amount;
      } else {
        monthExpense += amount;
      }

      if (recentItems.length < 5) {
        final label = type == 0 ? 'kirim' : 'chiqim';
        recentItems.add('$title: ${amount.toStringAsFixed(0)} so\'m ($label)');
      }
    }

    final lines = <String>[
      'Bu oy kirim: ${monthIncome.toStringAsFixed(0)} so\'m',
      'Bu oy chiqim: ${monthExpense.toStringAsFixed(0)} so\'m',
      'Balans: ${(monthIncome - monthExpense).toStringAsFixed(0)} so\'m',
    ];
    if (recentItems.isNotEmpty) {
      lines.add('So\'nggi yozuvlar: ${recentItems.join("; ")}');
    }
    return 'BUXGALTERIYA MA\'LUMOTLARI (joriy oy):\n${lines.join("\n")}';
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> clearHistory() async {
    state = const ChatState();
    await _box.clear();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
