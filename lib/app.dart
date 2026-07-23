/// 认证门禁：根据登录态决定显示登录页还是首页
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/login/login_page.dart';
import 'pages/main_shell.dart';
import 'pages/force_change_password/force_change_password_page.dart';
import 'providers/auth_provider.dart';

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
      debugShowCheckedModeBanner: false,
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
