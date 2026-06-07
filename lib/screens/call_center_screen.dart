import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/action_executor.dart';
import '../services/ai_service.dart';
import '../widgets/gradient_button.dart';

class CallCenterScreen extends ConsumerStatefulWidget {
  const CallCenterScreen({super.key});

  @override
  ConsumerState<CallCenterScreen> createState() => _CallCenterScreenState();
}

class _CallCenterScreenState extends ConsumerState<CallCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _executor = ActionExecutor();
  final _dialController = TextEditingController();
  final _scriptController = TextEditingController();
  List<Contact> _contacts = [];
  bool _loadingContacts = false;

  final List<CallLog> _callLogs = [
    CallLog(name: 'Ahmadjon', number: '+998901234567', type: CallType.outgoing, time: '10:30'),
    CallLog(name: 'Barno', number: '+998901111222', type: CallType.incoming, time: '09:15'),
    CallLog(name: 'Nozima', number: '+998909876543', type: CallType.missed, time: 'Kecha'),
    CallLog(name: '+998997654321', number: '+998997654321', type: CallType.outgoing, time: 'Kecha'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dialController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final status = await Permission.contacts.request();
    if (status.isDenied) return;

    setState(() => _loadingContacts = true);
    try {
      final contacts = await ContactsService.getContacts(withThumbnails: false);
      setState(() => _contacts = contacts.toList());
    } finally {
      setState(() => _loadingContacts = false);
    }
  }

  void _appendDial(String digit) {
    setState(() => _dialController.text += digit);
  }

  void _deleteDial() {
    final text = _dialController.text;
    if (text.isNotEmpty) {
      setState(() => _dialController.text = text.substring(0, text.length - 1));
    }
  }

  Future<void> _dial() async {
    final number = _dialController.text.trim();
    if (number.isEmpty) return;
    await _executor.execute('MAKE_CALL', {'phone': number});
  }

  Future<void> _generateScript() async {
    final purpose = _scriptController.text.trim();
    if (purpose.isEmpty) return;

    final aiService = AiService();
    final response = await aiService.sendMessage(
      message: '''
Quyidagi uchun professional telefon qo\'ng\'irog\'i skriptini yoz:
$purpose

Salomlashish, asosiy xabar va yakunlashni o\'z ichiga ol.
O\'zbek tilida yoz.
''',
    );

    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.bgCard,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, ctrl) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Qo\'ng\'iroq Skripti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: ctrl,
                    child: Text(
                      response.text,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryBlue,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textHint,
                tabs: const [
                  Tab(text: 'Terish'),
                  Tab(text: 'Kontaktlar'),
                  Tab(text: 'AI Skript'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDialer(),
                    _buildContacts(),
                    _buildAiScript(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text('📞', style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Text(
            'Call Center',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialer() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _dialController.text.isEmpty ? 'Raqam tering' : _dialController.text,
            style: TextStyle(
              fontSize: _dialController.text.isEmpty ? 18 : 28,
              color: _dialController.text.isEmpty
                  ? AppTheme.textHint
                  : Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            childAspectRatio: 1.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              ...[
                ['1', ''], ['2', 'ABC'], ['3', 'DEF'],
                ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
                ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'],
                ['*', ''], ['0', '+'], ['#', ''],
              ].map(
                (d) => GestureDetector(
                  onTap: () => _appendDial(d[0]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          d[0],
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (d[1].isNotEmpty)
                          Text(
                            d[1],
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppTheme.textHint,
                              letterSpacing: 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60),
              GestureDetector(
                onTap: _dial,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.success, Color(0xFF00BFA5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success,
                        blurRadius: 20,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 32),
                ),
              ),
              GestureDetector(
                onTap: _deleteDial,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.backspace_outlined, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContacts() {
    if (_loadingContacts) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Kontaktlar yuklanmadi',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            GradientButton(
              text: 'Ruxsat berish',
              onPressed: _loadContacts,
              width: 180,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _contacts.length,
      itemBuilder: (ctx, i) {
        final contact = _contacts[i];
        final phone = contact.phones?.firstOrNull?.value ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
              child: Text(
                (contact.displayName?.isNotEmpty == true
                        ? contact.displayName![0]
                        : '?')
                    .toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              contact.displayName ?? 'Noma\'lum',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              phone,
              style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _executor.execute('MAKE_CALL', {'phone': phone}),
                  icon: const Icon(Icons.call, color: AppTheme.success, size: 20),
                ),
                IconButton(
                  onPressed: () => _executor.execute('SEND_SMS', {'phone': phone, 'message': ''}),
                  icon: const Icon(Icons.message, color: AppTheme.primaryBlue, size: 20),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 30)).fadeIn();
      },
    );
  }

  Widget _buildAiScript() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI bilan skript yarating',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Qo\'ng\'iroq maqsadini yozing, ADM AI professional skript yaratib beradi',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _scriptController,
            style: const TextStyle(color: Colors.white),
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Masalan: Mijozga mahsulot haqida ma\'lumot berish va buyurtma olish',
              hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            text: 'AI Skript Yaratish',
            onPressed: _generateScript,
            icon: Icons.auto_awesome,
          ),
          const SizedBox(height: 32),
          const Text(
            'Qo\'ng\'iroq tarixi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ..._callLogs.map((log) => _buildCallLogItem(log)),
        ],
      ),
    );
  }

  Widget _buildCallLogItem(CallLog log) {
    final colors = {
      CallType.incoming: AppTheme.success,
      CallType.outgoing: AppTheme.primaryBlue,
      CallType.missed: AppTheme.error,
    };
    final icons = {
      CallType.incoming: Icons.call_received,
      CallType.outgoing: Icons.call_made,
      CallType.missed: Icons.call_missed,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icons[log.type], color: colors[log.type], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  log.number,
                  style: const TextStyle(color: AppTheme.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                log.time,
                style: const TextStyle(color: AppTheme.textHint, fontSize: 11),
              ),
              GestureDetector(
                onTap: () => _executor.execute('MAKE_CALL', {'phone': log.number}),
                child: const Icon(Icons.call, color: AppTheme.success, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum CallType { incoming, outgoing, missed }

class CallLog {
  final String name;
  final String number;
  final CallType type;
  final String time;

  const CallLog({
    required this.name,
    required this.number,
    required this.type,
    required this.time,
  });
}
