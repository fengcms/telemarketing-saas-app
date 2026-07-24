/// 日程详情模型
///
/// 映射 GET /api/tenant/schedules/:id 的响应结构（含 lead 快照 + call 摘要）。
/// 字段说明：
/// - [id]：日程 UUID
/// - [tenantId]：租户 ID
/// - [userId]：归属人 ID（详情接口不返回姓名，需前端用 options 映射）
/// - [leadId]：关联线索 ID（跳转线索详情用；lead 快照无 id 字段）
/// - [callRecordId]：关联通话记录 ID（无则为 null）
/// - [title]：标题
/// - [content]：内容（可选）
/// - [scheduledAt]：计划时间（Unix 秒）
/// - [status]：pending / completed / cancelled
/// - [completedAt]/[createdAt]/[updatedAt]/[deletedAt]：各时间戳（Unix 秒）
/// - [lead]：关联线索快照（姓名 + 明文手机号；线索擦除时为 null）
/// - [call]：关联通话摘要（无关联为 null）
library;

/// 关联线索快照（详情接口 lead 字段，手机号不脱敏）
class LeadSnapshot {
  /// 线索姓名
  final String name;

  /// 线索手机号（明文）
  final String phone;

  const LeadSnapshot({required this.name, required this.phone});

  factory LeadSnapshot.fromJson(Map<String, dynamic> json) => LeadSnapshot(
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
      );
}

/// 关联通话摘要（详情接口 call 字段）
class CallSummary {
  /// 通话记录 ID
  final String id;

  /// 接听类型（answered / no_answer / busy 等）
  final String answerType;

  /// 通话时长（秒）
  final int duration;

  /// 开始时间（Unix 秒）
  final int startedAt;

  const CallSummary({
    required this.id,
    required this.answerType,
    required this.duration,
    required this.startedAt,
  });

  factory CallSummary.fromJson(Map<String, dynamic> json) => CallSummary(
        id: json['id']?.toString() ?? '',
        answerType: json['answerType']?.toString() ?? '',
        duration: _toInt(json['duration']),
        startedAt: _toInt(json['startedAt']),
      );
}

/// 日程详情
class ScheduleDetail {
  final String id;
  final String tenantId;
  final String userId;
  final String leadId;
  final String? callRecordId;
  final String title;
  final String? content;
  final int scheduledAt;
  final String status;
  final int? completedAt;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final LeadSnapshot? lead;
  final CallSummary? call;

  const ScheduleDetail({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.leadId,
    this.callRecordId,
    required this.title,
    this.content,
    required this.scheduledAt,
    required this.status,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lead,
    this.call,
  });

  factory ScheduleDetail.fromJson(Map<String, dynamic> json) {
    final lead = json['lead'] as Map<String, dynamic>?;
    final call = json['call'] as Map<String, dynamic>?;
    return ScheduleDetail(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      leadId: json['leadId']?.toString() ?? '',
      callRecordId: json['callRecordId']?.toString(),
      title: json['title']?.toString() ?? '未命名日程',
      content: json['content']?.toString(),
      scheduledAt: _toInt(json['scheduledAt']),
      status: json['status']?.toString() ?? 'pending',
      completedAt: _toIntOrNull(json['completedAt']),
      createdAt: _toInt(json['createdAt']),
      updatedAt: _toInt(json['updatedAt']),
      deletedAt: _toIntOrNull(json['deletedAt']),
      lead: lead == null ? null : LeadSnapshot.fromJson(lead),
      call: call == null ? null : CallSummary.fromJson(call),
    );
  }

  /// 判断是否逾期（需传入服务端时间）
  bool isOverdue(int serverTime) =>
      status == 'pending' && scheduledAt < serverTime;

  /// 计划时间中文展示：2026年7月24日 14:00 星期四
  String get scheduledDisplay {
    final dt = DateTime.fromMillisecondsSinceEpoch(scheduledAt * 1000);
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    const week = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final w = week[(dt.weekday - 1).clamp(0, 6)];
    return '${dt.year}年$mo月$d日 $h:$mi $w';
  }

  /// 时间戳格式化（YYYY-MM-DD HH:mm），用于创建/更新时间
  static String formatTs(int ts) {
    if (ts == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$mo-$d $h:$mi';
  }
}

/// 将动态值转为 int（解析失败回退 0）
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// 将动态值转为 int?（null 透传）
int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
