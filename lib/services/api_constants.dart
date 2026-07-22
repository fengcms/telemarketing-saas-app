/// API 网关常量配置
///
/// 集中管理后端接口地址和认证相关的常亮。
/// 线上测试环境：https://tm-api-test.kao9.com/
class ApiConstants {
  ApiConstants._();

  /// 线上测试环境地址
  static const String baseUrl = 'https://tm-api-test.kao9.com';

  /// AccessToken 过期缓冲时间（秒）
  /// Token 实际过期前 60 秒就视为即将过期，提前刷新
  static const int tokenExpiryBufferSeconds = 60;

  /// 请求超时时间（毫秒）
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // ── 认证相关 ──

  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String logoutAll = '/api/auth/logout-all';
  static const String changePassword = '/api/auth/change-password';

  // ── 租户信息 ──

  static const String profile = '/api/tenant/profile';

  // ── 统计 ──

  static const String statsMine = '/api/tenant/stats/mine';
  static const String statsTeam = '/api/tenant/stats';

  // ── 日程 ──

  static const String schedules = '/api/tenant/schedules';
  static const String schedulesStatsMine = '/api/tenant/schedules/stats/mine';
  static const String schedulesStats = '/api/tenant/schedules/stats';
}
