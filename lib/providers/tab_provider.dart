/// 当前选中的底部 Tab 索引
///
/// 0: 首页 | 1: 线索 | 2: 日程 | 3: 我的
///
/// 由 [MainShell] 维护，供各页面感知当前 Tab。例如首页仅在其为当前 Tab 时才在
/// App 回前台时刷新，避免在其它页面（如线索详情拨号）前后台切换时无谓请求。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前选中的底部 Tab 索引（0 = 首页）
final currentTabProvider = StateProvider<int>((ref) => 0);
