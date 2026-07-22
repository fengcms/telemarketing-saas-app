import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'pages/login/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('=== FLUTTER ERROR ===\n${details.exception}\n${details.stack}');
  };
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const TelemarketingApp());
}

class TelemarketingApp extends StatelessWidget {
  const TelemarketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return TDTheme(
      data: TDThemeData.defaultData(),
      child: MaterialApp(
        title: '电销工作台',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF3F3F3),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0052D9),
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}
