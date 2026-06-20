import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/subscription_model.dart';
import '../widgets/quick_action_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final planModel = SubscriptionPlanModel.plans
        .firstWhere((p) => p.plan == user.plan);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, user, planModel)),
              SliverToBoxAdapter(child: _buildAiCard(context)),
              SliverToBoxAdapter(child: _buildQuickActions(context)),
              SliverToBoxAdapter(child: _buildRecentApps(context)),
              SliverToBoxAdapter(child: _buildStats(user, planModel)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserState user, SubscriptionPlanModel plan) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Text(
                  user.name?.isNotEmpty == true ? user.name! : 'Foydalanuvchi',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildPlanBadge(plan),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2);
  }

  Widget _buildPlanBadge(SubscriptionPlanModel plan) {
    final colors = {
      SubscriptionPlan.free: [Colors.grey, Colors.grey.shade600],
      SubscriptionPlan.pro: [AppTheme.primaryBlue, AppTheme.primaryPurple],
      SubscriptionPlan.ultra: [AppTheme.accentCyan, AppTheme.primaryBlue],
      SubscriptionPlan.vip: [AppTheme.accentGold, const Color(0xFFFF8F00)],
    };

    final planColors = colors[plan.plan]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: planColors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        plan.name.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildAiCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () => context.go('/chat'),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A4E), Color(0xFF12123A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADM AI bilan gaplashing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nima yordam bera olaman?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideX(begin: -0.1);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      QuickAction(
        icon: '📞',
        label: 'Call Center',
        color: const Color(0xFF00E676),
        route: '/call-center',
      ),
      QuickAction(
        icon: '📊',
        label: 'Moliya',
        color: const Color(0xFFFFD740),
        route: '/bookkeeping',
      ),
      QuickAction(
        icon: '📱',
        label: 'Ilovalar',
        color: AppTheme.primaryPurple,
        route: '/apps',
      ),
      QuickAction(
        icon: '👥',
        label: 'Kontaktlar',
        color: const Color(0xFF00E5FF),
        route: '/contacts',
      ),
    ];

    final actions2 = [
      QuickAction(
        icon: '🎤',
        label: 'Ovozli',
        color: const Color(0xFFE040FB),
        route: '/voice',
      ),
      QuickAction(
        icon: '📅',
        label: 'Kalendar',
        color: const Color(0xFF4285F4),
        route: '/chat',
      ),
      QuickAction(
        icon: '✉️',
        label: 'Email',
        color: const Color(0xFFEA4335),
        route: '/chat',
      ),
      QuickAction(
        icon: '⏰',
        label: 'Eslatma',
        color: const Color(0xFFFF6D00),
        route: '/chat',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tezkor amallar',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              Row(
                children: actions
                    .map(
                      (a) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: QuickActionCard(
                            icon: a.icon,
                            label: a.label,
                            color: a.color,
                            onTap: () => context.go(a.route),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: actions2
                    .map(
                      (a) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: QuickActionCard(
                            icon: a.icon,
                            label: a.label,
                            color: a.color,
                            onTap: () => context.go(a.route),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildRecentApps(BuildContext context) {
    final apps = [
      AppItem(icon: '📱', name: 'Telegram', package: 'telegram'),
      AppItem(icon: '💬', name: 'WhatsApp', package: 'whatsapp'),
      AppItem(icon: '▶️', name: 'YouTube', package: 'youtube'),
      AppItem(icon: '📸', name: 'Instagram', package: 'instagram'),
      AppItem(icon: '🎵', name: 'Musiqa', package: 'music'),
      AppItem(icon: '🗺️', name: 'Xarita', package: 'maps'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ilovalar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/apps'),
                child: const Text(
                  'Barchasi',
                  style: TextStyle(color: AppTheme.primaryBlue, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: apps.length,
              itemBuilder: (ctx, i) {
                final app = apps[i];
                return GestureDetector(
                  onTap: () => context.go('/apps'),
                  child: Container(
                    width: 64,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              app.icon,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          app.name,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildStats(UserState user, SubscriptionPlanModel plan) {
    final remaining = user.remainingCalls;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Qolgan so\'rovlar',
                value: remaining == -1 ? '∞' : remaining.toString(),
                icon: Icons.chat_bubble_outline,
                color: AppTheme.primaryBlue,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withOpacity(0.08),
            ),
            Expanded(
              child: _StatItem(
                label: 'Tarif reja',
                value: plan.name,
                icon: Icons.star_outline,
                color: AppTheme.accentGold,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withOpacity(0.08),
            ),
            Expanded(
              child: _StatItem(
                label: 'Bugungi chat',
                value: user.dailyCallsUsed.toString(),
                icon: Icons.trending_up,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 500.ms);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Yaxshi tun 🌙';
    if (hour < 12) return 'Xayrli tong ☀️';
    if (hour < 17) return 'Xayrli kun 🌤️';
    if (hour < 21) return 'Xayrli kech 🌆';
    return 'Xayrli oqshom 🌙';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textHint,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class QuickAction {
  final String icon;
  final String label;
  final Color color;
  final String route;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

class AppItem {
  final String icon;
  final String name;
  final String package;

  const AppItem({
    required this.icon,
    required this.name,
    required this.package,
  });
}
