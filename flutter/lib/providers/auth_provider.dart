import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/secure_storage_helper.dart';

// ─── Auth State ────────────────────────────────────────────────────────────
enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) =>
    AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );

  bool get isAdmin => user?.isAdmin ?? false;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ─── Auth Notifier ─────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final user = await SecureStorageHelper.getUser();
    final token = await SecureStorageHelper.getAccessToken();
    if (user != null && token != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
      // Silently refresh user data
      try {
        final freshUser = await _api.getMe();
        await SecureStorageHelper.saveUser(freshUser);
        state = state.copyWith(user: freshUser);
      } catch (_) {}
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final response = await _api.login(email, password);
      if (response['success'] == true) {
        final data = response['data'];
        await SecureStorageHelper.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        final user = UserModel.fromJson(data['user']);
        await SecureStorageHelper.saveUser(user);
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: response['message'] ?? 'Login failed',
      );
      return false;
    } catch (e) {
      String message = 'Network error. Please try again.';
      state = AuthState(status: AuthStatus.unauthenticated, error: message);
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await SecureStorageHelper.getRefreshToken();
    try { await _api.logout(refreshToken); } catch (_) {}
    await SecureStorageHelper.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────
final apiServiceProvider = Provider((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiServiceProvider)),
);
