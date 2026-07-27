/// 客户详情模型
///
/// 映射 GET /api/tenant/leads/:id 返回的 data.customer 对象。
/// 仅当线索状态为 `converted`（已转化）时存在。
class CustomerDetail {
  final String id;
  final String? tenantId;
  final String? leadId;
  final String name;
  final String phone;
  final String? company;
  final String? position;
  final String? gender;
  final int? age;
  final String? wechat;
  final String? address;
  final String? ownerId;
  final String? projectId;
  final String? categoryId;
  final String level;
  final String? customFields;
  final String? remark;
  final int? convertedAt;
  final int? consentAt;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final int? erasedAt;

  const CustomerDetail({
    required this.id,
    this.tenantId,
    this.leadId,
    required this.name,
    required this.phone,
    this.company,
    this.position,
    this.gender,
    this.age,
    this.wechat,
    this.address,
    this.ownerId,
    this.projectId,
    this.categoryId,
    this.level = 'normal',
    this.customFields,
    this.remark,
    this.convertedAt,
    this.consentAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.erasedAt,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      leadId: json['leadId']?.toString(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      company: json['company']?.toString(),
      position: json['position']?.toString(),
      gender: json['gender']?.toString(),
      age: _toInt(json['age']),
      wechat: json['wechat']?.toString(),
      address: json['address']?.toString(),
      ownerId: json['ownerId']?.toString(),
      projectId: json['projectId']?.toString(),
      categoryId: json['categoryId']?.toString(),
      level: json['level']?.toString() ?? 'normal',
      customFields: json['customFields']?.toString(),
      remark: json['remark']?.toString(),
      convertedAt: _toInt(json['convertedAt']),
      consentAt: _toInt(json['consentAt']),
      createdAt: _toInt(json['createdAt']) ?? 0,
      updatedAt: _toInt(json['updatedAt']) ?? 0,
      deletedAt: _toInt(json['deletedAt']),
      erasedAt: _toInt(json['erasedAt']),
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
