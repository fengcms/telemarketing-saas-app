/// 客户模型
///
/// 对应 GET /api/tenant/customers 列表响应（api.md §客户管理）。
/// 真实返回字段（驼峰）：id / tenantId / leadId / name / phone /
/// company / position / gender / age / wechat / address / ownerId /
/// projectId / categoryId / level / customFields / remark / convertedAt /
/// consentAt / createdAt / updatedAt / deletedAt / erasedAt
/// 本轮列表页仅用核心字段；其余字段详情页（doc18）再取。
library;

import 'package:flutter/material.dart';

/// 客户模型
class Customer {
  /// 客户 ID
  final String id;

  /// 来源线索 ID（详情页用）
  final String? leadId;

  /// 客户姓名（脱敏，如 "客户-吴艳"）
  final String? name;

  /// 电话（脱敏，如 "155****0125"）
  final String? phone;

  /// 公司（列表响应**有此字段但多为 null**，空则卡片隐藏公司行）
  final String? company;

  /// 等级：normal / important / vip / lost
  final String? level;

  /// 转化日期（Unix 秒）
  final int? convertedAt;

  /// 删除时间（null = 未删）
  final dynamic deletedAt;

  /// 擦除时间（null = 未擦除）
  final dynamic erasedAt;

  const Customer({
    required this.id,
    this.leadId,
    this.name,
    this.phone,
    this.company,
    this.level,
    this.convertedAt,
    this.deletedAt,
    this.erasedAt,
  });

  /// 从接口 JSON 构造
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      leadId: json['leadId']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      company: json['company']?.toString(),
      level: json['level']?.toString(),
      convertedAt: _toInt(json['convertedAt']),
      deletedAt: json['deletedAt'],
      erasedAt: json['erasedAt'],
    );
  }

  /// 展示姓名：空 → 未命名客户
  String get displayName => (name ?? '').isEmpty ? '未命名客户' : name!;

  /// 展示电话：空 → 无联系电话
  String get displayPhone =>
      (phone ?? '').isEmpty ? '无联系电话' : phone!;

  /// 等级中文标签（'' 表示无等级）
  String get levelLabel {
    switch (level) {
      case 'normal':
        return '普通';
      case 'important':
        return '重要';
      case 'vip':
        return 'VIP';
      case 'lost':
        return '流失';
      default:
        return '';
    }
  }

  /// 是否显示等级标签
  bool get hasLevel => levelLabel.isNotEmpty;

  /// 等级标签背景色（10% 透明度）
  Color get levelBgColor {
    switch (level) {
      case 'normal':
        return const Color(0x192BA471);
      case 'important':
        return const Color(0x190052D9);
      case 'vip':
        return const Color(0x19E37318);
      case 'lost':
        return const Color(0x19D54941);
      default:
        return const Color(0xFFF3F3F3);
    }
  }

  /// 等级标签文字色
  Color get levelTextColor {
    switch (level) {
      case 'normal':
        return const Color(0xFF2BA471);
      case 'important':
        return const Color(0xFF0052D9);
      case 'vip':
        return const Color(0xFFE37318);
      case 'lost':
        return const Color(0xFFD54941);
      default:
        return const Color(0xFF6B7A90);
    }
  }

  /// 转化日期展示：空/0 → "转化日期: —"
  String get convertedAtLabel {
    final sec = convertedAt;
    if (sec == null || sec <= 0) return '转化日期: —';
    final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '转化日期: $y-$m-$d';
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
