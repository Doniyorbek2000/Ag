import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/subscription_model.dart';
import '../services/api_client.dart' show ApiClient;
import '../services/crash_reporting_service.dart';
import '../services/analytics_service.dart';
import '../utils/hive_boxes.dart';

class UserState {
  final String? name;
  final String? email;
  final String? apiKey;
  final SubscriptionPlan plan;
  final bool isOnboarded;
  final int dailyCallsUsed;
  final DateTime? lastResetDate;

  const UserState({
    this.name,
    this.email,
    this.apiKey,
    this.plan = SubscriptionPlan.free,
    this.isOnboarded = false,
    this.dailyCallsUsed = 0,
    this.lastResetDate,
  });

  UserState copyWith({
    String? name,
    String? email,
    String? apiKey,
    SubscriptionPlan? plan,
    bool? isOnboarded,
    int? dailyCallsUsed,
    DateTime? lastResetDate,
  }) {
    return UserState(
      name: name ?? this.name,
      email: email ?? this.email,
      apiKey: apiKey ?? this.apiKey,
      plan: plan ?? this.plan,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      dailyCallsUsed: dailyCallsUsed ?? this.dailyCallsUsed,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  bool get canMakeAiCall {
    final planModel = SubscriptionPlanModel.plans
        .firstWhere((p) => p.plan == plan);
    if (planModel.aiCallsPerDay == -1) return true;

    final now = DateTime.now();
    final last = lastResetDate;
    if (last == null ||
        now.day != last.day ||
        now.month != last.month ||
        now.year != last.year) {
      return true;
    }
    return dailyCallsUsed < planModel.aiCallsPerDay;
  }

  int get remainingCalls {
    final planModel = SubscriptionPlanModel.plans
        .firstWhere((p) => p.plan == plan);
    if (planModel.aiCallsPerDay == -1) return -1;

    final now = DateTime.now();
    final last = lastResetDate;
    if (last == null ||
        now.day != last.day ||
        now.month != last.month ||
        now.year != last.year) {
      return planModel.aiCallsPerDay;
    }
    return (planModel.aiCallsPerDay - dailyCallsUsed).clamp(0, planModel.aiCallsPerDay);
  }
}

class AuthNotifier extends StateNotifier<UserState> {
  static const _anonIdKey = 'anon_user_id';
  static const _uuid = Uuid();

  AuthNotifier() : super(const UserState()) {
    _loadFromStorage();
  }

  /// Stable, anonymous per-install identifier used purely to correlate crash
  /// reports across sessions -- never tied to name/email (no PII).
  Future<String> _ensureAnonId(SharedPreferences prefs) async {
    final existing = prefs.getString(_anonIdKey);
    if (existing != null) return existing;
    final generated = _uuid.v4();
    await prefs.setString(_anonIdKey, generated);
    return generated;
  }

  /// The app has no visible login/registration screen -- a backend account is
  /// provisioned transparently, keyed off the anonymous per-install id, so
  /// that account-bound features (subscriptions, Click/Payme checkout, usage
  /// tracking, support tickets) work without asking the user for credentials.
  /// Derived deterministically from [anonId] so re-provisioning after a
  /// reinstall (same id is not regenerated once persisted) always resolves to
  /// the same backend account via login-or-register.
  String _deviceAccountEmail(String anonId) => '$anonId@device.adm-ai.local';
  String _deviceAccountPassword(String anonId) => 'adm-device-$anonId';

  /// Posts to an auth endpoint and extracts the returned token, or returns
  /// null on any failure (wrong/missing credentials, backend unreachable).
  Future<String?> _tryAuth(ApiClient api, String path, Map<String, dynamic> data) async {
    try {
      final res = await api.post<Map<String, dynamic>>(path, data: data);
      return res.data?['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureBackendAccount(SharedPreferences prefs, String anonId) async {
    if (prefs.getString('backend_token') != null) return;

    final api = ApiClient();
    final email = _deviceAccountEmail(anonId);
    final password = _deviceAccountPassword(anonId);
    final credentials = {'email': email, 'password': password};

    final token = await _tryAuth(api, '/auth/login', credentials) ??
        await _tryAuth(api, '/auth/register', {'name': 'ADM AI', ...credentials});

    // If both fail (e.g. backend unreachable), the app keeps working offline.
    if (token != null) await api.setToken(token);
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final anonId = await _ensureAnonId(prefs);
    CrashReportingService.setUserId(anonId);
    _ensureBackendAccount(prefs, anonId);

    state = state.copyWith(
      name: prefs.getString('user_name'),
      email: prefs.getString('user_email'),
      apiKey: prefs.getString('api_key'),
      plan: SubscriptionPlan.values[prefs.getInt('subscription_plan') ?? 0],
      isOnboarded: prefs.getBool('is_onboarded') ?? false,
      dailyCallsUsed: prefs.getInt('daily_calls_used') ?? 0,
    );
  }

  Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    state = state.copyWith(name: name);
    AnalyticsService().track('profile_name_set');
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key);
    state = state.copyWith(apiKey: key);
    AnalyticsService().track('api_key_set');
  }

  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    state = state.copyWith(isOnboarded: true);
    AnalyticsService().track('onboarding_completed');
  }

  Future<void> upgradePlan(SubscriptionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('subscription_plan', plan.index);
    state = state.copyWith(plan: plan);
    AnalyticsService().track('plan_upgraded', {'plan': plan.name});
  }

  Future<void> incrementDailyCall() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final last = state.lastResetDate;

    int newCount = state.dailyCallsUsed;
    if (last == null ||
        now.day != last.day ||
        now.month != last.month ||
        now.year != last.year) {
      newCount = 1;
    } else {
      newCount++;
    }

    await prefs.setInt('daily_calls_used', newCount);
    state = state.copyWith(dailyCallsUsed: newCount, lastResetDate: now);
  }

  /// Permanently deletes the device's backend account (subscriptions,
  /// payments, usage history) and wipes all local app data, returning the
  /// app to a fresh-install state. Returns false (without touching local
  /// data) if a backend account exists but the deletion request fails --
  /// e.g. no network -- so the user can retry instead of losing server-side
  /// history while believing it's gone.
  Future<bool> deleteAccount() async {
    AnalyticsService().track('account_deleted');
    final api = ApiClient();
    if (api.token != null) {
      try {
        await api.delete('/users/me');
      } catch (_) {
        return false;
      }
      await api.setToken(null);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    for (final boxName in allHiveBoxNames) {
      if (Hive.isBoxOpen(boxName)) await Hive.box(boxName).clear();
    }

    await _loadFromStorage();
    return true;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserState>((ref) {
  return AuthNotifier();
});
