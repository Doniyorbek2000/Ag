import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/action_executor.dart';
import '../services/analytics_service.dart';

class AppsHubScreen extends StatefulWidget {
  const AppsHubScreen({super.key});

  @override
  State<AppsHubScreen> createState() => _AppsHubScreenState();
}

class _AppsHubScreenState extends State<AppsHubScreen> {
  final _executor = ActionExecutor();
  final _searchController = TextEditingController();
  String _search = '';

  final List<AppCategory> _categories = [
    AppCategory(
      name: 'Ijtimoiy tarmoqlar',
      icon: '💬',
      apps: [
        AppEntry(icon: '📨', name: 'Telegram', package: 'telegram', color: Color(0xFF0088CC)),
        AppEntry(icon: '💬', name: 'WhatsApp', package: 'whatsapp', color: Color(0xFF25D366)),
        AppEntry(icon: '📸', name: 'Instagram', package: 'instagram', color: Color(0xFFE1306C)),
        AppEntry(icon: '📘', name: 'Facebook', package: 'facebook', color: Color(0xFF1877F2)),
        AppEntry(icon: '🐦', name: 'Twitter', package: 'twitter', color: Color(0xFF1DA1F2)),
        AppEntry(icon: '🎵', name: 'TikTok', package: 'tiktok', color: Color(0xFF010101)),
      ],
    ),
    AppCategory(
      name: 'Multimedia',
      icon: '🎬',
      apps: [
        AppEntry(icon: '▶️', name: 'YouTube', package: 'youtube', color: Color(0xFFFF0000)),
        AppEntry(icon: '🎵', name: 'Spotify', package: 'spotify', color: Color(0xFF1DB954)),
        AppEntry(icon: '🎬', name: 'Netflix', package: 'netflix', color: Color(0xFFE50914)),
        AppEntry(icon: '📻', name: 'Radio', package: 'radio', color: Color(0xFFFF6B35)),
      ],
    ),
    AppCategory(
      name: 'Google xizmatlari',
      icon: '🔍',
      apps: [
        AppEntry(icon: '🗺️', name: 'Maps', package: 'maps', color: Color(0xFF4285F4)),
        AppEntry(icon: '📧', name: 'Gmail', package: 'gmail', color: Color(0xFFEA4335)),
        AppEntry(icon: '📅', name: 'Calendar', package: 'calendar', color: Color(0xFF4285F4)),
        AppEntry(icon: '🌐', name: 'Chrome', package: 'chrome', color: Color(0xFF4285F4)),
        AppEntry(icon: '💾', name: 'Drive', package: 'drive', color: Color(0xFF0F9D58)),
        AppEntry(icon: '📸', name: 'Photos', package: 'photos', color: Color(0xFF4285F4)),
      ],
    ),
    AppCategory(
      name: 'Samaradorlik',
      icon: '🛠️',
      apps: [
        AppEntry(icon: '📅', name: 'Kalendar', package: 'calendar', color: Color(0xFF4285F4)),
        AppEntry(icon: '⏰', name: 'Soat', package: 'clock', color: Color(0xFF607D8B)),
        AppEntry(icon: '📝', name: 'Eslatmalar', package: 'notes', color: Color(0xFFFFC107)),
        AppEntry(icon: '📁', name: 'Fayllar', package: 'files', color: Color(0xFF795548)),
        AppEntry(icon: '🔐', name: 'Parollar', package: 'passwords', color: Color(0xFF9C27B0)),
        AppEntry(icon: '📊', name: 'Jadvallar', package: 'sheets', color: Color(0xFF0F9D58)),
      ],
    ),
    AppCategory(
      name: 'Telefon',
      icon: '📱',
      apps: [
        AppEntry(icon: '📞', name: 'Telefon', package: 'dialer', color: Color(0xFF00E676)),
        AppEntry(icon: '💬', name: 'SMS', package: 'sms', color: Color(0xFF2979FF)),
        AppEntry(icon: '📷', name: 'Kamera', package: 'camera', color: Color(0xFF7C4DFF)),
        AppEntry(icon: '🖼️', name: 'Galereya', package: 'gallery', color: Color(0xFFFF6D00)),
        AppEntry(icon: '🧮', name: 'Kalkulyator', package: 'calculator', color: Color(0xFF757575)),
        AppEntry(icon: '⚙️', name: 'Sozlamalar', package: 'settings', color: Color(0xFF546E7A)),
      ],
    ),
    AppCategory(
      name: 'Video qo\'ng\'iroq',
      icon: '📹',
      apps: [
        AppEntry(icon: '🎥', name: 'Zoom', package: 'zoom', color: Color(0xFF2D8CFF)),
        AppEntry(icon: '📹', name: 'Teams', package: 'teams', color: Color(0xFF6264A7)),
        AppEntry(icon: '🎙️', name: 'Meet', package: 'meet', color: Color(0xFF00897B)),
        AppEntry(icon: '📞', name: 'Skype', package: 'skype', color: Color(0xFF00AFF0)),
      ],
    ),
  ];

  List<AppCategory> get _filtered {
    if (_search.isEmpty) return _categories;
    final q = _search.toLowerCase();
    return _categories
        .map((cat) => AppCategory(
              name: cat.name,
              icon: cat.icon,
              apps: cat.apps.where((a) => a.name.toLowerCase().contains(q)).toList(),
            ))
        .where((cat) => cat.apps.isNotEmpty)
        .toList();
  }

  Future<void> _openApp(AppEntry app) async {
    AnalyticsService().track('app_launched', {'app': app.package});
    await _executor.execute('OPEN_APP', {'app': app.package});
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
              _buildSearchBar(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) => _buildCategory(_filtered[i], i),
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Ilovalar markazi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Ilova qidirish...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
          suffixIcon: _search.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                  child: const Icon(Icons.clear, color: AppTheme.textHint),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategory(AppCategory category, int index) {
    if (category.apps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: category.apps.length,
            itemBuilder: (ctx, i) {
              final app = category.apps[i];
              return GestureDetector(
                onTap: () => _openApp(app),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: app.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: app.color.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          app.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: index * 50 + i * 30)).fadeIn().scale(
                  begin: const Offset(0.8, 0.8), duration: 300.ms);
            },
          ),
        ],
      ),
    );
  }
}

class AppCategory {
  final String name;
  final String icon;
  final List<AppEntry> apps;

  AppCategory({required this.name, required this.icon, required this.apps});
}

class AppEntry {
  final String icon;
  final String name;
  final String package;
  final Color color;

  const AppEntry({
    required this.icon,
    required this.name,
    required this.package,
    required this.color,
  });
}
