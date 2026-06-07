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
import '../screens/legal_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_subscriptions_screen.dart';
import '../screens/admin/admin_tickets_screen.dart';
import '../screens/admin/admin_broadcasts_screen.dart';

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
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VoiceScreen(autoListen: extra?['autoListen'] == true);
        },
      ),
      GoRoute(
        path: '/subscription',
        builder: (ctx, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/legal/privacy-policy',
        builder: (ctx, state) =>
            const LegalScreen(document: LegalDocument.privacyPolicy),
      ),
      GoRoute(
        path: '/legal/terms-of-use',
        builder: (ctx, state) =>
            const LegalScreen(document: LegalDocument.termsOfUse),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (ctx, state) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (ctx, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (ctx, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (ctx, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/subscriptions',
            builder: (ctx, state) => const AdminSubscriptionsScreen(),
          ),
          GoRoute(
            path: '/admin/tickets',
            builder: (ctx, state) => const AdminTicketsScreen(),
          ),
          GoRoute(
            path: '/admin/broadcasts',
            builder: (ctx, state) => const AdminBroadcastsScreen(),
          ),
        ],
      ),
    ],
  );
});
