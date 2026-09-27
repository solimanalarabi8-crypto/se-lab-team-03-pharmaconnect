import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_connect_client/main.dart';

void main() {
  testWidgets('PharmaConnectApp smoke test and title verification', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PharmaConnectApp());

    // Verify that the title PharmaConnect and Auth screen are displayed
    expect(find.text('PharmaConnect'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);

    // Tap continue as guest to reach HomeScreen
    final guestButton = find.text('المتابعة كزائر والبحث عن الأدوية مباشرة');
    expect(guestButton, findsOneWidget);
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    // Verify HomeScreen is reached
    expect(find.text('ابحث عن دوائك الآن'), findsOneWidget);
  });
}
