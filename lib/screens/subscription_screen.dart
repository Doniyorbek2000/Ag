import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/subscription_model.dart';
import '../providers/auth_provider.dart';
import '../services/purchase_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  int _selectedPlanIndex = 1;
  final PurchaseService _purchaseService = PurchaseService();

  @override
  void initState() {
    super.initState();
    _purchaseService.initialize(
      onActivated: (plan) async {
        await ref.read(authProvider.notifier).upgradePlan(plan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Obuna tasdiqlandi va faollashtirildi!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      },
      onError: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppTheme.error),
          );
        }
      },
    );
  }

  final Map<SubscriptionPlan, Map<String, String>> _planMeta = {
    SubscriptionPlan.free: {
      'badge': '',
      'icon': '🆓',
    },
    SubscriptionPlan.pro: {
      'badge': 'Mashhur',
      'icon': '⚡',
    },
    SubscriptionPlan.ultra: {
      'badge': 'Tavsiya',
      'icon': '🚀',
    },
    SubscriptionPlan.vip: {
      'badge': 'Eng yaxshi',
      'icon': '👑',
    },
  };

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final currentPlanIndex =
        SubscriptionPlanModel.plans.indexWhere((p) => p.plan == user.plan);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPlanSelector(),
                      _buildSelectedPlanDetails(context, currentPlanIndex),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    'ADM AI Premium',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Imkoniyatlaringizni kengaytiring',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: SubscriptionPlanModel.plans.asMap().entries.map((entry) {
          final i = entry.key;
          final plan = entry.value;
          final isSelected = i == _selectedPlanIndex;
          final meta = _planMeta[plan.plan]!;

          final planColors = _getPlanColors(plan.plan);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPlanIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: planColors)
                      : null,
                  color: isSelected ? null : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? planColors.first.withOpacity(0.5)
                        : Colors.white.withOpacity(0.08),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: planColors.first.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    if (meta['badge']!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meta['badge']!,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    const SizedBox(height: 4),
                    Text(meta['icon']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      plan.price == '0' ? 'Bepul' : plan.price,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white.withOpacity(0.8)
                            : AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedPlanDetails(BuildContext context, int currentPlanIndex) {
    final plan = SubscriptionPlanModel.plans[_selectedPlanIndex];
    final planColors = _getPlanColors(plan.plan);
    final isCurrent = _selectedPlanIndex == currentPlanIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  planColors.first.withOpacity(0.2),
                  planColors.last.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: planColors.first.withOpacity(0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          LinearGradient(colors: planColors).createShader(bounds),
                      child: Text(
                        '${_planMeta[plan.plan]!['icon']} ${plan.name}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.price == '0' ? 'Bepul' : '${plan.price} so\'m',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: planColors.first,
                          ),
                        ),
                        if (plan.price != '0')
                          Text(
                            plan.period,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textHint,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Imkoniyatlar:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                ...plan.features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: planColors.first,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (plan.lockedFeatures.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...plan.lockedFeatures.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: AppTheme.textHint,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Hozirgi tarif rejangiz',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: planColors),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: planColors.first.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _subscribe(context, plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    plan.price == '0'
                        ? 'Bepul boshlash'
                        : '${plan.name} ga o\'tish',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            plan.price == '0'
                ? 'Hech qanday to\'lov talab qilinmaydi'
                : 'Istalgan vaqt bekor qilish mumkin',
            style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Future<void> _subscribe(BuildContext context, SubscriptionPlanModel plan) async {
    if (plan.plan == SubscriptionPlan.free) {
      await ref.read(authProvider.notifier).upgradePlan(plan.plan);
      if (mounted) Navigator.pop(context);
      return;
    }

    // Try real Google Play Billing first — only succeeds on a signed
    // release build with the product registered in Play Console.
    if (await _purchaseService.isAvailable) {
      final productId = PurchaseService.productIds[plan.plan];
      final products = await _purchaseService.loadProducts();
      final product = products.where((p) => p.id == productId).firstOrNull;

      if (product != null) {
        final launched = await _purchaseService.buy(plan.plan, product);
        if (launched) return; // Play billing sheet handles the rest via the purchase stream
      }
    }

    _showDemoActivationDialog(context, plan);
  }

  void _showDemoActivationDialog(BuildContext context, SubscriptionPlanModel plan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text(
          '${plan.name} rejasiga o\'tish',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Oyiga ${plan.price} so\'m to\'lanadi.\n'
          'Google Play to\'lov tizimi mavjud emas (sinov/debug build yoki '
          'mahsulot Play Console\'da ro\'yxatdan o\'tmagan), shuning uchun '
          'reja qo\'lda faollashtiriladi — bu rejim haqiqiy to\'lovni '
          'tasdiqlamaydi.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).upgradePlan(plan.plan);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${plan.name} rejasi faollashtirildi!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text(
              'Faollashtirish',
              style: TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getPlanColors(SubscriptionPlan plan) {
    return switch (plan) {
      SubscriptionPlan.free => [Colors.grey.shade600, Colors.grey.shade800],
      SubscriptionPlan.pro => [AppTheme.primaryBlue, AppTheme.primaryPurple],
      SubscriptionPlan.ultra => [AppTheme.accentCyan, AppTheme.primaryBlue],
      SubscriptionPlan.vip => [AppTheme.accentGold, const Color(0xFFFF8F00)],
    };
  }
}
