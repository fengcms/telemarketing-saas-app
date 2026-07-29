/// 经理/管理员 · 团队当日概览统计模型
///
/// 映射 GET /api/tenant/stats/today 的响应（仅 TM/TA 可访问）。
/// 数据为**实时 COUNT（北京时间今日窗口）**，与 `lead_stats_daily` 宽表口径不同，
/// 不应与 `dailyTrend` 关联使用。
///
/// 字段说明：
/// - [todayFollowup]：团队今日跟进次数
/// - [todayAnswered]：团队今日接通数
/// - [todayConverted]：团队今日转化数
/// - [todayAdded]：团队今日新增线索
/// - [todayPending]：团队今日待办（与 home-summary.todayPending 同源同值）
/// - [compareYesterday]：较昨日同时段差值（followup/answered/converted 三项）
class ManagerTodayStats {
  final int todayFollowup;
  final int todayAnswered;
  final int todayConverted;
  final int todayAdded;
  final int todayPending;
  final CompareYesterday compareYesterday;

  const ManagerTodayStats({
    this.todayFollowup = 0,
    this.todayAnswered = 0,
    this.todayConverted = 0,
    this.todayAdded = 0,
    this.todayPending = 0,
    this.compareYesterday = const CompareYesterday(),
  });

  factory ManagerTodayStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map? ?? {};
    return ManagerTodayStats(
      todayFollowup: _toInt(data['todayFollowup']),
      todayAnswered: _toInt(data['todayAnswered']),
      todayConverted: _toInt(data['todayConverted']),
      todayAdded: _toInt(data['todayAdded']),
      todayPending: _toInt(data['todayPending']),
      compareYesterday: CompareYesterday.fromJson(
          (data['compareYesterday'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{}),
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

/// 较昨日同时段差值
class CompareYesterday {
  final int followupDiff;
  final int answeredDiff;
  final int convertedDiff;

  const CompareYesterday({
    this.followupDiff = 0,
    this.answeredDiff = 0,
    this.convertedDiff = 0,
  });

  factory CompareYesterday.fromJson(Map<String, dynamic> json) {
    return CompareYesterday(
      followupDiff: ManagerTodayStats._toInt(json['followupDiff']),
      answeredDiff: ManagerTodayStats._toInt(json['answeredDiff']),
      convertedDiff: ManagerTodayStats._toInt(json['convertedDiff']),
    );
  }
}
