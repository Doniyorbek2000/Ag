import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/background_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/analytics_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'models/chat_message.dart';
import 'models/bookkeeping_entry.dart';
import 'utils/hive_boxes.dart';
import 'services/reminder_service.dart';

void main() async {
  await CrashReportingService.init(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Hive.initFlutter();
    await _initHiveAdapters();
    await AnalyticsService().ensureInitialized();
    await _initNotifications();
    ReminderService().rescheduleAll();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0A1A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    await AdmBackgroundService.initialize();

    runApp(const ProviderScope(child: AdmAiApp()));
  });
}

Future<void> _initNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);
  await plugin.initialize(settings);
}

Future<void> _initHiveAdapters() async {
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(MessageTypeAdapter());
  Hive.registerAdapter(BookkeepingEntryAdapter());
  Hive.registerAdapter(EntryTypeAdapter());

  for (final boxName in allHiveBoxNames) {
    await Hive.openBox(boxName);
  }
}

class AdmAiApp extends ConsumerWidget {
  const AdmAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ADM AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
