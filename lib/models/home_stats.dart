/// 首页统计数据模型
///
/// 映射 GET /api/tenant/stats/mine + GET /api/tenant/schedules/stats/mine 的响应。
///
/// 字段说明：
/// - [followupCount]：今日跟进数（data.myToday.followupCount）
/// - [answeredCount]：今日接通数（data.myToday.answeredCount）
/// - [myLeadsTotal]：我的线索总数（data.myLeadsTotal）
/// - [dueToday]：今日待办数（data.byStatus.dueToday，兜底用 byStatus.pending）
class HomeStats {
  final int followupCount;
  final int answeredCount;
  final int myLeadsTotal;
  final int dueToday;

  const HomeStats({
    this.followupCount = 0,
    this.answeredCount = 0,
    this.myLeadsTotal = 0,
    this.dueToday = 0,
  });

  factory HomeStats.fromMyStats(Map<String, dynamic> json) {
    final data = json['data'] as Map? ?? {};
    final myToday = data['myToday'] as Map? ?? {};
    return HomeStats(
      followupCount: _toInt(myToday['followupCount']),
      answeredCount: _toInt(myToday['answeredCount']),
      myLeadsTotal: _toInt(data['myLeadsTotal']),
    );
  }

  /// 从 schedules/stats/mine 解析 dueToday（兜底用 pending）
  factory HomeStats.fromScheduleStats(Map<String, dynamic> json) {
    final data = json['data'] as Map? ?? {};
    final byStatus = data['byStatus'] as Map? ?? {};
    // 优先取 dueToday，兜底用 pending
    final dueToday = _toInt(byStatus['dueToday']);
    final pending = _toInt(byStatus['pending']);
    return HomeStats(dueToday: dueToday > 0 ? dueToday : pending);
  }

  /// 合并两个来源的数据
  HomeStats merge(HomeStats other) {
    return HomeStats(
      followupCount: followupCount,
      answeredCount: answeredCount,
      myLeadsTotal: myLeadsTotal,
      dueToday: other.dueToday > 0 ? other.dueToday : dueToday,
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
