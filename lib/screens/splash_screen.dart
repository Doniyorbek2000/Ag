import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 3000), _navigate);
  }

  void _navigate() {
    final user = ref.read(authProvider);
    if (user.isOnboarded) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildTagline(),
              const SizedBox(height: 80),
              _buildLoader(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(
                  0.3 + _pulseController.value * 0.3,
                ),
                blurRadius: 30 + _pulseController.value * 20,
                spreadRadius: 5 + _pulseController.value * 10,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'ADM',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 800.ms)
        .scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.elasticOut);
  }

  Widget _buildTitle() {
    return const Text(
      'ADM AI',
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 3,
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, duration: 600.ms);
  }

  Widget _buildTagline() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppTheme.accentCyan, AppTheme.primaryBlue, AppTheme.primaryPurple],
      ).createShader(bounds),
      child: const Text(
        'Sizning aqlli yordamchingiz',
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
      ),
    )
        .animate(delay: 600.ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, duration: 600.ms);
  }

  Widget _buildLoader() {
    return SizedBox(
      width: 40,
      height: 4,
      child: LinearProgressIndicator(
        backgroundColor: Colors.white.withOpacity(0.1),
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        borderRadius: BorderRadius.circular(2),
      ),
    ).animate(delay: 800.ms).fadeIn(duration: 400.ms);
  }
}
