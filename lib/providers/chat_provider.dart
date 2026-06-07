import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/action_executor.dart';
import 'auth_provider.dart';

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
  final _uuid = const Uuid();

  ChatNotifier(this._ref) : super(const ChatState()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // Load from Hive
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

    try {
      final history = state.messages
          .where((m) => m != userMsg)
          .take(20)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      final apiKey = user.apiKey;
      if (apiKey != null && apiKey.isNotEmpty) {
        _aiService.setApiKey(apiKey);
      }

      final response = await _aiService.sendMessage(
        message: text,
        conversationHistory: history,
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
        actionResult = await _executor.execute(
          response.action!.type,
          response.action!.params,
        );
      }

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
        lastActionResult: actionResult,
      );

      await _ref.read(authProvider.notifier).incrementDailyCall();
    } on AiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Xato yuz berdi: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearHistory() {
    state = const ChatState();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
