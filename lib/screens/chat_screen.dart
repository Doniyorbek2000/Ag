import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../models/chat_message.dart';
import '../services/voice_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _voiceService = VoiceService();
  bool _isVoiceMode = false;

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
    _voiceService.addListener(_onVoiceChanged);
  }

  void _onVoiceChanged() {
    if (!_voiceService.isListening && _voiceService.recognizedText.isNotEmpty) {
      _sendMessage(_voiceService.recognizedText, isVoice: true);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _voiceService.removeListener(_onVoiceChanged);
    super.dispose();
  }

  Future<void> _sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(chatProvider.notifier).sendMessage(text.trim(), isVoice: isVoice);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleVoice() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    } else {
      setState(() => _isVoiceMode = true);
      await _voiceService.startListening(
        onResult: (text) {
          setState(() => _isVoiceMode = false);
          _sendMessage(text, isVoice: true);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(authProvider);

    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (next.messages.length != prev?.messages.length) {
        _scrollToBottom();
        final last = next.messages.lastOrNull;
        if (last != null && !last.isUser) {
          _voiceService.speak(last.content);
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, user),
              if (chatState.error != null) _buildErrorBanner(chatState.error!),
              Expanded(
                child: chatState.messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(chatState),
              ),
              if (_isVoiceMode) _buildVoiceIndicator(),
              _buildInputArea(chatState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UserState user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADM AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Har doim tayyor',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppTheme.bgCard,
                  title: const Text(
                    'Suhbatni tozalash',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Barcha xabarlar o\'chiriladi',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Bekor'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(chatProvider.notifier).clearHistory();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'O\'chirish',
                        style: TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(chatProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: AppTheme.textHint, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final suggestions = [
      '"YouTube\'da O\'zbek musiqasi qo\'y"',
      '"Bugungi ob-havo qanday?"',
      '"Telegramni och"',
      '"1 000 000 so\'m kirim qo\'sh"',
      '"Ertaga soat 8 ga uyg\'otgich qo\'y"',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 40)),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(
              begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          const Text(
            'ADM AI tayyor!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            'Ovozda yoki yozib so\'rang',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Maslahatlar:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map(
            (e) => GestureDetector(
              onTap: () => _sendMessage(
                e.value.replaceAll('"', ''),
              ),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  e.value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ).animate(delay: Duration(milliseconds: 400 + e.key * 80)).fadeIn().slideX(begin: -0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == state.messages.length) {
          return const TypingIndicator();
        }
        return ChatBubble(message: state.messages[i]);
      },
    );
  }

  Widget _buildVoiceIndicator() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            _voiceService.recognizedText.isEmpty
                ? 'Gapiring...'
                : _voiceService.recognizedText,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildInputArea(ChatState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Xabar yozing yoki 🎙 bosing...',
                hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.bgSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleVoice,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _voiceService.isListening
                    ? const LinearGradient(
                        colors: [AppTheme.error, Color(0xFFFF8F00)],
                      )
                    : const LinearGradient(
                        colors: [AppTheme.accentCyan, AppTheme.primaryBlue],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (_voiceService.isListening
                            ? AppTheme.error
                            : AppTheme.primaryBlue)
                        .withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _voiceService.isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: state.isLoading ? null : () => _sendMessage(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: state.isLoading
                    ? LinearGradient(
                        colors: [Colors.grey.shade800, Colors.grey.shade700],
                      )
                    : AppTheme.primaryGradient,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
