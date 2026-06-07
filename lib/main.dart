import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'services/background_service.dart';
import 'providers/auth_provider.dart';
import 'models/chat_message.dart';
import 'models/bookkeeping_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await _initHiveAdapters();

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
}

Future<void> _initHiveAdapters() async {
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(MessageTypeAdapter());
  Hive.registerAdapter(BookkeepingEntryAdapter());
  Hive.registerAdapter(EntryTypeAdapter());

  await Hive.openBox('settings');
  await Hive.openBox('chats');
  await Hive.openBox('bookkeeping');
  await Hive.openBox('contacts_cache');
}

class AdmAiApp extends ConsumerWidget {
  const AdmAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ADM AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
