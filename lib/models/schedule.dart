/// 日程模型
///
/// 映射 GET /api/tenant/schedules 列表项的响应结构。
/// 字段说明：
/// - [id]：日程 UUID
/// - [title]：日程标题
/// - [content]：日程备注（可选）
/// - [scheduledAt]：预定时间（Unix 秒）
/// - [status]：状态（pending / completed / cancelled）
/// - [leadName]：关联线索姓名（来自 lead.name，擦除时为 null）
/// - [leadPhone]：关联线索手机号（来自 lead.phone，擦除时为 null）
class Schedule {
  final String id;
  final String title;
  final String? content;
  final int scheduledAt;
  final String status;
  final String? leadName;
  final String? leadPhone;

  const Schedule({
    required this.id,
    required this.title,
    this.content,
    required this.scheduledAt,
    required this.status,
    this.leadName,
    this.leadPhone,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final lead = json['lead'] as Map?;
    return Schedule(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '未命名日程',
      content: json['content']?.toString(),
      scheduledAt: _toInt(json['scheduledAt']),
      status: json['status']?.toString() ?? 'pending',
      leadName: lead?['name']?.toString(),
      leadPhone: lead?['phone']?.toString(),
    );
  }

  /// 判断是否逾期（需传入服务端时间）
  bool isOverdue(int serverTime) =>
      status == 'pending' && scheduledAt < serverTime;

  /// 格式化时间显示（HH:mm）
  String get timeDisplay {
    final dt =
        DateTime.fromMillisecondsSinceEpoch(scheduledAt * 1000);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
