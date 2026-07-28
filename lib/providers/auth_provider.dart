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
import 'package:telemarketing_app/providers/cache_coordinator.dart';

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

      // ── 跨租户判定（必须在 fetchTenantId 前读 prev）──
      // 详见 docs/dev/PLAN_34_CACHE_ISOLATION.md：同租户换人保留共享缓存，跨租户全清。
      final tenantService = _ref.read(tenantServiceProvider);
      final prevTenantId = tenantService.cachedTenantId;
      // force:true 绕过本地 TTL，确保拿到「本次登录」真实租户 ID，
      // 否则跨租户但缓存未过期时会误判同租户（见 tenant_service.fetchTenantId）。
      final newTenantId = await tenantService.fetchTenantId(force: true);
      final crossTenant = prevTenantId != null && prevTenantId != newTenantId;
      _ref.read(cacheCoordinatorProvider).onSessionChanged(crossTenant: crossTenant);

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
    // 只清用户私有缓存；租户共享（options/profile）保留供同租户换人加速
    _ref.read(cacheCoordinatorProvider).onLogout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 全设备退出登录
  ///
  /// 调 POST /api/auth/logout-all。成功时清除 Token 跳转登录页；
  /// 失败时不清除、不跳转，由调用方处理（如 Toast 提示）。
  Future<bool> logoutAll() async {
    final authService = _ref.read(authServiceProvider);
    final ok = await authService.logoutAll();
    if (ok) {
      final tokenStorage = _ref.read(tokenStorageProvider);
      await tokenStorage.clearAll();
      _ref.read(cacheCoordinatorProvider).onLogout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
    return ok;
  }

  /// 清除本地所有缓存数据（含登录凭据）并跳登录页重新登录。
  ///
  /// 与 [logout] 区别：
  /// - 清**所有**本地数据（含租户共享 options / tenant profile），[logout] 仅清用户私有；
  /// - **不调**后端 `/api/auth/logout`，不吊销后端会话、不影响其他设备（纯本地清除）；
  /// - **保留** [LocalStorageService] 的登录预填（saved_login_email/password）。
  ///
  /// 由设置页「清除缓存」调用：清除后状态置 [AuthStatus.unauthenticated]，
  /// [AuthGate] 自动跳转登录页（清除任务栈）。
  Future<void> clearLocalCache() async {
    final tokenStorage = _ref.read(tokenStorageProvider);
    await tokenStorage.clearAll();
    await _ref.read(cacheCoordinatorProvider).clearAllData();
    state = const AuthState(status: AuthStatus.unauthenticated);
    // 重建 API 层：清除 _isRefreshing / 刷新队列 / options._loadingFuture 等
    // 跨清除缓存存活的脏状态，等价于「杀 App 重开」，避免重新登录后列表卡骨架屏
    // （apiClient 是单例 Provider，不清会复用 401 刷新死锁的脏状态）。
    _ref.invalidate(apiClientProvider);
  }

  /// 修改密码（用户主动修改，需旧密码复核）
  ///
  /// 调 POST /api/auth/change-password。成功时清除本地 Token 并返回 null；
  /// **不在本方法内切换为未登录态**——否则 [AuthGate] 会立即跳转登录页，
  /// 导致修改密码页来不及展示成功 Toast（设计文档 §4.4 / §5.5）。
  /// 页面应先展示 Toast（约 2s），再调用 [notifyPasswordChanged] 触发跳转。
  /// 失败时返回错误消息字符串，由调用方显示到对应输入框下方。
  /// 返回 null 表示成功。
  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(errorMessage: null);

    try {
      final authService = _ref.read(authServiceProvider);
      await authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      // 改密成功 → 清空 Token（不在此切换登录态，详见方法注释）
      final tokenStorage = _ref.read(tokenStorageProvider);
      await tokenStorage.clearAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return '网络错误，请重试';
    }
  }

  /// 改密成功 Toast 展示完毕后，由修改密码页调用以触发登录页跳转（清除任务栈）。
  ///
  /// 仅切换为未登录态；Token 已在 [changePassword] 中清空。
  void notifyPasswordChanged() {
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
