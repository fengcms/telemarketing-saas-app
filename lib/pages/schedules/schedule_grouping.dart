/// 日程列表分组逻辑（语义桶模型，纯函数，无状态依赖）。
///
/// 待办 Tab（逾期置顶）：已逾期 → 今天 → 明天 → 后天 → 本周 → 下周 → 更晚
/// 已完成 Tab（过去侧镜像）：今天 → 昨天 → 本周 → 上周 → 更早
///
/// 周起点取周一（国内习惯）；下周之后统一归入「更晚」。
/// 卡片本身已显示完整日期（YYYY-MM-DD HH:mm），按天分头无额外信息，
/// 改语义桶可消除「两个本周/下周」这类同名头。
///
/// 注意：日期标签基于设备本地时间计算，跨天不会自动重算，
/// 需下拉刷新或重建才会更新（跨天重算机制见开发文档，标记为待开发）。
part of 'schedule_list_page.dart';

/// 分组数据
class _Group {
  final String key;
  final String title;
  final bool isOverdue;
  final List<Schedule> items;

  _Group({
    required this.key,
    required this.title,
    required this.isOverdue,
    required this.items,
  });
}

/// 纯前端分组：语义桶模型（每个类别仅一个分组头，标签不会重复）。
List<_Group> _groupSchedules(
    List<Schedule> items, int serverTime, String tab) {
  final order = <String, int>{};
  final buckets = <String, List<Schedule>>{};
  for (final s in items) {
    final key = _bucketKey(s, serverTime, tab);
    order[key] = _bucketOrder(key, tab);
    buckets.putIfAbsent(key, () => []).add(s);
  }
  final sortedKeys = buckets.keys.toList()
    ..sort((a, b) => order[a]!.compareTo(order[b]!));
  return sortedKeys.map((k) {
    final list = buckets[k]!
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return _Group(
      key: k,
      title: _bucketTitle(k),
      isOverdue: k == 'overdue',
      items: list,
    );
  }).toList();
}

/// 计算一条日程归属的语义桶 key
String _bucketKey(Schedule s, int serverTime, String tab) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dt = DateTime.fromMillisecondsSinceEpoch(s.scheduledAt * 1000);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = day.difference(today).inDays;

  if (tab == 'pending') {
    if (s.isOverdue(serverTime)) return 'overdue';
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff == 2) return 'day_after';
  } else {
    if (diff == 0) return 'today';
    if (diff == -1) return 'yesterday';
  }

  // 周边界（周一为一周起点）
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final thisSunday = monday.add(const Duration(days: 6));
  final nextMonday = monday.add(const Duration(days: 7));
  final nextSunday = nextMonday.add(const Duration(days: 6));
  final lastMonday = monday.subtract(const Duration(days: 7));

  if (tab == 'pending') {
    if (!day.isBefore(monday) && !day.isAfter(thisSunday)) return 'this_week';
    if (!day.isBefore(nextMonday) && !day.isAfter(nextSunday)) {
      return 'next_week';
    }
    return 'later';
  } else {
    // 已完成：本周更早的天 / 上周 / 更早
    if (!day.isBefore(monday) && day.isBefore(today)) return 'this_week';
    if (!day.isBefore(lastMonday) && day.isBefore(monday)) {
      return 'last_week';
    }
    return 'earlier';
  }
}

/// 桶的排序权重（数值越小越靠上）
int _bucketOrder(String key, String tab) {
  const pendingOrder = <String, int>{
    'overdue': 0,
    'today': 1,
    'tomorrow': 2,
    'day_after': 3,
    'this_week': 4,
    'next_week': 5,
    'later': 6,
  };
  const doneOrder = <String, int>{
    'today': 0,
    'yesterday': 1,
    'this_week': 2,
    'last_week': 3,
    'earlier': 4,
  };
  return (tab == 'pending' ? pendingOrder : doneOrder)[key] ?? 99;
}

/// 桶标题
String _bucketTitle(String key) {
  switch (key) {
    case 'overdue':
      return '已逾期';
    case 'today':
      return '今天';
    case 'tomorrow':
      return '明天';
    case 'day_after':
      return '后天';
    case 'this_week':
      return '本周';
    case 'next_week':
      return '下周';
    case 'later':
      return '更晚';
    case 'yesterday':
      return '昨天';
    case 'last_week':
      return '上周';
    case 'earlier':
      return '更早';
    default:
      return key;
  }
}
