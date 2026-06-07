import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin/admin_auth_provider.dart';

/// Shell for the admin panel — gates access to authenticated admins and
/// provides bottom navigation between the admin sections.
class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/admin/users')) return 1;
    if (location.startsWith('/admin/subscriptions')) return 2;
    if (location.startsWith('/admin/tickets')) return 3;
    if (location.startsWith('/admin/broadcasts')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin');
      case 1:
        context.go('/admin/users');
      case 2:
        context.go('/admin/subscriptions');
      case 3:
        context.go('/admin/tickets');
      case 4:
        context.go('/admin/broadcasts');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);

    if (auth.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/admin/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AdminNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Statistika',
                  isActive: index == 0,
                  onTap: () => _onTap(context, 0),
                ),
                _AdminNavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people_rounded,
                  label: 'Foydalanuvchilar',
                  isActive: index == 1,
                  onTap: () => _onTap(context, 1),
                ),
                _AdminNavItem(
                  icon: Icons.workspace_premium_outlined,
                  activeIcon: Icons.workspace_premium_rounded,
                  label: 'Obunalar',
                  isActive: index == 2,
                  onTap: () => _onTap(context, 2),
                ),
                _AdminNavItem(
                  icon: Icons.support_agent_outlined,
                  activeIcon: Icons.support_agent_rounded,
                  label: 'Murojaatlar',
                  isActive: index == 3,
                  onTap: () => _onTap(context, 3),
                ),
                _AdminNavItem(
                  icon: Icons.campaign_outlined,
                  activeIcon: Icons.campaign_rounded,
                  label: 'Xabarnoma',
                  isActive: index == 4,
                  onTap: () => _onTap(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textHint,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textHint,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared header used across admin screens.
class AdminHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onRefresh;

  const AdminHeader({super.key, required this.title, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: onRefresh,
            ),
          Consumer(builder: (context, ref, _) {
            return IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
              tooltip: 'Chiqish',
              onPressed: () async {
                await ref.read(adminAuthProvider.notifier).logout();
                if (context.mounted) context.go('/admin/login');
              },
            );
          }),
        ],
      ),
    );
  }
}
