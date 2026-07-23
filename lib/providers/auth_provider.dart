/// Token 存储实例
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/models/user.dart';
import 'package:telemarketing_app/services/api_client.dart';
import 'package:telemarketing_app/services/api_exception.dart';
import 'package:telemarketing_app/services/auth_service.dart';
import 'package:telemarketing_app/services/token_storage.dart';
import 'package:telemarketing_app/services/local_storage_service.dart';
import 'package:telemarketing_app/services/tenant_service.dart';

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

/// 租户信息服务实例
final tenantServiceProvider = Provider<TenantService>((ref) {
  return TenantService(apiClient: ref.read(apiClientProvider));
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
  /// 需强制改密
  forceChangePassword,
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

      if (result.mustResetPassword) {
        // 管理员重置了密码，跳转强制改密页
        state = AuthState(
          status: AuthStatus.forceChangePassword,
          user: result.user,
        );
      } else {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.user,
        );
      }
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

  /// 强制改密
  Future<bool> forceChangePassword({
    required String newPassword,
  }) async {
    state = state.copyWith(errorMessage: null);

    try {
      final authService = _ref.read(authServiceProvider);
      await authService.forceChangePassword(newPassword: newPassword);
      // 改密成功 → 清空 Token → 跳转登录页
      final tokenStorage = _ref.read(tokenStorageProvider);
      await tokenStorage.clearAll();
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: '密码修改成功，请重新登录',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: '修改失败，请稍后再试',
      );
      return false;
    }
  }

  /// 退出强制改密（用户点击返回确认后）
  Future<void> cancelForceChangePassword() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    await tokenStorage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 网络层 423 兜底触发：强制跳转改密页
  void forceRedirect() {
    state = AuthState(
      status: AuthStatus.forceChangePassword,
      errorMessage: '密码已被管理员重置，请设置新密码',
    );
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
  // 设置 423 兜底回调：ApiClient 捕获 FORCE_CHANGE_PASSWORD 后触发跳转
  final apiClient = ref.read(apiClientProvider);
  final notifier = AuthNotifier(ref);
  apiClient.onForceChangePassword = () => notifier.forceRedirect();
  return notifier;
});
