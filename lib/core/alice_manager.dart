/// Alice 网络请求检视工具（仅开发版接入）
///
/// 接入方式：
/// 1. 通过 [AliceManager.instance] 懒加载获取 Alice 实例与适配器；
/// 2. 在 [ApiClient] 的 Dio 实例上 add 适配器（它既是 Dio 拦截器，
///    又通过 `alice.addAdapter` 注入核心，自动捕获全部请求的 URL、参数、
///    请求头、响应体与耗时）；
/// 3. 在 [MaterialApp] 上挂 `navigatorKey: alice.getNavigatorKey()`，
///    并通过一个全局浮标按钮调用 `alice.showInspector()` 打开请求列表面板。
///
/// 重要：Alice/AliveDioAdapter 必须通过 [AliceManager] 懒加载，
/// 不得在模块顶层创建实例（否则 AOT 下会在 main() 之前、Flutter 引擎
/// 初始化之前运行，导致网络栈状态被破坏，HTTP 请求 DNS 解析失败）。
library;

import 'package:alice/alice.dart';
import 'package:alice/model/alice_configuration.dart';
import 'package:alice_dio/alice_dio_adapter.dart';

/// Alice 管理器：提供懒加载的 Alice 实例与 Dio 适配器。
///
/// 所有访问都通过 [AliceManager.instance] 进行，确保 Alice 仅在首次
/// 被访问时才初始化（此时 Flutter 引擎已就绪）。
class AliceManager {
  AliceManager._();

  static AliceManager? _instance;

  /// 单例，首次访问时懒加载创建。
  static AliceManager get instance {
    _instance ??= AliceManager._();
    return _instance!;
  }

  late final Alice alice = Alice(
    configuration: AliceConfiguration(
      /// 关闭摇一摇唤起（避免误触），统一用浮标按钮打开。
      showInspectorOnShake: false,
      /// 关闭系统通知栏常驻入口，仅用浮标按钮唤出，避免权限弹窗。
      showNotification: false,
    ),
  );

  late final AliceDioAdapter dioAdapter = AliceDioAdapter();
}
