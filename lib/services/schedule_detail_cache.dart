/// 日程详情缓存（内存，10 分钟 TTL）
///
/// 仅缓存当前 App 运行会话内；进程被杀即失效，符合
/// "日程详情默认缓存 10 分钟"的需求。不做磁盘持久化。
///
/// 用途：
/// - [get] 命中且未过期返回 detail，否则 null（用于进入详情页秒开）
/// - [put] 写入缓存
/// - [invalidate] 单条失效（写操作后调用，强制下次刷新）
/// - [invalidateAll] 全部失效（登出 / 列表重置时调用）
library;

import 'package:telemarketing_app/models/schedule_detail.dart';

/// 日程详情缓存（内存，10 分钟 TTL）
class ScheduleDetailCache {
  /// 缓存有效期：10 分钟
  static const int ttlMillis = 10 * 60 * 1000;

  final Map<String, _CacheEntry> _store = {};

  /// 命中且未过期返回 detail，否则清理并返回 null。
  ScheduleDetail? get(String id) {
    final entry = _store[id];
    if (entry == null) return null;
    if (DateTime.now().millisecondsSinceEpoch - entry.fetchedAt > ttlMillis) {
      _store.remove(id);
      return null;
    }
    return entry.detail;
  }

  /// 写入缓存（覆盖同名条目）。
  void put(String id, ScheduleDetail detail) {
    _store[id] = _CacheEntry(detail, DateTime.now().millisecondsSinceEpoch);
  }

  /// 单条失效。
  void invalidate(String id) => _store.remove(id);

  /// 全部失效。
  void invalidateAll() => _store.clear();
}

/// 缓存条目
class _CacheEntry {
  final ScheduleDetail detail;
  final int fetchedAt;

  _CacheEntry(this.detail, this.fetchedAt);
}
