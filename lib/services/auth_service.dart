/// 认证服务
///
/// 封装登录、登出、Token 刷新、改密等认证相关接口。
library;

import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_constants.dart';
import 'api_exception.dart';
import 'token_storage.dart';
import 'package:telemarketing_app/models/user.dart';

/// 认证服务
///
/// 封装登录、登出、Token 刷新、改密等认证相关接口。
class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService({
    required this._apiClient,
    required this._tokenStorage,
  });

  /// 登录
  ///
  /// 调用 POST /api/auth/login，成功后保存 Token 和用户信息。
  /// 返回 [User] 对象和 [mustResetPassword] 标记。
  /// 抛出 [ApiException] 时调用方自行处理（401/423等）。
  Future<({User user, bool mustResetPassword})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final body = data['data'] as Map;
        final accessToken = body['accessToken'] as String;
        final refreshToken = body['refreshToken'] as String;
        final userJson = body['user'] as Map<String, dynamic>;
        final user = User.fromJson(userJson);

        await _tokenStorage.saveAuth(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
          userRole: user.role,
        );

        return (user: user, mustResetPassword: user.mustResetPassword);
      }

      throw const ApiException(
        statusCode: 200,
        code: 'UNKNOWN',
        message: '登录失败，请稍后再试',
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 登出
  ///
  /// 调用 POST /api/auth/logout，清除本地 Token。
  Future<void> logout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } catch (_) {
      // 登出失败也要清除本地 Token
    } finally {
      await _tokenStorage.clearAll();
    }
  }

  /// 检查本地是否已有有效登录态
  ///
  /// 用于 APP 启动时自动登录。
  Future<User?> tryAutoLogin() async {
    final accessToken = await _tokenStorage.getAccessToken();
    final userId = await _tokenStorage.getUserId();
    if (accessToken == null || userId == null) return null;

    final userName = await _tokenStorage.getUserName();
    final userEmail = await _tokenStorage.getUserEmail();
    final userRole = await _tokenStorage.getUserRole();

    if (userName == null || userEmail == null || userRole == null) {
      await _tokenStorage.clearAll();
      return null;
    }

    return User(
      id: userId,
      email: userEmail,
      name: userName,
      role: userRole,
    );
  }

  /// 强制改密（管理员重置密码后首次登录场景）
  ///
  /// 调用 POST /api/auth/change-password，无需传入旧密码。
  /// 成功响应后后端自增 tv 使当前 Token 失效，APP 需清空本地 Token 并跳转登录页。
  Future<void> forceChangePassword({
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.changePassword,
        data: {'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// 修改密码（用户主动修改，需旧密码复核）
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.changePassword,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
