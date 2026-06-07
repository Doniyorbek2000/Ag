import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

/// Authenticates against the ADM AI backend (POST /api/auth/login) and
/// only grants admin-panel access when the account's role is 'admin'.
class AdminSession {
  final String id;
  final String name;
  final String email;
  final String role;

  const AdminSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      id: json['id'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
    );
  }
}

class AdminAuthState {
  final AdminSession? session;
  final bool isLoading;
  final bool isRestoring;
  final String? error;

  const AdminAuthState({
    this.session,
    this.isLoading = false,
    this.isRestoring = true,
    this.error,
  });

  bool get isAuthenticated => session != null && session!.role == 'admin';

  AdminAuthState copyWith({
    AdminSession? session,
    bool? isLoading,
    bool? isRestoring,
    String? error,
  }) {
    return AdminAuthState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      isRestoring: isRestoring ?? this.isRestoring,
      error: error,
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final ApiClient _api = ApiClient();

  AdminAuthNotifier() : super(const AdminAuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    if (_api.token == null) {
      state = state.copyWith(isRestoring: false);
      return;
    }
    try {
      final res = await _api.get<Map<String, dynamic>>('/auth/me');
      final session = AdminSession.fromJson(res.data?['user'] ?? {});
      if (session.role == 'admin') {
        state = state.copyWith(session: session, isRestoring: false);
      } else {
        state = state.copyWith(isRestoring: false);
      }
    } catch (_) {
      // Token invalid/expired — stay logged out, login screen will handle it.
      state = state.copyWith(isRestoring: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.post<Map<String, dynamic>>('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data ?? {};
      final session = AdminSession.fromJson(data['user'] ?? {});

      if (session.role != 'admin') {
        await _api.setToken(null);
        state = state.copyWith(
          isLoading: false,
          error: 'Bu hisobda administrator huquqi yo\'q',
        );
        return false;
      }

      await _api.setToken(data['token'] as String?);
      state = state.copyWith(isLoading: false, session: session, error: null);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _api.setToken(null);
    state = const AdminAuthState();
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier();
});
