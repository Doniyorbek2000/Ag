import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin/admin_provider.dart';
import 'admin_shell.dart';

class AdminBroadcastsScreen extends ConsumerStatefulWidget {
  const AdminBroadcastsScreen({super.key});

  @override
  ConsumerState<AdminBroadcastsScreen> createState() => _AdminBroadcastsScreenState();
}

class _AdminBroadcastsScreenState extends ConsumerState<AdminBroadcastsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _targetPlan = 'all';

  static const _plans = ['all', 'free', 'pro', 'ultra', 'vip'];
  static const _planLabels = {
    'all': 'Barchasi',
    'free': 'Bepul',
    'pro': 'Pro',
    'ultra': 'Ultra',
    'vip': 'VIP',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) return;
    final ok = await ref.read(adminBroadcastsProvider.notifier).send(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          targetPlan: _targetPlan,
        );
    if (ok && mounted) {
      _titleController.clear();
      _bodyController.clear();
      setState(() => _targetPlan = 'all');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xabarnoma yuborildi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminBroadcastsProvider);
    final notifier = ref.read(adminBroadcastsProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              AdminHeader(title: 'Xabarnomalar', onRefresh: () => notifier.load()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  children: [
                    _ComposeCard(
                      titleController: _titleController,
                      bodyController: _bodyController,
                      targetPlan: _targetPlan,
                      onPlanChanged: (p) => setState(() => _targetPlan = p),
                      onSend: _send,
                      isSending: state.isSending,
                      error: state.error,
                      plans: _plans,
                      planLabels: _planLabels,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Yuborilgan xabarnomalar',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (state.isLoading && state.broadcasts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state.broadcasts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                            child: Text('Hali xabarnoma yuborilmagan',
                                style: TextStyle(color: AppTheme.textSecondary))),
                      )
                    else
                      for (final broadcast in state.broadcasts)
                        _BroadcastCard(broadcast: broadcast, planLabels: _planLabels),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposeCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final String targetPlan;
  final ValueChanged<String> onPlanChanged;
  final VoidCallback onSend;
  final bool isSending;
  final String? error;
  final List<String> plans;
  final Map<String, String> planLabels;

  const _ComposeCard({
    required this.titleController,
    required this.bodyController,
    required this.targetPlan,
    required this.onPlanChanged,
    required this.onSend,
    required this.isSending,
    required this.error,
    required this.plans,
    required this.planLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yangi xabarnoma yuborish',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Sarlavha'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Xabar matni'),
          ),
          const SizedBox(height: 12),
          const Text('Qabul qiluvchilar', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final plan in plans)
                ChoiceChip(
                  label: Text(planLabels[plan]!),
                  selected: targetPlan == plan,
                  onSelected: (_) => onPlanChanged(plan),
                  selectedColor: AppTheme.primaryBlue,
                  backgroundColor: AppTheme.bgSurface,
                  labelStyle: TextStyle(
                    color: targetPlan == plan ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(isSending ? 'Yuborilmoqda...' : 'Yuborish'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  final AdminBroadcast broadcast;
  final Map<String, String> planLabels;

  const _BroadcastCard({required this.broadcast, required this.planLabels});

  @override
  Widget build(BuildContext context) {
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
                  broadcast.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  planLabels[broadcast.targetPlan] ?? broadcast.targetPlan,
                  style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            broadcast.body,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 14, color: AppTheme.textHint),
              const SizedBox(width: 4),
              Text('${broadcast.sentCount} qabul qiluvchi',
                  style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
              const Spacer(),
              Text(_formatDate(broadcast.createdAt),
                  style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd.MM.yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
