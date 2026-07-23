/// 线索详情缓存（内存，10 分钟 TTL）
///
/// 仅缓存当前 App 运行会话内；进程被杀即失效，符合
/// "线索详情默认缓存 10 分钟"的需求。不做磁盘持久化。
///
/// 用途：
/// - [get] 命中且未过期返回 bundle，否则 null（用于进入详情页秒开）
/// - [put] 写入缓存
/// - [invalidate] 单条失效（写操作后调用，强制下次刷新）
/// - [invalidateAll] 全部失效（登出 / 列表重置时调用）
library;

import 'package:telemarketing_app/models/lead_detail_bundle.dart';

class LeadDetailCache {
  /// 缓存有效期：10 分钟
  static const int ttlMillis = 10 * 60 * 1000;

  final Map<String, _CacheEntry> _store = {};

  /// 命中且未过期返回 bundle，否则清理并返回 null。
  LeadDetailBundle? get(String leadId) {
    final entry = _store[leadId];
    if (entry == null) return null;
    if (DateTime.now().millisecondsSinceEpoch - entry.fetchedAt >
        ttlMillis) {
      _store.remove(leadId);
      return null;
    }
    return entry.bundle;
  }

  /// 写入缓存（覆盖同名条目）。
  void put(String leadId, LeadDetailBundle bundle) {
    _store[leadId] = _CacheEntry(bundle, bundle.fetchedAt);
  }

  /// 单条失效。
  void invalidate(String leadId) => _store.remove(leadId);

  /// 全部失效。
  void invalidateAll() => _store.clear();
}

/// 缓存条目
class _CacheEntry {
  final LeadDetailBundle bundle;
  final int fetchedAt;

  _CacheEntry(this.bundle, this.fetchedAt);
}
