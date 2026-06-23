import '../services/analytics_service.dart';
import '../services/book_tracker_service.dart';
import '../services/brain_game_service.dart';
import '../services/favorites_service.dart';
import '../services/habit_service.dart';
import '../services/health_tracker_service.dart';
import '../services/journal_service.dart';
import '../services/memory_service.dart';
import '../services/password_vault_service.dart';
import '../services/reminder_service.dart';
import '../services/scheduled_service.dart';
import '../services/usage_stats_service.dart';

/// Every Hive box the app opens at startup ([main.dart]) and wipes on
/// account deletion ([AuthNotifier.deleteAccount]) -- kept in one place so
/// the two lists can't drift apart when a new box is added.
const allHiveBoxNames = [
  'settings',
  'chats',
  'bookkeeping',
  'contacts_cache',
  MemoryService.boxName,
  AnalyticsService.boxName,
  ReminderService.boxName,
  'notes',
  'todos',
  'shopping',
  'goals',
  HealthTrackerService.boxName,
  'budget',
  HabitService.boxName,
  ScheduledService.boxName,
  JournalService.boxName,
  PasswordVaultService.boxName,
  BookTrackerService.boxName,
  BrainGameService.boxName,
  FavoritesService.boxName,
  UsageStatsService.boxName,
];
