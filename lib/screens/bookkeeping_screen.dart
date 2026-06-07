import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/bookkeeping_entry.dart';

final bookkeepingProvider = StateNotifierProvider<BookkeepingNotifier, List<BookkeepingEntry>>((ref) {
  return BookkeepingNotifier();
});

class BookkeepingNotifier extends StateNotifier<List<BookkeepingEntry>> {
  final Box _box = Hive.box('bookkeeping');
  final _uuid = const Uuid();

  BookkeepingNotifier() : super([]) {
    _load();
  }

  void _load() {
    final entries = _box.values
        .cast<Map>()
        .map((m) => BookkeepingEntry(
              id: m['id'] as String,
              title: m['title'] as String,
              amount: (m['amount'] as num).toDouble(),
              type: EntryType.values[m['type'] as int],
              category: m['category'] as String,
              date: DateTime.parse(m['date'] as String),
              note: m['note'] as String?,
            ))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    state = entries;
  }

  Future<void> addEntry({
    required String title,
    required double amount,
    required EntryType type,
    required String category,
    String? note,
  }) async {
    final entry = BookkeepingEntry(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: DateTime.now(),
      note: note,
    );
    await _box.put(entry.id, {
      'id': entry.id,
      'title': entry.title,
      'amount': entry.amount,
      'type': entry.type.index,
      'category': entry.category,
      'date': entry.date.toIso8601String(),
      'note': entry.note,
    });
    state = [entry, ...state];
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
    state = state.where((e) => e.id != id).toList();
  }

  double get totalIncome => state
      .where((e) => e.type == EntryType.income)
      .fold(0, (sum, e) => sum + e.amount);

  double get totalExpense => state
      .where((e) => e.type == EntryType.expense)
      .fold(0, (sum, e) => sum + e.amount);

  double get balance => totalIncome - totalExpense;
}

class BookkeepingScreen extends ConsumerStatefulWidget {
  const BookkeepingScreen({super.key});

  @override
  ConsumerState<BookkeepingScreen> createState() => _BookkeepingScreenState();
}

class _BookkeepingScreenState extends ConsumerState<BookkeepingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    EntryType type = EntryType.expense;
    String category = expenseCategories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final categories =
              type == EntryType.expense ? expenseCategories : incomeCategories;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Yangi yozuv',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          type = EntryType.expense;
                          category = expenseCategories.first;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: type == EntryType.expense
                                ? AppTheme.error.withOpacity(0.2)
                                : AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: type == EntryType.expense
                                  ? AppTheme.error
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '📤 Xarajat',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          type = EntryType.income;
                          category = incomeCategories.first;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: type == EntryType.income
                                ? AppTheme.success.withOpacity(0.2)
                                : AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: type == EntryType.income
                                  ? AppTheme.success
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '📥 Daromad',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Sarlavha',
                    labelStyle: TextStyle(color: AppTheme.textHint),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Miqdor (so\'m)',
                    labelStyle: TextStyle(color: AppTheme.textHint),
                    prefixText: '₽ ',
                    prefixStyle: TextStyle(color: AppTheme.textHint),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: AppTheme.bgCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Kategoriya',
                    labelStyle: TextStyle(color: AppTheme.textHint),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setModalState(() => category = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Izoh (ixtiyoriy)',
                    labelStyle: TextStyle(color: AppTheme.textHint),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountCtrl.text);
                      if (amount == null || titleCtrl.text.isEmpty) return;
                      ref.read(bookkeepingProvider.notifier).addEntry(
                            title: titleCtrl.text,
                            amount: amount,
                            type: type,
                            category: category,
                            note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Saqlash'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(bookkeepingProvider.notifier);
    final entries = ref.watch(bookkeepingProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildBalanceCard(notifier),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryBlue,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textHint,
                tabs: const [
                  Tab(text: 'Tarix'),
                  Tab(text: 'Grafik'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistory(entries),
                    _buildChart(notifier, entries),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Moliyaviy hisob',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BookkeepingNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A4E), Color(0xFF12123A)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Text(
              'Umumiy balans',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatAmount(notifier.balance)} so\'m',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: notifier.balance >= 0 ? AppTheme.success : AppTheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _BalanceStat(
                    label: 'Daromad',
                    amount: notifier.totalIncome,
                    color: AppTheme.success,
                    icon: Icons.arrow_upward,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.1),
                ),
                Expanded(
                  child: _BalanceStat(
                    label: 'Xarajat',
                    amount: notifier.totalExpense,
                    color: AppTheme.error,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildHistory(List<BookkeepingEntry> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'Hali yozuvlar yo\'q',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final e = entries[i];
        return Dismissible(
          key: Key(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) =>
              ref.read(bookkeepingProvider.notifier).deleteEntry(e.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (e.type == EntryType.income
                            ? AppTheme.success
                            : AppTheme.error)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      e.type == EntryType.income
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: e.type == EntryType.income
                          ? AppTheme.success
                          : AppTheme.error,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${e.category} · ${_formatDate(e.date)}',
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${e.type == EntryType.income ? '+' : '-'}${_formatAmount(e.amount)}',
                  style: TextStyle(
                    color: e.type == EntryType.income
                        ? AppTheme.success
                        : AppTheme.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.1),
        );
      },
    );
  }

  Widget _buildChart(BookkeepingNotifier notifier, List<BookkeepingEntry> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'Grafik uchun yozuv qo\'shing',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: notifier.totalIncome,
                    color: AppTheme.success,
                    title: 'Daromad',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    radius: 80,
                  ),
                  PieChartSectionData(
                    value: notifier.totalExpense,
                    color: AppTheme.error,
                    title: 'Xarajat',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    radius: 80,
                  ),
                ],
                centerSpaceRadius: 30,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final abs = amount.abs();
    if (abs >= 1000000) {
      return '${(abs / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '${(abs / 1000).toStringAsFixed(0)}K';
    }
    return abs.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    final months = [
      'Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyun',
      'Iyul', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          '${amount >= 1000000 ? "${(amount / 1000000).toStringAsFixed(1)}M" : "${(amount / 1000).toStringAsFixed(0)}K"} so\'m',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textHint, fontSize: 11),
        ),
      ],
    );
  }
}
