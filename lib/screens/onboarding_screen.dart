import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/gradient_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _agreedToTerms = false;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      icon: '🤖',
      title: 'ADM AI ga xush kelibsiz',
      subtitle: 'Siri va Google Assistantdan ham kuchli\nshaxsiy AI yordamchingiz',
      gradient: [Color(0xFF2979FF), Color(0xFF7C4DFF)],
    ),
    const OnboardingPage(
      icon: '🎙️',
      title: 'Ovozli boshqarish',
      subtitle: 'Telefoningizni faqat ovozingiz bilan\nboshqaring — qo\'ng\'iroq, musiqa, ilova',
      gradient: [Color(0xFF00E5FF), Color(0xFF2979FF)],
    ),
    const OnboardingPage(
      icon: '📱',
      title: 'Barcha ilovalar',
      subtitle: 'Telegram, WhatsApp, YouTube, Instagram\nva boshqa barcha ilovalarni boshqaring',
      gradient: [Color(0xFF7C4DFF), Color(0xFFE91E63)],
    ),
    const OnboardingPage(
      icon: '💼',
      title: 'Biznes va buxgalteriya',
      subtitle: 'Xarajat va daromadlaringizni kuzating,\nhisobotlar oling, Call Center boshqaring',
      gradient: [Color(0xFF00E676), Color(0xFF00BCD4)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.phone,
      Permission.contacts,
      Permission.notification,
      Permission.storage,
    ].request();
  }

  Future<void> _complete() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Davom etish uchun Foydalanish shartlari va Maxfiylik '
            'siyosatiga rozilik bildiring',
          ),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await ref.read(authProvider.notifier).setName(name);
    }
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      await ref.read(authProvider.notifier).setApiKey(apiKey);
    }
    await ref.read(authProvider.notifier).setOnboarded();
    await _requestPermissions();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    ..._pages.map(_buildPage),
                    _buildSetupPage(),
                  ],
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final total = _pages.length + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
              decoration: BoxDecoration(
                color: i <= _currentPage
                    ? AppTheme.primaryBlue
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: page.gradient),
              boxShadow: [
                BoxShadow(
                  color: page.gradient.first.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                page.icon,
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(
              begin: const Offset(0.7, 0.7),
              duration: 600.ms,
              curve: Curves.elasticOut),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Center(
              child: Text('⚙️', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Sozlash',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ADM AI ni shaxsiylashtiring',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Ismingiz',
              labelStyle: const TextStyle(color: AppTheme.textHint),
              hintText: 'Masalan: Doniyorbek',
              hintStyle: const TextStyle(color: AppTheme.textHint),
              prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textHint),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Claude API kalit (ixtiyoriy)',
              labelStyle: const TextStyle(color: AppTheme.textHint),
              hintText: 'sk-ant-...',
              hintStyle: const TextStyle(color: AppTheme.textHint),
              prefixIcon: const Icon(Icons.key_outlined, color: AppTheme.textHint),
              helperText: 'anthropic.com dan oling — bepul boshlang',
              helperStyle: const TextStyle(color: AppTheme.textHint, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'API kalit bo\'lmasa ham bepul rejimda ishlash mumkin',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          children: [
                            const TextSpan(text: 'Men '),
                            TextSpan(
                              text: 'Foydalanish shartlari',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => context.push('/legal/terms-of-use'),
                            ),
                            const TextSpan(text: ' va '),
                            TextSpan(
                              text: 'Maxfiylik siyosati',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => context.push('/legal/privacy-policy'),
                            ),
                            const TextSpan(text: ' bilan tanishdim va roziman.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Boshlash',
            onPressed: _complete,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLast = _currentPage == _pages.length;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text(
                'Orqaga',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            const SizedBox(width: 80),
          if (!isLast)
            GradientButton(
              text: 'Keyingi',
              width: 130,
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          if (!isLast)
            TextButton(
              onPressed: _complete,
              child: const Text(
                'O\'tkazib yuborish',
                style: TextStyle(color: AppTheme.textHint, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
