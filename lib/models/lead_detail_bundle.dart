/// 线索详情聚合数据
///
/// 映射 GET /api/tenant/leads/:id 的完整响应。
/// 后端一次请求同时返回：线索对象 + 全量跟进时间线 +
/// 最近 5 条通话 + 最近 5 条日程，前端无需再补请求。
library;

import 'package:telemarketing_app/models/lead_detail.dart';
import 'package:telemarketing_app/models/follow_up_record.dart';
import 'package:telemarketing_app/models/call_record.dart';
import 'package:telemarketing_app/models/schedule.dart';

class LeadDetailBundle {
  /// 线索对象（含 categoryId 等字段）
  final LeadDetail lead;

  /// 全量跟进时间线（按 createdAt 倒序）
  final List<FollowUpRecord> followups;

  /// 最近 5 条通话（按 startedAt 倒序）
  final List<CallRecord> calls;

  /// 最近 5 条日程（按 scheduledAt 倒序）
  final List<Schedule> schedules;

  /// 拉取时间（毫秒），用于缓存过期判断
  final int fetchedAt;

  const LeadDetailBundle({
    required this.lead,
    this.followups = const [],
    this.calls = const [],
    this.schedules = const [],
    required this.fetchedAt,
  });

  /// 从详情接口的 data 体一次性解析四块数据。
  ///
  /// [fetchedAtMs] 可选，显式传入拉取时间；缺省取当前时间。
  factory LeadDetailBundle.fromJson(
    Map<String, dynamic> body, {
    int? fetchedAtMs,
  }) {
    final leadJson = body['lead'] as Map<String, dynamic>?;
    final followups = (body['followups'] as List<dynamic>? ?? [])
        .map((e) => FollowUpRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    final calls = (body['calls'] as List<dynamic>? ?? [])
        .map((e) => CallRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    final schedules = (body['schedules'] as List<dynamic>? ?? [])
        .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
        .toList();

    return LeadDetailBundle(
      // lead 缺失时退化为空对象，交由上层按 404/已删除 处理
      lead: LeadDetail.fromJson(leadJson ?? const {}),
      followups: followups,
      calls: calls,
      schedules: schedules,
      fetchedAt: fetchedAtMs ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
