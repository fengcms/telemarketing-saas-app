/// 角色中文标签
///
/// 与接口返回的 role 码对应（见 /options/users 等）：
/// - tenant_employee → 电销专员
/// - tenant_manager  → 团队经理
/// - tenant_admin    → 管理员
/// 其余（含 null）→ 空串（按普通员工处理，隐藏团队入口）
///
/// 抽成共享函数，避免各页面重复硬编码角色文案导致不一致。
String roleLabel(String? role) {
  switch (role) {
    case 'tenant_employee':
      return '电销专员';
    case 'tenant_manager':
      return '团队经理';
    case 'tenant_admin':
      return '管理员';
    default:
      return '';
  }
}
