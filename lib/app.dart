/// 认证门禁：根据登录态决定显示登录页还是首页
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/login/login_page.dart';
import 'pages/main_shell.dart';
import 'pages/force_change_password/force_change_password_page.dart';
import 'providers/auth_provider.dart';
import 'core/alice_manager.dart';
import 'core/dev_tools.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // ignore: avoid_print
    print('=== FLUTTER ERROR ===\n${details.exception}\n${details.stack}');
  };
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ProviderScope(child: TelemarketingApp()));
}

class TelemarketingApp extends ConsumerWidget {
  const TelemarketingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '电销工作台',
      // 开发版挂 Alice 浮窗导航键；正式构建 enableDevTools 为 false，不挂
      navigatorKey: enableDevTools ? AliceManager.instance.alice.getNavigatorKey() : null,
      debugShowCheckedModeBanner: false,
      // 开发版浮标：在每页右上叠加一个按钮，点击打开 Alice 网络面板
      builder: (context, child) {
        if (!enableDevTools || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return Stack(
          children: [
            child,
            const _DevToolsFloatingButton(),
          ],
        );
      },
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3F3F3),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0052D9),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// 认证门禁：根据登录态决定显示登录页还是首页
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return switch (authState.status) {
      AuthStatus.initial => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.authenticated => const MainShell(),
      AuthStatus.forceChangePassword => const ForceChangePasswordPage(),
      AuthStatus.authenticating || AuthStatus.unauthenticated =>
        const LoginPage(),
    };
  }
}

/// 开发版浮标按钮：可拖拽到任意位置（避开测试控件），点击打开 Alice 网络请求检视面板
class _DevToolsFloatingButton extends StatefulWidget {
  const _DevToolsFloatingButton();

  @override
  State<_DevToolsFloatingButton> createState() => _DevToolsFloatingButtonState();
}

class _DevToolsFloatingButtonState extends State<_DevToolsFloatingButton> {
  /// 拖拽后的位置；null 表示默认右下角
  Offset? _offset;
  bool _moved = false;
  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final left = _offset?.dx ?? screen.width - _size - 16;
    final top = _offset?.dy ?? screen.height - _size - 90;
    return Positioned(
      left: left.clamp(0, screen.width - _size),
      top: top.clamp(0, screen.height - _size),
      child: GestureDetector(
        // 仅用 pan 手势：纯点击（无位移）才打开面板，拖拽时不触发点击
        onPanStart: (_) => _moved = false,
        onPanUpdate: (d) {
          _moved = true;
          setState(() {
            _offset = Offset(
              (d.globalPosition.dx - _size / 2)
                  .clamp(0, screen.width - _size),
              (d.globalPosition.dy - _size / 2)
                  .clamp(0, screen.height - _size),
            );
          });
        },
        onPanEnd: (_) {
          if (!_moved) AliceManager.instance.alice.showInspector();
          _moved = false;
        },
        child: Container(
          width: _size,
          height: _size,
          decoration: const BoxDecoration(
            color: Color(0xFF0052D9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.network_check,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
