/// 线索数据模型
///
/// 映射 GET /api/tenant/leads 列表项的响应结构。
class Lead {
  final String id;
  final String name;
  final String phone;
  final String? company;
  final String status;
  final String? categoryId;
  final String? projectId;
  final LeadProject? project;
  final LeadOwner? owner;
  final int? lastFollowupAt;
  final int? nextFollowupAt;
  final int updatedAt;

  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    this.company,
    required this.status,
    this.categoryId,
    this.projectId,
    this.project,
    this.owner,
    this.lastFollowupAt,
    this.nextFollowupAt,
    required this.updatedAt,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      company: json['company']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      categoryId: json['categoryId']?.toString(),
      projectId: json['projectId']?.toString(),
      project: json['project'] != null
          ? LeadProject.fromJson(json['project'] as Map<String, dynamic>)
          : null,
      owner: json['owner'] != null
          ? LeadOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      lastFollowupAt: _toInt(json['lastFollowupAt']),
      nextFollowupAt: _toInt(json['nextFollowupAt']),
      updatedAt: _toInt(json['updatedAt']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

/// 线索关联项目
class LeadProject {
  final String id;
  final String name;

  const LeadProject({required this.id, required this.name});

  factory LeadProject.fromJson(Map<String, dynamic> json) {
    return LeadProject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// 线索归属人
class LeadOwner {
  final String id;
  final String name;

  const LeadOwner({required this.id, required this.name});

  factory LeadOwner.fromJson(Map<String, dynamic> json) {
    return LeadOwner(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
