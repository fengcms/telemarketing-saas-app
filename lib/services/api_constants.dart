/// API 网关常量配置
///
/// 集中管理后端接口地址和认证相关的常亮。
/// 测试环境（默认）：https://tm-api-test.kao9.com/
/// 生产环境（需 dart-define）：https://tm-api.kao9.com/
///
/// 编译时通过 --dart-define=API_BASE_URL=https://tm-api.kao9.com 切换。
/// 不传参数时自动使用测试环境地址。
class ApiConstants {
  ApiConstants._();

  /// 生产环境地址
  static const String prodBaseUrl = 'https://tm-api.kao9.com';

  /// 测试环境地址（默认）
  static const String testBaseUrl = 'https://tm-api-test.kao9.com';

  /// 实际使用的后端地址
  ///
  /// 编译时通过 `--dart-define=API_BASE_URL=...` 覆盖。
  /// 不传 dart-define 时默认使用测试环境 [testBaseUrl]。
  /// 生产构建推荐：
  /// `flutter build apk --release --dart-define=API_BASE_URL=https://tm-api.kao9.com`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: testBaseUrl,
  );

  /// AccessToken 过期缓冲时间（秒）
  /// Token 实际过期前 60 秒就视为即将过期，提前刷新
  static const int tokenExpiryBufferSeconds = 60;

  /// 请求超时时间（毫秒）
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  /// 下拉选项缓存有效期（秒）
  /// 选项数据（分类/项目/用户等）变更不频繁，
  /// 缓存 10 小时（36000 秒）减少重复请求。
  /// 个人中心「更新公司数据」按钮可手动清空缓存重新拉取。
  static const int optionsCacheTTL = 36000;

  // ── 认证相关 ──

  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';
  static const String logoutAll = '/api/auth/logout-all';
  static const String changePassword = '/api/auth/change-password';

  // ── 健康检查 ──

  static const String health = '/health';

  // ── 租户信息 ──

  static const String profile = '/api/tenant/profile';

  // ── 统计 ──

  static const String statsMine = '/api/tenant/stats/mine';
  static const String statsTeam = '/api/tenant/stats';
  // 经理/管理员 · 团队当日概览（首页四宫格 + 「我的」页团队业绩卡共用）
  // 仅 tenant_manager / tenant_admin 可访问，实时 COUNT，无参
  static const String statsToday = '/api/tenant/stats/today';

  // ── 日程 ──

  static const String schedules = '/api/tenant/schedules';
  static const String schedulesStatsMine = '/api/tenant/schedules/stats/mine';
  static const String schedulesStats = '/api/tenant/schedules/stats';
  // 首页日程聚合（今日待办 + 即将到期 + 预览列表），无参
  static const String homeSummary = '/api/tenant/schedules/home-summary';

  // ── 线索 ──

  static const String leads = '/api/tenant/leads';
  static const String leadClaim = '/api/tenant/leads/{id}/claim';

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
