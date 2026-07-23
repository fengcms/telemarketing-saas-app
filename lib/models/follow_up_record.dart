/// 跟进记录模型
///
/// 映射 GET /api/tenant/leads/:id/followups 列表项的响应结构。
/// 跟进时间线中的单位条记录。
class FollowUpRecord {
  final String id;
  final String leadId;
  final String userId;
  final String content;
  final String? categoryId;
  final String? answerType;
  final int? duration;
  final int createdAt;

  const FollowUpRecord({
    required this.id,
    required this.leadId,
    required this.userId,
    required this.content,
    this.categoryId,
    this.answerType,
    this.duration,
    required this.createdAt,
  });

  /// 格式化的通话时长文本
  String get durationText {
    if (duration == null || duration == 0) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes分${seconds.toString().padLeft(2, '0')}秒';
  }

  /// 是否有通话信息（已接听）
  bool get hasCallInfo => answerType == 'answered';

  /// 是否有通话记录
  bool get hasAnswerType => answerType != null && answerType!.isNotEmpty;

  factory FollowUpRecord.fromJson(Map<String, dynamic> json) {
    return FollowUpRecord(
      id: json['id']?.toString() ?? '',
      leadId: json['leadId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      answerType: json['answerType']?.toString(),
      duration: _toInt(json['duration']),
      createdAt: _toInt(json['createdAt']) ?? 0,
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
