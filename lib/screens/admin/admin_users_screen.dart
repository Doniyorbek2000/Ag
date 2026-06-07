import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin/admin_provider.dart';
import 'admin_shell.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();

  static const _plans = ['free', 'pro', 'ultra', 'vip'];
  static const _planLabels = {'free': 'Bepul', 'pro': 'Pro', 'ultra': 'Ultra', 'vip': 'VIP'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              AdminHeader(title: 'Foydalanuvchilar', onRefresh: () => notifier.load()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Ism yoki email bo\'yicha qidirish...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onSubmitted: notifier.setSearch,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'Barchasi',
                      selected: state.planFilter == null,
                      onTap: () => notifier.setPlanFilter(null),
                    ),
                    for (final plan in _plans)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: _planLabels[plan]!,
                          selected: state.planFilter == plan,
                          onTap: () => notifier.setPlanFilter(plan),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: state.isLoading && state.users.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.users.isEmpty
                        ? const Center(
                            child: Text('Foydalanuvchilar topilmadi',
                                style: TextStyle(color: AppTheme.textSecondary)),
                          )
                        : RefreshIndicator(
                            onRefresh: () => notifier.load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                              itemCount: state.users.length,
                              itemBuilder: (context, index) {
                                final user = state.users[index];
                                return _UserTile(
                                  user: user,
                                  onTap: () => _showUserActions(context, user),
                                );
                              },
                            ),
                          ),
              ),
              if (state.totalPages > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 100, top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                        onPressed: state.page > 1
                            ? () => notifier.load(page: state.page - 1)
                            : null,
                      ),
                      Text('${state.page} / ${state.totalPages}',
                          style: const TextStyle(color: AppTheme.textSecondary)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                        onPressed: state.page < state.totalPages
                            ? () => notifier.load(page: state.page + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserActions(BuildContext context, AdminUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _UserActionsSheet(user: user),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : Colors.white.withOpacity(0.08),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  static const _planColors = {
    'free': AppTheme.textHint,
    'pro': AppTheme.primaryBlue,
    'ultra': AppTheme.primaryPurple,
    'vip': AppTheme.accentGold,
  };

  @override
  Widget build(BuildContext context) {
    final planColor = _planColors[user.plan] ?? AppTheme.textHint;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: planColor.withOpacity(0.2),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(color: planColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name.isNotEmpty ? user.name : 'Noma\'lum',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.role == 'admin') ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.shield_rounded, size: 14, color: AppTheme.accentGold),
                          ],
                          if (!user.isActive) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.block_rounded, size: 14, color: AppTheme.error),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.plan.toUpperCase(),
                    style: TextStyle(color: planColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserActionsSheet extends ConsumerStatefulWidget {
  final AdminUser user;

  const _UserActionsSheet({required this.user});

  @override
  ConsumerState<_UserActionsSheet> createState() => _UserActionsSheetState();
}

class _UserActionsSheetState extends ConsumerState<_UserActionsSheet> {
  late String _plan;
  late String _role;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.user.plan;
    _role = widget.user.role;
    _isActive = widget.user.isActive;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(adminUsersProvider.notifier).updateUser(
          widget.user.id,
          plan: _plan,
          role: _role,
          isActive: _isActive,
        );
    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('O\'chirishni tasdiqlang', style: TextStyle(color: Colors.white)),
        content: Text(
          '${widget.user.name} (${widget.user.email}) hisobi butunlay o\'chiriladi.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'chirish', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await ref.read(adminUsersProvider.notifier).deleteUser(widget.user.id);
      if (ok && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.user.name,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(widget.user.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          const Text('Tarif rejasi', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final plan in _AdminUsersScreenState._plans)
                ChoiceChip(
                  label: Text(_AdminUsersScreenState._planLabels[plan]!),
                  selected: _plan == plan,
                  onSelected: (_) => setState(() => _plan = plan),
                  selectedColor: AppTheme.primaryBlue,
                  backgroundColor: AppTheme.bgSurface,
                  labelStyle: TextStyle(
                    color: _plan == plan ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Rol', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Foydalanuvchi'),
                selected: _role == 'user',
                onSelected: (_) => setState(() => _role = 'user'),
                selectedColor: AppTheme.primaryBlue,
                backgroundColor: AppTheme.bgSurface,
                labelStyle: TextStyle(
                    color: _role == 'user' ? Colors.white : AppTheme.textSecondary, fontSize: 12),
              ),
              ChoiceChip(
                label: const Text('Administrator'),
                selected: _role == 'admin',
                onSelected: (_) => setState(() => _role = 'admin'),
                selectedColor: AppTheme.primaryPurple,
                backgroundColor: AppTheme.bgSurface,
                labelStyle: TextStyle(
                    color: _role == 'admin' ? Colors.white : AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Hisob faol', style: TextStyle(color: Colors.white, fontSize: 14)),
            activeColor: AppTheme.success,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                  label: const Text('O\'chirish', style: TextStyle(color: AppTheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Saqlash'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
