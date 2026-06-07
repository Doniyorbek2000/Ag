import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin/admin_provider.dart';
import 'admin_shell.dart';

class AdminTicketsScreen extends ConsumerWidget {
  const AdminTicketsScreen({super.key});

  static const _statusLabels = {
    'open': 'Ochiq',
    'in_progress': 'Jarayonda',
    'resolved': 'Hal qilingan',
    'closed': 'Yopilgan',
  };
  static const _statusColors = {
    'open': AppTheme.warning,
    'in_progress': AppTheme.primaryBlue,
    'resolved': AppTheme.success,
    'closed': AppTheme.textHint,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminTicketsProvider);
    final notifier = ref.read(adminTicketsProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              AdminHeader(title: 'Murojaatlar', onRefresh: () => notifier.load()),
              Expanded(
                child: state.isLoading && state.tickets.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.tickets.isEmpty
                        ? const Center(
                            child: Text('Murojaatlar yo\'q',
                                style: TextStyle(color: AppTheme.textSecondary)))
                        : RefreshIndicator(
                            onRefresh: () => notifier.load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                              itemCount: state.tickets.length,
                              itemBuilder: (context, index) {
                                final ticket = state.tickets[index];
                                return _TicketCard(
                                  ticket: ticket,
                                  onChangeStatus: (status) =>
                                      notifier.updateStatus(ticket.id, status),
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
}

class _TicketCard extends StatelessWidget {
  final AdminTicket ticket;
  final ValueChanged<String> onChangeStatus;

  const _TicketCard({required this.ticket, required this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    final color = AdminTicketsScreen._statusColors[ticket.status] ?? AppTheme.textHint;
    final label = AdminTicketsScreen._statusLabels[ticket.status] ?? ticket.status;

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
                  ticket.subject,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                color: AppTheme.bgSurface,
                onSelected: onChangeStatus,
                itemBuilder: (ctx) => AdminTicketsScreen._statusLabels.entries
                    .map((e) => PopupMenuItem(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                      Icon(Icons.expand_more_rounded, size: 14, color: color),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${ticket.userName} · ${ticket.userEmail}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            ticket.message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
