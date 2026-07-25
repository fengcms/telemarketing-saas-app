/// 首页日程聚合响应模型
///
/// 映射 GET /api/tenant/schedules/home-summary 的响应结构。
library;

import 'package:telemarketing_app/models/schedule.dart';
/// 该端点一次性返回首页日程区所需的全部数据，替代原先的
/// 待办列表查询、日程统计查询、即将到期时间窗查询三个请求。
///
/// 字段说明：
/// - [todayPending]：严格今日窗口内的待办数（00:00:00~23:59:59，排除历史逾期）
/// - [dueSoonCount]：未来 30 分钟内即将到期的日程数
/// - [pendingTotal]：全量待办总数（预留「查看全部」使用）
/// - [schedules]：待办日程预览（最多 5 条），结构与 [Schedule.fromJson] 同构
class HomeSummary {
  final int todayPending;
  final int dueSoonCount;
  final int pendingTotal;
  final List<Schedule> schedules;

  const HomeSummary({
    this.todayPending = 0,
    this.dueSoonCount = 0,
    this.pendingTotal = 0,
    this.schedules = const [],
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map? ?? {};
    final List<Schedule> items = (data['schedules'] as List?)
            ?.map((e) => Schedule.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return HomeSummary(
      todayPending: _toInt(data['todayPending']),
      dueSoonCount: _toInt(data['dueSoonCount']),
      pendingTotal: _toInt(data['pendingTotal']),
      schedules: items,
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
