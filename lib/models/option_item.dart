/// 通用下拉选项模型
///
/// 映射选项接口（options/categories、options/projects 等）的响应结构。
class OptionItem {
  final String id;
  final String name;

  const OptionItem({required this.id, required this.name});

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    return OptionItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['content']?.toString() ?? '',
    );
  }
}
