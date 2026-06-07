import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin/admin_provider.dart';
import 'admin_shell.dart';

class AdminSubscriptionsScreen extends ConsumerWidget {
  const AdminSubscriptionsScreen({super.key});

  static const _planLabels = {'free': 'Bepul', 'pro': 'Pro', 'ultra': 'Ultra', 'vip': 'VIP'};
  static const _planColors = {
    'free': AppTheme.textHint,
    'pro': AppTheme.primaryBlue,
    'ultra': AppTheme.primaryPurple,
    'vip': AppTheme.accentGold,
  };
  static const _statusLabels = {
    'active': 'Faol',
    'cancelled': 'Bekor qilingan',
    'expired': 'Muddati tugagan',
  };
  static const _statusColors = {
    'active': AppTheme.success,
    'cancelled': AppTheme.error,
    'expired': AppTheme.warning,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminSubscriptionsProvider);
    final notifier = ref.read(adminSubscriptionsProvider.notifier);
    final currency = NumberFormat.decimalPattern('uz');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              AdminHeader(title: 'Obunalar', onRefresh: () => notifier.load()),
              Expanded(
                child: state.isLoading && state.subscriptions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null && state.subscriptions.isEmpty
                        ? Center(
                            child: Text(state.error!, style: const TextStyle(color: AppTheme.error)))
                        : state.subscriptions.isEmpty
                            ? const Center(
                                child: Text('Obunalar topilmadi',
                                    style: TextStyle(color: AppTheme.textSecondary)))
                            : RefreshIndicator(
                                onRefresh: () => notifier.load(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                                  itemCount: state.subscriptions.length,
                                  itemBuilder: (context, index) {
                                    final sub = state.subscriptions[index];
                                    final planColor = _planColors[sub.plan] ?? AppTheme.textHint;
                                    final statusColor =
                                        _statusColors[sub.status] ?? AppTheme.textHint;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgCard,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  sub.userName.isNotEmpty
                                                      ? sub.userName
                                                      : sub.userEmail,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: planColor.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  (_planLabels[sub.plan] ?? sub.plan).toUpperCase(),
                                                  style: TextStyle(
                                                      color: planColor,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(sub.userEmail,
                                              style: const TextStyle(
                                                  color: AppTheme.textSecondary, fontSize: 12)),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Icon(Icons.circle, size: 8, color: statusColor),
                                              const SizedBox(width: 6),
                                              Text(
                                                _statusLabels[sub.status] ?? sub.status,
                                                style: TextStyle(color: statusColor, fontSize: 12),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${currency.format(sub.amount)} so\'m',
                                                style: const TextStyle(
                                                    color: AppTheme.accentGold,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                'Provayder: ${sub.provider}',
                                                style: const TextStyle(
                                                    color: AppTheme.textHint, fontSize: 11),
                                              ),
                                              const Spacer(),
                                              if (sub.expiresAt != null)
                                                Text(
                                                  'Tugaydi: ${_formatDate(sub.expiresAt!)}',
                                                  style: const TextStyle(
                                                      color: AppTheme.textHint, fontSize: 11),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
