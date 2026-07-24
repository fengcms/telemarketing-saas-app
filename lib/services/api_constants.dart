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

  /// 下拉选项缓存有效期（秒）
  /// 选项数据（分类/项目等）变更不频繁，
  /// 设置 30 分钟（1800 秒）缓存减少重复请求。
  /// 可根据实际需求调整此值。
  static const int optionsCacheTTL = 1800;

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

  // ── 线索 ──

  static const String leads = '/api/tenant/leads';

  // ── 通话记录 ──

  static const String calls = '/api/tenant/calls';

  // ── 客户 ──

  static const String customers = '/api/tenant/customers';

  // ── 下拉选项 ──

  static const String optionsCategories = '/api/tenant/options/categories';
  static const String optionsProjects = '/api/tenant/options/projects';
  static const String optionsUsers = '/api/tenant/options/users';
  static const String optionsQuickNotes = '/api/tenant/options/quick-notes';
}
