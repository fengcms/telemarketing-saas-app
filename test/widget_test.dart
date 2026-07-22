import 'package:flutter_test/flutter_test.dart';

import 'package:telemarketing_app/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TelemarketingApp());
    await tester.pumpAndSettle();

    // 验证登录页标题
    expect(find.text('电销工作台'), findsOneWidget);
    expect(find.text('登 录'), findsOneWidget);
  });
}
