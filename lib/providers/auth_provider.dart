import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_model.dart';

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
  AuthNotifier() : super(const UserState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
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
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key);
    state = state.copyWith(apiKey: key);
  }

  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    state = state.copyWith(isOnboarded: true);
  }

  Future<void> upgradePlan(SubscriptionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('subscription_plan', plan.index);
    state = state.copyWith(plan: plan);
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
}

final authProvider = StateNotifierProvider<AuthNotifier, UserState>((ref) {
  return AuthNotifier();
});
