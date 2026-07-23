/// API 客户端（Dio 单例）
///
/// 全局唯一的 HTTP 客户端，配置了：
/// - 基础地址（测试环境 https://tm-api-test.kao9.com）
/// - Token 注入拦截器（自动注入 Authorization header）
/// - Token 自动刷新拦截器（401 时静默换发后重试）
/// - 全局错误码解析为 [ApiException]
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// API 客户端（Dio 单例）
///
/// 全局唯一的 HTTP 客户端，配置了：
/// - 基础地址（测试环境 https://tm-api-test.kao9.com）
/// - Token 注入拦截器（自动注入 Authorization header）
/// - Token 自动刷新拦截器（401 时静默换发后重试）
/// - 全局错误码解析为 [ApiException]
class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  /// 刷新 Token 的锁，防止并发刷新
  bool _isRefreshing = false;
  /// 等待刷新完成的请求队列
  final List<_PendingRequest> _refreshQueue = [];

  /// 423 FORCE_CHANGE_PASSWORD 回调（由 AuthNotifier 设置）
  void Function()? onForceChangePassword;

  ApiClient({required this._tokenStorage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_isPublicEndpoint(options.path)) {
          return handler.next(options);
        }
        final token = await _tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 423 FORCE_CHANGE_PASSWORD — 不走 refresh→retry，直接跳转改密页
        if (error.response?.statusCode == 423) {
          final data = error.response?.data;
          if (data is Map &&
              data['error'] is Map &&
              (data['error'] as Map)['code'] == 'FORCE_CHANGE_PASSWORD') {
            onForceChangePassword?.call();
            return handler.next(error);
          }
        }

        if (error.response?.statusCode == 401 &&
            !_isPublicEndpoint(error.requestOptions.path)) {
          final retryResponse = await _refreshAndRetry(error.requestOptions);
          if (retryResponse != null) {
            return handler.resolve(retryResponse);
          }
        }
        return handler.next(error);
      },
    ));

  }

  /// 获取 Dio 实例供业务 Service 调用
  Dio get dio => _dio;

  bool _isPublicEndpoint(String path) =>
      path == ApiConstants.login || path == ApiConstants.refresh;

  /// 刷新 Token 并重试原请求
  Future<Response?> _refreshAndRetry(RequestOptions requestOptions) async {
    // 如果正在刷新中，将当前请求加入等待队列
    if (_isRefreshing) {
      final completer = Completer<Response?>();
      _refreshQueue.add(_PendingRequest(requestOptions, completer));
      return completer.future;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
          .post(ApiConstants.refresh, data: {'refreshToken': refreshToken});

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final d = data['data'];
        if (d is! Map) return null;
        final newAccess = d['accessToken'] as String? ?? '';
        final newRefresh = d['refreshToken'] as String? ?? '';
        await _tokenStorage.saveTokens(
            accessToken: newAccess, refreshToken: newRefresh);

        // 重试所有排队的请求
        for (final pending in _refreshQueue) {
          pending.options.headers['Authorization'] = 'Bearer $newAccess';
          try {
            final retry = await _dio.fetch(pending.options);
            pending.completer.complete(retry);
          } catch (e) {
            pending.completer.complete(null);
          }
        }
        _refreshQueue.clear();

        // 重试当前请求
        requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        return _dio.fetch(requestOptions);
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// 解析后端错误为 [ApiException]
  static ApiException parseError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;

    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        statusCode: statusCode,
        code: err['code']?.toString() ?? 'UNKNOWN',
        message: err['message']?.toString() ?? '未知错误',
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        statusCode: 0,
        code: 'TIMEOUT',
        message: '网络连接超时，请检查网络后重试',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: '网络连接失败，请检查网络后重试',
      );
    }

    return ApiException(
      statusCode: statusCode,
      code: 'UNKNOWN',
      message: '系统异常，请稍后再试',
    );
  }
}

/// 待重试的请求记录
class _PendingRequest {
  final RequestOptions options;
  final Completer<Response?> completer;

  _PendingRequest(this.options, this.completer);
}
