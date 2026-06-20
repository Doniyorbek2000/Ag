import '../services/analytics_service.dart';
import '../services/memory_service.dart';
import '../services/reminder_service.dart';

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
];
