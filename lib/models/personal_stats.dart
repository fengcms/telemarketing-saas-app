/// 个人统计模型
///
/// 映射 GET /api/tenant/stats/mine 的响应（按 dateFrom/dateTo 区间聚合）。
///
/// 转化率口径（产品已确认）：[conversionRate] 由后端计算并直接返回
/// （= myConverted / myLeadsTotal，分母 0 时后端返 0），前端仅展示、不二次计算。
library;

/// 个人统计数据
class PersonalStats {
  /// 名下线索总量
  final int leadsTotal;

  /// 累计跟进数
  final int followed;

  /// 累计接通数
  final int answered;

  /// 累计未接数
  final int noAnswer;

  /// 累计转化数
  final int converted;

  /// 转化率百分比（后端算，0~100，分母 0 时后端返 0）
  final double conversionRate;

  /// 今日跟进数（实时，固定不随日期范围变化）
  final int todayFollowup;

  /// 今日接通数（实时，固定不随日期范围变化）
  final int todayAnswered;

  const PersonalStats({
    this.leadsTotal = 0,
    this.followed = 0,
    this.answered = 0,
    this.noAnswer = 0,
    this.converted = 0,
    this.conversionRate = 0,
    this.todayFollowup = 0,
    this.todayAnswered = 0,
  });

  factory PersonalStats.fromJson(Map<String, dynamic> json) {
    final m = json;
    final data = m['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final myToday = data['myToday'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return PersonalStats(
      leadsTotal: _int(data['myLeadsTotal']),
      followed: _int(data['myFollowed']),
      answered: _int(data['myAnswered']),
      noAnswer: _int(data['myNoAnswer']),
      converted: _int(data['myConverted']),
      conversionRate: _num(data['myConversionRate']),
      todayFollowup: _int(myToday['followupCount']),
      todayAnswered: _int(myToday['answeredCount']),
    );
  }

  /// 转化率展示文案（如 "12.5%" / "0.0%"）
  String get conversionRateDisplay =>
      '${conversionRate.toStringAsFixed(1)}%';

  /// 转化率环形进度（0~1，>100% 截断为 1）
  double get conversionProgress =>
      conversionRate > 100 ? 1 : conversionRate / 100;

  /// "转化 X / 线索 Y" 说明
  String get conversionSummary => '转化 $converted / 线索 $leadsTotal';
}

/// 整数安全转换（兼容 int / double / 数字字符串 / null）
int _int(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// 浮点安全转换（兼容 num / 数字字符串 / null）
double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}
