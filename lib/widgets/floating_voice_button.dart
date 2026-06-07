import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/voice_service.dart';

class FloatingVoiceButton extends StatefulWidget {
  const FloatingVoiceButton({super.key});

  @override
  State<FloatingVoiceButton> createState() => _FloatingVoiceButtonState();
}

class _FloatingVoiceButtonState extends State<FloatingVoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _voiceService.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    _voiceService.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/voice'),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 64 + _controller.value * 8,
              height: 64 + _controller.value * 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0x402979FF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
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
                    color: AppTheme.primaryBlue.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 500.ms)
        .scale(begin: const Offset(0, 0), duration: 600.ms, curve: Curves.elasticOut);
  }
}
