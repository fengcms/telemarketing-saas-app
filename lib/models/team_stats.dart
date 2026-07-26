/// 团队统计模型
///
/// 映射 GET /api/tenant/stats 的响应（按 dateFrom/dateTo 区间聚合）。
///
/// ⚠️ 契约说明（2026-07-26 后端修正）：
/// 公海权威定义 = status=pending 且 ownerId IS NULL。
/// seed 聚合键曾误写为 `pool` 导致 funnel.pool 恒 0，
/// 现已全链路修正为 `pending`（design.md 已同步、测试库脏数据已 UPDATE）。
/// 客户端**统一用 `pending` 单键**，不保留 `pool` 兼容。
library;

/// 状态分布（当前快照）
class TeamStatusBreakdown {
  /// 公海：status=pending 且 ownerId IS NULL
  final int pending;

  /// 已分配
  final int assigned;

  /// 跟进中
  final int following;

  /// 已转化
  final int converted;

  /// 无效
  final int invalid;

  const TeamStatusBreakdown({
    required this.pending,
    required this.assigned,
    required this.following,
    required this.converted,
    required this.invalid,
  });

  factory TeamStatusBreakdown.fromJson(Map<String, dynamic> json) {
    final m = json;
    return TeamStatusBreakdown(
      pending: _int(m['pending']),
      assigned: _int(m['assigned']),
      following: _int(m['following']),
      converted: _int(m['converted']),
      invalid: _int(m['invalid']),
    );
  }

  /// 五项之和（用于环形图总计兜底）
  int get sum =>
      pending + assigned + following + converted + invalid;
}

/// 转化漏斗（线索生命周期：公海 → 已分配 → 跟进中 → 已转化）
class TeamFunnel {
  /// 基数 = 公海（修正键 pending，正常为非零最大值）
  final int pending;

  /// 已分配
  final int assigned;

  /// 跟进中
  final int following;

  /// 已转化
  final int converted;

  const TeamFunnel({
    required this.pending,
    required this.assigned,
    required this.following,
    required this.converted,
  });

  factory TeamFunnel.fromJson(Map<String, dynamic> json) {
    final m = json;
    return TeamFunnel(
      pending: _int(m['pending']),
      assigned: _int(m['assigned']),
      following: _int(m['following']),
      converted: _int(m['converted']),
    );
  }
}

/// 坐席绩效
class AgentPerf {
  final String userId;
  final String name;
  final int ownedLeads;
  final int followupCount;
  final int answeredCount;
  final int noAnswerCount;
  final int convertedCount;
  final int avgDuration;
  final int lastFollowupAt;

  const AgentPerf({
    required this.userId,
    required this.name,
    required this.ownedLeads,
    required this.followupCount,
    required this.answeredCount,
    required this.noAnswerCount,
    required this.convertedCount,
    required this.avgDuration,
    required this.lastFollowupAt,
  });

  factory AgentPerf.fromJson(Map<String, dynamic> json) {
    final m = json;
    return AgentPerf(
      userId: m['userId']?.toString() ?? '',
      name: m['name']?.toString() ?? '未知',
      ownedLeads: _int(m['ownedLeads']),
      followupCount: _int(m['followupCount']),
      answeredCount: _int(m['answeredCount']),
      noAnswerCount: _int(m['noAnswerCount']),
      convertedCount: _int(m['convertedCount']),
      avgDuration: _int(m['avgDuration']),
      lastFollowupAt: _int(m['lastFollowupAt']),
    );
  }

  /// 转化率（前端计算）：转化数 / 拥有线索数，分母 0 时返回 0
  double get conversionRate =>
      ownedLeads == 0 ? 0.0 : convertedCount / ownedLeads * 100;
}

/// 逐日趋势点
class DailyTrend {
  final String date; // yyyy-MM-dd
  final int added;
  final int followup;
  final int converted;
  final int answered;
  final int total;

  const DailyTrend({
    required this.date,
    required this.added,
    required this.followup,
    required this.converted,
    required this.answered,
    required this.total,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    final m = json;
    return DailyTrend(
      date: m['date']?.toString() ?? '',
      added: _int(m['added']),
      followup: _int(m['followup']),
      converted: _int(m['converted']),
      answered: _int(m['answered']),
      total: _int(m['total']),
    );
  }

  /// MM-DD（折线图 X 轴标签）
  String get mmdd => date.length >= 10 ? date.substring(5) : date;
}

/// 环比（仅"今日"范围有意义）
class TeamCompare {
  final int addedDiff;
  final int followupDiff;
  final int convertedDiff;

  const TeamCompare({
    required this.addedDiff,
    required this.followupDiff,
    required this.convertedDiff,
  });

  factory TeamCompare.fromJson(Map<String, dynamic> json) {
    final m = json;
    return TeamCompare(
      addedDiff: _int(m['addedDiff']),
      followupDiff: _int(m['followupDiff']),
      convertedDiff: _int(m['convertedDiff']),
    );
  }
}

/// 团队统计聚合结果
class TeamStats {
  final int total;
  final TeamStatusBreakdown byStatus;
  final int poolTotal;
  final int staleInPool;
  final TeamFunnel funnel;
  final List<AgentPerf> agentPerf;
  final List<DailyTrend> dailyTrend;
  final TeamCompare compareYesterday;

  const TeamStats({
    required this.total,
    required this.byStatus,
    required this.poolTotal,
    required this.staleInPool,
    required this.funnel,
    required this.agentPerf,
    required this.dailyTrend,
    required this.compareYesterday,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    final m = json;
    final byStatus = TeamStatusBreakdown.fromJson(
      m['byStatus'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    final funnel = TeamFunnel.fromJson(
      m['funnel'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    final agentPerf = (m['agentPerf'] as List<dynamic>?)
            ?.map((e) => AgentPerf.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <AgentPerf>[];
    final dailyTrend = (m['dailyTrend'] as List<dynamic>?)
            ?.map((e) => DailyTrend.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <DailyTrend>[];
    final compare = TeamCompare.fromJson(
      m['compareYesterday'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );
    return TeamStats(
      total: _int(m['total']),
      byStatus: byStatus,
      poolTotal: _int(m['poolTotal']),
      staleInPool: _int(m['staleInPool']),
      funnel: funnel,
      agentPerf: agentPerf,
      dailyTrend: dailyTrend,
      compareYesterday: compare,
    );
  }

  /// 团队级转化率：Σ转化数 / Σ拥有线索数，分母 0 时返回 0
  double get teamConversionRate {
    if (agentPerf.isEmpty) return 0.0;
    final owned = agentPerf.fold(0, (s, a) => s + a.ownedLeads);
    final conv = agentPerf.fold(0, (s, a) => s + a.convertedCount);
    return owned == 0 ? 0.0 : conv / owned * 100;
  }
}

/// 数字安全转换（兼容 int / double / 数字字符串 / null）
int _int(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
