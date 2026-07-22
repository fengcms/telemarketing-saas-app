/// API 异常
///
/// 封装后端返回的结构化错误信息，方便页面层统一处理。
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): [$code] $message';

  // ── 常用错误码判断 ──

  bool get isAuthInvalid => code == 'AUTH_INVALID';
  bool get isAuthExpired => code == 'AUTH_EXPIRED';
  bool get isAuthForbidden => code == 'AUTH_FORBIDDEN';
  bool get isTenantExpired => code == 'TENANT_EXPIRED';
  bool get isTenantInGrace => code == 'TENANT_IN_GRACE';
  bool get isAccountLocked => code == 'ACCOUNT_LOCKED';
  bool get isRateLimited => code == 'RATE_LIMITED';
  bool get isValidation => code == 'VALIDATION';
  bool get isNotFound => code == 'NOT_FOUND';
  bool get isInternal => statusCode >= 500;
}
