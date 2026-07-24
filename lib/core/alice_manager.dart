/// Alice 网络请求检视工具（仅开发版接入）
///
/// 接入方式：
/// 1. 本文件导出全局 [alice] 实例与 [aliceDioAdapter]；
/// 2. 在 [ApiClient] 的 Dio 实例上 add [aliceDioAdapter]（它既是 Dio 拦截器，
///    又通过 `alice.addAdapter` 注入核心，自动捕获全部请求的 URL、参数、
///    请求头、响应体与耗时）；
/// 3. 在 [MaterialApp] 上挂 `navigatorKey: alice.getNavigatorKey()`，
///    并通过一个全局浮标按钮调用 `alice.showInspector()` 打开请求列表面板。
///
/// 仅当 `enableDevTools` 为 true 时才会被引用；正式构建中因编译期
/// 死代码消除，本文件里的实例不会被创建。
library;

import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice_dio/alice_dio_adapter.dart';

/// 全局唯一 Alice 实例。
final Alice alice = Alice(
  configuration: AliceConfiguration(
    /// 关闭摇一摇唤起（避免误触），统一用浮标按钮打开。
    showInspectorOnShake: false,
    /// 关闭系统通知栏常驻入口，仅用浮标按钮唤出，避免权限弹窗。
    showNotification: false,
  ),
);

/// Dio 适配器：既是 Dio 拦截器，又向 [alice] 注入核心以收集请求。
final AliceDioAdapter aliceDioAdapter = AliceDioAdapter();
