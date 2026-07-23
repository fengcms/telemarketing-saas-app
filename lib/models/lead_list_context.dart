/// 线索列表上下文
///
/// 从列表页跳转详情页时携带的路由参数，
/// 详情页据此决定是否显示底部线索导航条。
class LeadListContext {
  /// 有序 ID 数组（当前筛选+排序结果）
  final List<String> ids;

  /// 当前线索在数组中的索引（0-based）
  final int index;

  /// 来源标识："leads" | "public_pool"
  final String source;

  const LeadListContext({
    required this.ids,
    required this.index,
    this.source = 'leads',
  });

  /// 是否有上一个线索
  bool get hasPrev => index > 0;

  /// 是否有下一个线索
  bool get hasNext => index < ids.length - 1;

  /// 上一个线索 ID
  String? get prevId => hasPrev ? ids[index - 1] : null;

  /// 下一个线索 ID
  String? get nextId => hasNext ? ids[index + 1] : null;

  /// 显示文本，如 "3 / 28"
  String get displayText => '${index + 1} / ${ids.length}';

  /// 创建下一个上下文（切换到下一条）
  LeadListContext next() => copyWith(index: index + 1);

  /// 创建上一个上下文（切换到上一条）
  LeadListContext prev() => copyWith(index: index - 1);

  /// 跳过当前已删除的 ID 后创建新上下文
  LeadListContext skipAndNext({required String removedId}) {
    final filtered = ids.where((id) => id != removedId).toList();
    final newIndex = filtered.indexOf(ids[index + 1]);
    return LeadListContext(
      ids: filtered,
      index: newIndex >= 0 ? newIndex : index,
      source: source,
    );
  }

  LeadListContext copyWith({
    List<String>? ids,
    int? index,
    String? source,
  }) {
    return LeadListContext(
      ids: ids ?? this.ids,
      index: index ?? this.index,
      source: source ?? this.source,
    );
  }
}
