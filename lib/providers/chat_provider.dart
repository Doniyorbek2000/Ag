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
import '../services/crash_reporting_service.dart';
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

      final response = await _aiService.sendMessage(
        message: text,
        conversationHistory: history,
        contextInfo: memorySummary.isEmpty ? null : memorySummary,
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
      }

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
        lastActionResult: actionResult,
      );
      await _persist(aiMsg);

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
      default:
        return _executor.execute(action.type, action.params);
    }
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
