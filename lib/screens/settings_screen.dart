import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wake_word_provider.dart';
import '../services/ai_service.dart';
import '../services/telegram_service.dart';
import '../services/whatsapp_service.dart';
import '../services/weather_service.dart';
import '../services/news_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider);
    _apiKeyController.text = user.apiKey ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildProfileSection(user)),
              SliverToBoxAdapter(child: _buildApiSection()),
              const SliverToBoxAdapter(child: _IntegrationsSection()),
              SliverToBoxAdapter(child: _buildSubscriptionSection(context, user)),
              SliverToBoxAdapter(child: _buildPreferencesSection()),
              SliverToBoxAdapter(child: _buildAboutSection(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        'Sozlamalar',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileSection(UserState user) {
    return _SettingsSection(
      title: 'Profil',
      children: [
        _SettingsTile(
          icon: Icons.person_outline,
          title: 'Ism',
          subtitle: user.name ?? 'Belgilanmagan',
          onTap: () => _editName(user.name),
        ),
      ],
    );
  }

  Widget _buildApiSection() {
    return _SettingsSection(
      title: 'AI Sozlamalar',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.key_outlined, color: AppTheme.textHint, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Claude API kaliti',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: !_showApiKey,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'sk-ant-...',
                  hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 13),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _showApiKey = !_showApiKey),
                        icon: Icon(
                          _showApiKey ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textHint,
                          size: 18,
                        ),
                      ),
                      IconButton(
                        onPressed: _saveApiKey,
                        icon: const Icon(
                          Icons.check,
                          color: AppTheme.success,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'API kalitini anthropic.com dan oling →',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection(BuildContext context, UserState user) {
    return _SettingsSection(
      title: 'Obuna',
      children: [
        _SettingsTile(
          icon: Icons.star_outline,
          title: 'Tarif reja',
          subtitle: _getPlanName(user.plan),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textHint),
          onTap: () => context.push('/subscription'),
        ),
        _SettingsTile(
          icon: Icons.analytics_outlined,
          title: 'Kunlik so\'rovlar',
          subtitle: user.remainingCalls == -1
              ? 'Cheksiz'
              : '${user.remainingCalls} ta qoldi',
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    final wakeWord = ref.watch(wakeWordProvider);

    return _SettingsSection(
      title: 'Sozlamalar',
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          secondary: const Icon(Icons.mic_none_outlined, color: AppTheme.textHint, size: 20),
          title: const Text('"Hey ADM AI" uyg\'otish so\'zi',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: Text(
            wakeWord.enabled
                ? 'Yoqilgan — fonda tinglanmoqda'
                : 'O\'chirilgan — mikrofon tugmasini bosing',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          value: wakeWord.enabled,
          activeColor: AppTheme.success,
          onChanged: (_) => ref.read(wakeWordProvider.notifier).toggle(),
        ),
        if (wakeWord.enabled && !wakeWord.batteryExempted)
          _SettingsTile(
            icon: Icons.battery_alert_outlined,
            title: 'Batareya tejashni o\'chiring',
            subtitle: 'Aks holda "Hey ADM AI" ekran o\'chganda to\'xtab qolishi mumkin',
            onTap: () => ref.read(wakeWordProvider.notifier).requestBatteryExemption(),
          ),
        _SettingsTile(
          icon: Icons.language_outlined,
          title: 'Til',
          subtitle: 'O\'zbekcha',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.record_voice_over_outlined,
          title: 'Ovoz tili',
          subtitle: 'uz-UZ',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Bildirishnomalar',
          subtitle: 'Yoqilgan',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.security_outlined,
          title: 'Xavfsizlik',
          subtitle: 'Barmoq izi / Yuz ID',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _SettingsSection(
      title: 'Ilova haqida',
      children: [
        _SettingsTile(
          icon: Icons.info_outline,
          title: 'Versiya',
          subtitle: '1.0.0',
        ),
        _SettingsTile(
          icon: Icons.description_outlined,
          title: 'Foydalanish shartlari',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Maxfiylik siyosati',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.bug_report_outlined,
          title: 'Xato haqida xabar berish',
          onTap: () {},
        ),
        _SettingsTile(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Admin panel',
          subtitle: 'Boshqaruv paneliga kirish',
          onTap: () => context.push('/admin/login'),
        ),
      ],
    );
  }

  Future<void> _editName(String? currentName) async {
    final ctrl = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Ismni o\'zgartirish',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ismingiz',
            hintStyle: TextStyle(color: AppTheme.textHint),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).setName(ctrl.text.trim());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Saqlash',
                style: TextStyle(color: AppTheme.primaryBlue)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    await ref.read(authProvider.notifier).setApiKey(key);
    AiService().setApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API kalit saqlandi'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  String _getPlanName(plan) {
    return switch (plan.toString()) {
      'SubscriptionPlan.free' => 'Bepul',
      'SubscriptionPlan.pro' => 'Pro',
      'SubscriptionPlan.ultra' => 'Ultra',
      'SubscriptionPlan.vip' => 'VIP',
      _ => 'Bepul',
    };
  }
}

/// Lets the user paste their own API credentials for direct messaging
/// (Telegram Bot API, WhatsApp Cloud API) and real-time data (weather,
/// news). These can't use a shared/bundled key — each provider requires
/// the account owner's own credentials, so this is the only honest way
/// to enable the "real data" / "direct messaging" features end to end.
class _IntegrationsSection extends StatefulWidget {
  const _IntegrationsSection();

  @override
  State<_IntegrationsSection> createState() => _IntegrationsSectionState();
}

class _IntegrationsSectionState extends State<_IntegrationsSection> {
  final _telegramController = TextEditingController();
  final _whatsappPhoneIdController = TextEditingController();
  final _whatsappTokenController = TextEditingController();
  final _weatherKeyController = TextEditingController();
  final _newsKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final telegramToken = await TelegramService().token;
    final weatherKey = await WeatherService().apiKey;
    final newsKey = await NewsService().apiKey;
    if (!mounted) return;
    setState(() {
      _telegramController.text = telegramToken ?? '';
      _weatherKeyController.text = weatherKey ?? '';
      _newsKeyController.text = newsKey ?? '';
    });
  }

  @override
  void dispose() {
    _telegramController.dispose();
    _whatsappPhoneIdController.dispose();
    _whatsappTokenController.dispose();
    _weatherKeyController.dispose();
    _newsKeyController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'Integratsiyalar',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To\'g\'ridan-to\'g\'ri xabar yuborish va real ma\'lumotlar uchun '
                'o\'z hisob ma\'lumotlaringizni kiriting — bular hech qayerga '
                'yuborilmaydi, faqat shu qurilmada saqlanadi.',
                style: TextStyle(color: AppTheme.textHint, fontSize: 11.5, height: 1.4),
              ),
              const SizedBox(height: 18),
              _IntegrationField(
                label: 'Telegram bot tokeni',
                hint: '123456:ABC-DEF...',
                helpText: '@BotFather orqali bot yarating va tokenni shu yerga qo\'ying',
                controller: _telegramController,
                obscure: true,
                onSave: () async {
                  await TelegramService().setToken(_telegramController.text.trim());
                  _toast('Telegram boti sozlandi');
                },
              ),
              const SizedBox(height: 16),
              _IntegrationField(
                label: 'WhatsApp Business — Phone Number ID',
                hint: 'Meta Developer konsolidan',
                controller: _whatsappPhoneIdController,
                onSave: () async {
                  await WhatsAppService().setCredentials(
                    phoneNumberId: _whatsappPhoneIdController.text.trim(),
                    accessToken: _whatsappTokenController.text.trim(),
                  );
                  _toast('WhatsApp Business hisobi sozlandi');
                },
              ),
              const SizedBox(height: 10),
              _IntegrationField(
                label: 'WhatsApp Business — Access Token',
                hint: 'EAAxxxxxx...',
                helpText:
                    'developers.facebook.com da WhatsApp Cloud API ilovasi yarating',
                controller: _whatsappTokenController,
                obscure: true,
                onSave: () async {
                  await WhatsAppService().setCredentials(
                    phoneNumberId: _whatsappPhoneIdController.text.trim(),
                    accessToken: _whatsappTokenController.text.trim(),
                  );
                  _toast('WhatsApp Business hisobi sozlandi');
                },
              ),
              const SizedBox(height: 16),
              _IntegrationField(
                label: 'OpenWeatherMap API kaliti',
                hint: 'Ob-havo ma\'lumotlari uchun',
                helpText: 'openweathermap.org da bepul ro\'yxatdan o\'ting',
                controller: _weatherKeyController,
                obscure: true,
                onSave: () async {
                  await WeatherService().setApiKey(_weatherKeyController.text.trim());
                  _toast('Ob-havo xizmati sozlandi');
                },
              ),
              const SizedBox(height: 10),
              _IntegrationField(
                label: 'GNews API kaliti',
                hint: 'Yangiliklar uchun',
                helpText: 'gnews.io da bepul ro\'yxatdan o\'ting',
                controller: _newsKeyController,
                obscure: true,
                onSave: () async {
                  await NewsService().setApiKey(_newsKeyController.text.trim());
                  _toast('Yangiliklar xizmati sozlandi');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IntegrationField extends StatefulWidget {
  final String label;
  final String hint;
  final String? helpText;
  final TextEditingController controller;
  final bool obscure;
  final Future<void> Function() onSave;

  const _IntegrationField({
    required this.label,
    required this.hint,
    this.helpText,
    required this.controller,
    this.obscure = false,
    required this.onSave,
  });

  @override
  State<_IntegrationField> createState() => _IntegrationFieldState();
}

class _IntegrationFieldState extends State<_IntegrationField> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: widget.obscure && !_show,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 12),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.obscure)
                  IconButton(
                    onPressed: () => setState(() => _show = !_show),
                    icon: Icon(
                      _show ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textHint,
                      size: 18,
                    ),
                  ),
                IconButton(
                  onPressed: widget.onSave,
                  icon: const Icon(Icons.check, color: AppTheme.success, size: 18),
                ),
              ],
            ),
          ),
        ),
        if (widget.helpText != null) ...[
          const SizedBox(height: 4),
          Text(widget.helpText!, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
        ],
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: children.asMap().entries.map((e) {
                final isLast = e.key == children.length - 1;
                return Column(
                  children: [
                    e.value,
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: Colors.white.withOpacity(0.06),
                        indent: 52,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textHint, size: 20),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 18)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
