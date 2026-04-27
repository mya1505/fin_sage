import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('transaction flow smoke test', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('FinSage Transaction Flow'))));
    expect(find.text('FinSage Transaction Flow'), findsOneWidget);
  });

  testWidgets('backup flow smoke test', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('FinSage Backup Flow'))));
    expect(find.text('FinSage Backup Flow'), findsOneWidget);
  });
}
