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
      navigatorKey: enableDevTools ? alice.getNavigatorKey() : null,
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

/// 开发版浮标按钮：点击打开 Alice 网络请求检视面板
class _DevToolsFloatingButton extends StatelessWidget {
  const _DevToolsFloatingButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 90,
      child: GestureDetector(
        onTap: () => alice.showInspector(),
        child: Container(
          width: 48,
          height: 48,
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
