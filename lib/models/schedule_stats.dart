/// 日程统计模型
///
/// 映射 GET /api/tenant/schedules/stats/mine 与
/// GET /api/tenant/schedules/stats（团队版）的响应。
/// 字段说明：
/// - [pending]：待办数（全量，不限日期）
/// - [completed]：已完成数
/// - [cancelled]：已取消数
/// - [overdue]：已逾期数（pending 且 scheduledAt < 当前，用于独立"逾期 N"标识）
/// - [todayPending]：今日待办数（严格今日窗口，北京时间，不含逾期）
///   与 home-summary.todayPending 同源，全端角标统一读此字段。
library;

/// 日程统计
class ScheduleStats {
  /// 待办数（全量，不限日期）
  final int pending;

  /// 已完成数
  final int completed;

  /// 已取消数
  final int cancelled;

  /// 已逾期数
  final int overdue;

  /// 今日待办数（严格今日窗口，不含逾期）
  final int todayPending;

  const ScheduleStats({
    this.pending = 0,
    this.completed = 0,
    this.cancelled = 0,
    this.overdue = 0,
    this.todayPending = 0,
  });

  /// 从接口响应解析。
  ///
  /// 兼容传入完整响应 {success, data} 或仅 data 层。
  /// [todayPending] 为顶层字段（与 home-summary 同源），
  /// 旧 [dueToday]（含历史逾期，byStatus 内）已弃用。
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
      todayPending: toInt(data['todayPending']),
    );
  }
}
