import 'package:flutter_test/flutter_test.dart';

import 'package:sales_tracker/app.dart';

void main() {
  testWidgets('App boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SalesTrackerApp());

    // The splash screen shows the app name.
    expect(find.text('Al Tuwijri Wallet'), findsOneWidget);
  });
}
