/// 开发调试工具总开关
///
/// 通过编译参数开启，例如：
///   flutter build apk --dart-define=DEV_TOOLS=true
///
/// - 开启后：Alice 网络浮窗与登录页测试账号预填均生效；
/// - 不传或设为 false（正式构建默认）：上述能力完全不参与编译，
///   Dart 编译期会把相关引用消除，正式包零残留。
///
/// 正式发布构建请勿传入该参数。
const bool enableDevTools = bool.fromEnvironment(
  'DEV_TOOLS',
  defaultValue: false,
);
