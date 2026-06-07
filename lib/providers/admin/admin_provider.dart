import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

/// Lightweight models that mirror the backend's admin API responses
/// (see backend/src/routes/admin.js). Kept intentionally close to the raw
/// JSON shape since the admin panel is a thin window onto the server data.

class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final Map<String, int> planCounts;
  final int revenue;
  final List<Map<String, dynamic>> newUsersLast7Days;
  final List<Map<String, dynamic>> usageLast7Days;
  final int openTickets;

  const AdminStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.planCounts = const {},
    this.revenue = 0,
    this.newUsersLast7Days = const [],
    this.usageLast7Days = const [],
    this.openTickets = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final rawPlanCounts = json['planCounts'] as List? ?? [];
    final planCounts = <String, int>{
      for (final row in rawPlanCounts)
        (row['plan'] as String? ?? 'free'): (row['count'] as int? ?? 0),
    };
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      planCounts: planCounts,
      revenue: json['revenue'] ?? 0,
      newUsersLast7Days:
          List<Map<String, dynamic>>.from(json['newUsersLast7Days'] ?? []),
      usageLast7Days:
          List<Map<String, dynamic>>.from(json['usageLast7Days'] ?? []),
      openTickets: json['openTickets'] ?? 0,
    );
  }
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String plan;
  final bool isActive;
  final String? planExpiresAt;
  final String createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.plan,
    required this.isActive,
    this.planExpiresAt,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      plan: json['plan'] ?? 'free',
      isActive: json['isActive'] ?? true,
      planExpiresAt: json['planExpiresAt'] as String?,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class AdminSubscription {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String plan;
  final String status;
  final String provider;
  final int amount;
  final String? expiresAt;
  final String createdAt;

  const AdminSubscription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.plan,
    required this.status,
    required this.provider,
    required this.amount,
    this.expiresAt,
    required this.createdAt,
  });

  factory AdminSubscription.fromJson(Map<String, dynamic> json) {
    return AdminSubscription(
      id: json['id'] as String,
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? json['name'] ?? '',
      userEmail: json['user_email'] ?? json['email'] ?? '',
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'active',
      provider: json['provider'] ?? 'manual',
      amount: json['amount'] ?? 0,
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class AdminTicket {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String message;
  final String status;
  final String createdAt;

  const AdminTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory AdminTicket.fromJson(Map<String, dynamic> json) {
    return AdminTicket(
      id: json['id'] as String,
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? json['name'] ?? '',
      userEmail: json['user_email'] ?? json['email'] ?? '',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class AdminBroadcast {
  final String id;
  final String title;
  final String body;
  final String targetPlan;
  final int sentCount;
  final String createdAt;

  const AdminBroadcast({
    required this.id,
    required this.title,
    required this.body,
    required this.targetPlan,
    required this.sentCount,
    required this.createdAt,
  });

  factory AdminBroadcast.fromJson(Map<String, dynamic> json) {
    return AdminBroadcast(
      id: json['id'] as String,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      targetPlan: json['target_plan'] ?? 'all',
      sentCount: json['sent_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

/// ---- Stats ----

class AdminStatsState {
  final AdminStats? stats;
  final bool isLoading;
  final String? error;

  const AdminStatsState({this.stats, this.isLoading = false, this.error});

  AdminStatsState copyWith({AdminStats? stats, bool? isLoading, String? error}) {
    return AdminStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminStatsNotifier extends StateNotifier<AdminStatsState> {
  final ApiClient _api = ApiClient();

  AdminStatsNotifier() : super(const AdminStatsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.get<Map<String, dynamic>>('/admin/stats');
      state = state.copyWith(
        stats: AdminStats.fromJson(res.data ?? {}),
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }
}

final adminStatsProvider =
    StateNotifierProvider<AdminStatsNotifier, AdminStatsState>((ref) {
  return AdminStatsNotifier();
});

/// ---- Users ----

class AdminUsersState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? error;
  final String search;
  final String? planFilter;
  final int page;
  final int totalPages;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.planFilter,
    this.page = 1,
    this.totalPages = 1,
  });

  AdminUsersState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    String? error,
    String? search,
    String? planFilter,
    bool clearPlanFilter = false,
    int? page,
    int? totalPages,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      search: search ?? this.search,
      planFilter: clearPlanFilter ? null : (planFilter ?? this.planFilter),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final ApiClient _api = ApiClient();

  AdminUsersNotifier() : super(const AdminUsersState()) {
    load();
  }

  Future<void> load({int? page}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.get<Map<String, dynamic>>('/admin/users', query: {
        'page': page ?? state.page,
        if (state.search.isNotEmpty) 'search': state.search,
        if (state.planFilter != null) 'plan': state.planFilter,
      });
      final data = res.data ?? {};
      final users = (data['users'] as List? ?? [])
          .map((u) => AdminUser.fromJson(u as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        users: users,
        isLoading: false,
        page: pagination['page'] ?? state.page,
        totalPages: pagination['totalPages'] ?? 1,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  void setSearch(String value) {
    state = state.copyWith(search: value, page: 1);
    load(page: 1);
  }

  void setPlanFilter(String? plan) {
    state = state.copyWith(planFilter: plan, clearPlanFilter: plan == null, page: 1);
    load(page: 1);
  }

  Future<bool> updateUser(String id, {String? plan, String? role, bool? isActive}) async {
    try {
      await _api.patch('/admin/users/$id', data: {
        if (plan != null) 'plan': plan,
        if (role != null) 'role': role,
        if (isActive != null) 'isActive': isActive,
      });
      await load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _api.delete('/admin/users/$id');
      await load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier();
});

/// ---- Subscriptions ----

class AdminSubscriptionsState {
  final List<AdminSubscription> subscriptions;
  final bool isLoading;
  final String? error;

  const AdminSubscriptionsState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.error,
  });

  AdminSubscriptionsState copyWith({
    List<AdminSubscription>? subscriptions,
    bool? isLoading,
    String? error,
  }) {
    return AdminSubscriptionsState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminSubscriptionsNotifier extends StateNotifier<AdminSubscriptionsState> {
  final ApiClient _api = ApiClient();

  AdminSubscriptionsNotifier() : super(const AdminSubscriptionsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.get<Map<String, dynamic>>('/admin/subscriptions');
      final list = (res.data?['subscriptions'] as List? ?? [])
          .map((s) => AdminSubscription.fromJson(s as Map<String, dynamic>))
          .toList();
      state = state.copyWith(subscriptions: list, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }
}

final adminSubscriptionsProvider =
    StateNotifierProvider<AdminSubscriptionsNotifier, AdminSubscriptionsState>(
        (ref) {
  return AdminSubscriptionsNotifier();
});

/// ---- Support tickets ----

class AdminTicketsState {
  final List<AdminTicket> tickets;
  final bool isLoading;
  final String? error;

  const AdminTicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  AdminTicketsState copyWith({
    List<AdminTicket>? tickets,
    bool? isLoading,
    String? error,
  }) {
    return AdminTicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminTicketsNotifier extends StateNotifier<AdminTicketsState> {
  final ApiClient _api = ApiClient();

  AdminTicketsNotifier() : super(const AdminTicketsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.get<Map<String, dynamic>>('/admin/tickets');
      final list = (res.data?['tickets'] as List? ?? [])
          .map((t) => AdminTicket.fromJson(t as Map<String, dynamic>))
          .toList();
      state = state.copyWith(tickets: list, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _api.patch('/admin/tickets/$id', data: {'status': status});
      await load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }
}

final adminTicketsProvider =
    StateNotifierProvider<AdminTicketsNotifier, AdminTicketsState>((ref) {
  return AdminTicketsNotifier();
});

/// ---- Broadcasts ----

class AdminBroadcastsState {
  final List<AdminBroadcast> broadcasts;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const AdminBroadcastsState({
    this.broadcasts = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  AdminBroadcastsState copyWith({
    List<AdminBroadcast>? broadcasts,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return AdminBroadcastsState(
      broadcasts: broadcasts ?? this.broadcasts,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class AdminBroadcastsNotifier extends StateNotifier<AdminBroadcastsState> {
  final ApiClient _api = ApiClient();

  AdminBroadcastsNotifier() : super(const AdminBroadcastsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.get<Map<String, dynamic>>('/admin/broadcasts');
      final list = (res.data?['broadcasts'] as List? ?? [])
          .map((b) => AdminBroadcast.fromJson(b as Map<String, dynamic>))
          .toList();
      state = state.copyWith(broadcasts: list, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<bool> send({
    required String title,
    required String body,
    String targetPlan = 'all',
  }) async {
    state = state.copyWith(isSending: true, error: null);
    try {
      await _api.post('/admin/broadcasts', data: {
        'title': title,
        'body': body,
        'targetPlan': targetPlan,
      });
      state = state.copyWith(isSending: false);
      await load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
      return false;
    }
  }
}

final adminBroadcastsProvider =
    StateNotifierProvider<AdminBroadcastsNotifier, AdminBroadcastsState>((ref) {
  return AdminBroadcastsNotifier();
});
