/// 通话记录模型
///
/// 映射 GET /api/tenant/calls 列表项的响应结构。
/// 用于线索详情页 D 区通话记录摘要和通话记录列表页。
class CallRecord {
  final String id;
  final String leadId;
  final String userId;
  final String phone;
  final String direction;
  final String? answerType;
  final int startedAt;
  final int? endedAt;
  final int? duration;
  final String? recordingUrl;
  final int createdAt;

  const CallRecord({
    required this.id,
    required this.leadId,
    required this.userId,
    required this.phone,
    required this.direction,
    this.answerType,
    required this.startedAt,
    this.endedAt,
    this.duration,
    this.recordingUrl,
    required this.createdAt,
  });

  /// 格式化的时长文本（M:SS）
  String get durationText {
    if (duration == null || duration == 0) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// 简短日期格式（MM-DD HH:mm）
  String get shortDateTime {
    final dt =
        DateTime.fromMillisecondsSinceEpoch(startedAt * 1000);
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    return CallRecord(
      id: json['id']?.toString() ?? '',
      leadId: json['leadId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'outbound',
      answerType: json['answerType']?.toString(),
      startedAt: _toInt(json['startedAt']) ?? 0,
      endedAt: _toInt(json['endedAt']),
      duration: _toInt(json['duration']),
      recordingUrl: json['recordingUrl']?.toString(),
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
