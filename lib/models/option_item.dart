/// 通用下拉选项模型
///
/// 映射选项接口（options/categories、options/projects 等）的响应结构。
/// [type] 字段仅快捷备注等部分接口返回（如 `followup`/`schedule`），其余场景为 null。
class OptionItem {
  final String id;
  final String name;
  final String? type;

  /// 成员角色（仅 /options/users 返回：tenant_admin / tenant_manager / tenant_employee）
  /// 其余接口（分类 / 项目 / 快捷备注等）不返回，为 null。
  final String? role;

  const OptionItem({required this.id, required this.name, this.type, this.role});

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    return OptionItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['content']?.toString() ?? '',
      type: json['type']?.toString(),
      role: json['role']?.toString(),
    );
  }
}
