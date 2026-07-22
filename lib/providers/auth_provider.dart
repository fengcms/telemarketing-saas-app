import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../services/local_storage_service.dart';

// ── Service Providers ──

/// Token 存储实例
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// 本地凭据存储（邮箱/密码）
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// API 客户端实例
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.read(tokenStorageProvider));
});

/// 认证服务实例
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    apiClient: ref.read(apiClientProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

// ── Auth State ──

/// 认证状态
enum AuthStatus {
  /// 初始态（正在检查本地 Token）
  initial,
  /// 未登录
  unauthenticated,
  /// 登录中
  authenticating,
  /// 已登录
  authenticated,
}

/// 认证状态数据
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// 认证状态管理
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _tryAutoLogin();
  }

  /// 启动时自动检查本地 Token
  Future<void> _tryAutoLogin() async {
    final authService = _ref.read(authServiceProvider);
    final user = await authService.tryAutoLogin();
    if (user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// 登录
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      errorMessage: null,
    );

    try {
      final authService = _ref.read(authServiceProvider);
      final result = await authService.login(email: email, password: password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: '登录失败，请稍后再试',
      );
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    final authService = _ref.read(authServiceProvider);
    await authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// 认证状态 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
