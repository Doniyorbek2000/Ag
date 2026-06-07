import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/voice_service.dart';
import '../providers/chat_provider.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  final bool autoListen;

  const VoiceScreen({super.key, this.autoListen = false});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final VoiceService _voiceService = VoiceService();
  String _statusText = 'Bosing va gapiring';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _voiceService.initialize();
    _voiceService.addListener(_onVoiceChanged);

    if (widget.autoListen) {
      // "Hey ADM AI" woke the app up — start listening for the actual
      // command right away instead of waiting for a tap.
      WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
    }
  }

  void _onVoiceChanged() {
    setState(() {
      if (_voiceService.isListening) {
        _statusText = _voiceService.recognizedText.isEmpty
            ? 'Eshitilmoqda...'
            : _voiceService.recognizedText;
        _waveController.repeat(reverse: true);
      } else {
        _waveController.stop();
        _waveController.reset();
      }
    });
  }

  Future<void> _startListening() async {
    setState(() => _statusText = 'Eshitilmoqda...');
    await _voiceService.startListening(
      onResult: (text) {
        _processVoiceCommand(text);
      },
    );
  }

  Future<void> _stopListening() async {
    await _voiceService.stopListening();
    setState(() => _statusText = 'Bosing va gapiring');
  }

  Future<void> _processVoiceCommand(String text) async {
    if (text.isEmpty) return;
    setState(() => _statusText = 'Qayta ishlanmoqda...');

    await ref.read(chatProvider.notifier).sendMessage(text, isVoice: true);

    final state = ref.read(chatProvider);
    final lastAiMsg = state.messages.lastOrNull;
    if (lastAiMsg != null && !lastAiMsg.isUser) {
      await _voiceService.speak(lastAiMsg.content);
    }

    setState(() => _statusText = 'Bosing va gapiring');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _voiceService.removeListener(_onVoiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWaveVisualizer(),
                    const SizedBox(height: 48),
                    _buildMicButton(),
                    const SizedBox(height: 32),
                    _buildStatusText(),
                    const SizedBox(height: 20),
                    _buildSuggestions(),
                  ],
                ),
              ),
              _buildLanguageSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ADM AI Ovozli Boshqarish',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildWaveVisualizer() {
    return SizedBox(
      height: 100,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, _) {
          return CustomPaint(
            painter: WavePainter(
              animation: _waveController.value,
              isActive: _voiceService.isListening,
              soundLevel: _voiceService.soundLevel,
            ),
            child: const SizedBox(width: 300, height: 100),
          );
        },
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTapDown: (_) => _startListening(),
      onTapUp: (_) => _stopListening(),
      onTapCancel: () => _stopListening(),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (_voiceService.isListening) ...[
                Container(
                  width: 150 + _pulseController.value * 30,
                  height: 150 + _pulseController.value * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                  ),
                ),
                Container(
                  width: 130 + _pulseController.value * 20,
                  height: 130 + _pulseController.value * 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                  ),
                ),
              ],
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _voiceService.isListening
                      ? const LinearGradient(
                          colors: [AppTheme.error, Color(0xFFFF8F00)],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: (_voiceService.isListening
                              ? AppTheme.error
                              : AppTheme.primaryBlue)
                          .withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _voiceService.isListening ? Icons.stop_rounded : Icons.mic,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusText() {
    return Text(
      _statusText,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    ).animate(onPlay: (c) => c.repeat(reverse: true)).then().shimmer(
          duration: 2000.ms,
          color: AppTheme.accentCyan,
        );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'YouTube\'da musiqa qo\'y',
      'Telegramni och',
      'Havo qanday?',
      'Qo\'ng\'iroq qil',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions
          .map(
            (s) => GestureDetector(
              onTap: () => _processVoiceCommand(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LangChip(
            label: "O'zbekcha",
            locale: 'uz-UZ',
            voiceService: _voiceService,
          ),
          const SizedBox(width: 8),
          _LangChip(
            label: 'Русский',
            locale: 'ru-RU',
            voiceService: _voiceService,
          ),
          const SizedBox(width: 8),
          _LangChip(
            label: 'English',
            locale: 'en-US',
            voiceService: _voiceService,
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final String locale;
  final VoiceService voiceService;

  const _LangChip({
    required this.label,
    required this.locale,
    required this.voiceService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => voiceService.setLanguage(locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animation;
  final bool isActive;
  final double soundLevel;

  WavePainter({
    required this.animation,
    required this.isActive,
    required this.soundLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) {
      _drawIdleWave(canvas, size);
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [AppTheme.primaryBlue, AppTheme.primaryPurple, AppTheme.accentCyan],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final barCount = 32;
    final barWidth = size.width / barCount - 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (size.width / barCount);
      final waveOffset = math.sin(i * 0.3 + animation * math.pi * 2);
      final randomHeight = (soundLevel / 40).clamp(0.1, 1.0);
      final height = size.height * 0.3 +
          waveOffset.abs() * size.height * 0.7 * randomHeight;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - height) / 2, barWidth, height),
        const Radius.circular(3),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  void _drawIdleWave(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final barCount = 32;
    final barWidth = size.width / barCount - 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (size.width / barCount);
      const height = 4.0;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - height) / 2, barWidth, height),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter old) =>
      old.animation != animation || old.isActive != isActive;
}
