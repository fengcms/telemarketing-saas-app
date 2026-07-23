/// 线索详情模型
///
/// 映射 GET /api/tenant/leads/:id 的响应结构。
/// 包含列表项所有字段 + 详情特有字段（position、createdAt、erasedAt 等）。
class LeadDetail {
  final String id;
  final String name;
  final String phone;
  final String? company;
  final String? position;
  final String status;
  final String? categoryId;
  final String? projectId;
  final LeadDetailProject? project;
  final LeadDetailOwner? owner;
  final int? lastFollowupAt;
  final int? nextFollowupAt;
  final int createdAt;
  final int updatedAt;
  final int? erasedAt;
  final String? gender;
  final String? address;
  final String? remark;

  const LeadDetail({
    required this.id,
    required this.name,
    required this.phone,
    this.company,
    this.position,
    required this.status,
    this.categoryId,
    this.projectId,
    this.project,
    this.owner,
    this.lastFollowupAt,
    this.nextFollowupAt,
    required this.createdAt,
    required this.updatedAt,
    this.erasedAt,
    this.gender,
    this.address,
    this.remark,
  });

  /// 是否为已转化线索
  bool get isConverted => status == 'converted';

  /// 是否为已删除/已擦除线索
  bool get isDeleted => erasedAt != null;

  factory LeadDetail.fromJson(Map<String, dynamic> json) {
    return LeadDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      company: json['company']?.toString(),
      position: json['position']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      categoryId: json['categoryId']?.toString(),
      projectId: json['projectId']?.toString(),
      project: json['project'] != null
          ? LeadDetailProject.fromJson(
              json['project'] as Map<String, dynamic>)
          : null,
      owner: json['owner'] != null
          ? LeadDetailOwner.fromJson(
              json['owner'] as Map<String, dynamic>)
          : null,
      lastFollowupAt: _toInt(json['lastFollowupAt']),
      nextFollowupAt: _toInt(json['nextFollowupAt']),
      createdAt: _toInt(json['createdAt']) ?? 0,
      updatedAt: _toInt(json['updatedAt']) ?? 0,
      erasedAt: _toInt(json['erasedAt']),
      gender: json['gender']?.toString(),
      address: json['address']?.toString(),
      remark: json['remark']?.toString(),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

/// 线索详情关联项目
class LeadDetailProject {
  final String id;
  final String name;

  const LeadDetailProject({required this.id, required this.name});

  factory LeadDetailProject.fromJson(Map<String, dynamic> json) {
    return LeadDetailProject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

/// 线索详情归属人
class LeadDetailOwner {
  final String id;
  final String name;

  const LeadDetailOwner({required this.id, required this.name});

  factory LeadDetailOwner.fromJson(Map<String, dynamic> json) {
    return LeadDetailOwner(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
