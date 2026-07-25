/// 后端错误码 → 中文用户文案映射
///
/// 集中维护，便于统一文案。所有接口报错经 [ApiClient.parseError]
/// 统一替换为中文，覆盖登录、改密、线索、日程、通话记录等全端展示。
///
/// 映射来源：后端 error.code 对照表（2026-07-25 确认，后端真实值）。
class ErrorMessages {
  ErrorMessages._();

  static const Map<String, String> _map = {
    'VALIDATION': '请求参数校验失败',
    'STATUS_ROLLBACK_FORBIDDEN':
        '状态回退被拒（converted 硬终态、Manager 正向校验拦截、日程状态非法流转）',
    'AUTH_INVALID': '账号或密码错误',
    'AUTH_EXPIRED': 'Token 过期或已吊销',
    'AUTH_FORBIDDEN': '权限不足',
    'TENANT_EXPIRED': '租户已锁定，请联系平台超管',
    'TENANT_IN_GRACE': '租户已到期，宽限期内仅可导出数据',
    'NOT_FOUND': '资源不存在',
    'LEAD_DUPLICATE': '同项目+手机号线索已存在',
    'BATCH_TOO_LARGE': '批量操作超量',
    'ACCOUNT_LOCKED': '账号已锁定，请稍后重试',
    'RATE_LIMITED': '请求频率超限',
  };

  /// 解析用户可见文案。
  ///
  /// 命中 [code] 返回对应中文；未命中则返回 [fallback]（通常为后端原始 message），
  /// 二者皆为空时回退通用提示。
  static String resolve(String code, [String? fallback]) {
    return _map[code] ?? fallback ?? '未知错误，请稍后再试';
  }
}
