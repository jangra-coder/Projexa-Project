import 'package:flutter_test/flutter_test.dart';

import 'package:projexa/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WarrantyVaultApp());

    // Verify that splash screen shows app name
    expect(find.text('Warranty Vault'), findsOneWidget);
  });
}
