/// 日程统计模型
///
/// 映射 GET /api/tenant/schedules/stats/mine 的响应。
/// 字段说明：
/// - [pending]：待办数
/// - [completed]：已完成数
/// - [cancelled]：已取消数
/// - [overdue]：已逾期数（pending 且 scheduledAt < 当前）
/// - [dueToday]：今日待办数（按服务端时间）
library;

/// 日程统计
class ScheduleStats {
  /// 待办数
  final int pending;

  /// 已完成数
  final int completed;

  /// 已取消数
  final int cancelled;

  /// 已逾期数
  final int overdue;

  /// 今日待办数
  final int dueToday;

  const ScheduleStats({
    this.pending = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.overdue = 0,
    this.dueToday = 0,
  });

  /// 从接口响应解析。
  ///
  /// 兼容传入完整响应 {success, data} 或仅 data 层 {byStatus}。
  factory ScheduleStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] as Map : json;
    final byStatus =
        data['byStatus'] is Map ? data['byStatus'] as Map : <String, dynamic>{};

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return ScheduleStats(
      pending: toInt(byStatus['pending']),
      completed: toInt(byStatus['completed']),
      cancelled: toInt(byStatus['cancelled']),
      overdue: toInt(byStatus['overdue']),
      dueToday: toInt(byStatus['dueToday']),
    );
  }
}
