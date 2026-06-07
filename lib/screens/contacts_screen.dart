import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../services/action_executor.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _executor = ActionExecutor();
  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final status = await Permission.contacts.request();
    if (status.isDenied) {
      setState(() => _loading = false);
      return;
    }
    final contacts = await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      _contacts = contacts.toList()
        ..sort((a, b) =>
            (a.displayName ?? '').compareTo(b.displayName ?? ''));
      _filtered = _contacts;
      _loading = false;
    });
  }

  void _filter(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _contacts
          : _contacts
              .where((c) =>
                  (c.displayName ?? '').toLowerCase().contains(q.toLowerCase()) ||
                  (c.phones?.any((p) => p.value?.contains(q) == true) ?? false))
              .toList();
    });
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
              _buildSearch(),
              _loading
                  ? const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                      ),
                    )
                  : _contacts.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Text(
            'Kontaktlar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            '${_contacts.length} ta',
            style: const TextStyle(color: AppTheme.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filter,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Ism yoki raqam qidirish...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    _filter('');
                  },
                  child: const Icon(Icons.clear, color: AppTheme.textHint),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Kontaktlarga kirish ruxsati berilmagan',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContacts,
              child: const Text('Ruxsat berish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _filtered.length,
        itemBuilder: (ctx, i) {
          final contact = _filtered[i];
          final name = contact.displayName ?? 'Noma\'lum';
          final phone = contact.phones?.firstOrNull?.value ?? '';
          final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

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
                  initials,
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                phone,
                style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (phone.isNotEmpty)
                    GestureDetector(
                      onTap: () => _executor.execute('MAKE_CALL', {'phone': phone}),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call,
                          color: AppTheme.success,
                          size: 18,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  if (phone.isNotEmpty)
                    GestureDetector(
                      onTap: () => _executor.execute('SEND_SMS', {'phone': phone, 'message': ''}),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.message,
                          color: AppTheme.primaryBlue,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: (i % 20) * 30)).fadeIn().slideX(begin: 0.05);
        },
      ),
    );
  }
}
