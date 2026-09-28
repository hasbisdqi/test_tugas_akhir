import 'package:flutter_test/flutter_test.dart';
import 'package:test_tugas_akhir/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAgroApp(
      isLoggedIn: false,
      initialThemeMode: 'light',
    ));
    expect(find.text('SMART AGRO SYSTEM'), findsOneWidget);
  });
}
