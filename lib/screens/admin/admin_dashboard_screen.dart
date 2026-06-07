import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin/admin_provider.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminStatsProvider);
    final stats = state.stats;
    final currency = NumberFormat.decimalPattern('uz');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(adminStatsProvider.notifier).load(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AdminHeader(
                    title: 'Boshqaruv paneli',
                    onRefresh: () => ref.read(adminStatsProvider.notifier).load(),
                  ),
                ),
                if (state.isLoading && stats == null)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.error != null && stats == null)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(state.error!,
                          style: const TextStyle(color: AppTheme.error)),
                    ),
                  )
                else if (stats != null) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      delegate: SliverChildListDelegate([
                        _StatCard(
                          icon: Icons.people_alt_rounded,
                          color: AppTheme.primaryBlue,
                          label: 'Jami foydalanuvchilar',
                          value: '${stats.totalUsers}',
                        ),
                        _StatCard(
                          icon: Icons.bolt_rounded,
                          color: AppTheme.success,
                          label: 'Faol foydalanuvchilar',
                          value: '${stats.activeUsers}',
                        ),
                        _StatCard(
                          icon: Icons.payments_rounded,
                          color: AppTheme.accentGold,
                          label: 'Daromad (so\'m)',
                          value: currency.format(stats.revenue),
                        ),
                        _StatCard(
                          icon: Icons.support_agent_rounded,
                          color: AppTheme.warning,
                          label: 'Ochiq murojaatlar',
                          value: '${stats.openTickets}',
                        ),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(child: _PlanBreakdown(planCounts: stats.planCounts)),
                  SliverToBoxAdapter(
                    child: _ChartCard(
                      title: 'So\'nggi 7 kunlik yangi foydalanuvchilar',
                      data: stats.newUsersLast7Days,
                      barColor: AppTheme.primaryBlue,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ChartCard(
                      title: 'So\'nggi 7 kunlik AI so\'rovlar',
                      data: stats.usageLast7Days,
                      barColor: AppTheme.accentCyan,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PlanBreakdown extends StatelessWidget {
  final Map<String, int> planCounts;

  const _PlanBreakdown({required this.planCounts});

  static const _planLabels = {
    'free': 'Bepul',
    'pro': 'Pro',
    'ultra': 'Ultra',
    'vip': 'VIP',
  };

  static const _planColors = {
    'free': AppTheme.textHint,
    'pro': AppTheme.primaryBlue,
    'ultra': AppTheme.primaryPurple,
    'vip': AppTheme.accentGold,
  };

  @override
  Widget build(BuildContext context) {
    final total = planCounts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
            'Tariflar bo\'yicha taqsimot',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: [
                      for (final entry in planCounts.entries)
                        PieChartSectionData(
                          value: entry.value.toDouble(),
                          color: _planColors[entry.key] ?? AppTheme.textHint,
                          title: '',
                          radius: 22,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in planCounts.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _planColors[entry.key] ?? AppTheme.textHint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _planLabels[entry.key] ?? entry.key,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            const Spacer(),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final Color barColor;

  const _ChartCard({required this.title, required this.data, required this.barColor});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data
        .map((d) => (d['count'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxVal <= 0 ? 5 : maxVal * 1.3,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox.shrink();
                        final day = data[i]['day']?.toString() ?? '';
                        final label = day.length >= 10 ? day.substring(5) : day;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(label,
                              style: const TextStyle(color: AppTheme.textHint, fontSize: 9)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (data[i]['count'] as num?)?.toDouble() ?? 0,
                          color: barColor,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
