import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_test_app/main.dart';

void main() {
  testWidgets('App smoke test — launch screen shows AERO Sathi',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AeroSathiApp());
    expect(find.text('AERO Sathi'), findsOneWidget);
    expect(find.text('AI Airport Assistant'), findsOneWidget);
  });
}
