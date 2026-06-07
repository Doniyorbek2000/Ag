import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/main_shell.dart';
import '../screens/home_screen.dart';
import '../screens/voice_screen.dart';
import '../screens/apps_hub_screen.dart';
import '../screens/contacts_screen.dart';
import '../screens/bookkeeping_screen.dart';
import '../screens/call_center_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (ctx, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (ctx, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (ctx, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/apps',
            builder: (ctx, state) => const AppsHubScreen(),
          ),
          GoRoute(
            path: '/contacts',
            builder: (ctx, state) => const ContactsScreen(),
          ),
          GoRoute(
            path: '/bookkeeping',
            builder: (ctx, state) => const BookkeepingScreen(),
          ),
          GoRoute(
            path: '/call-center',
            builder: (ctx, state) => const CallCenterScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (ctx, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (ctx, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/voice',
        builder: (ctx, state) => const VoiceScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (ctx, state) => const SubscriptionScreen(),
      ),
    ],
  );
});
