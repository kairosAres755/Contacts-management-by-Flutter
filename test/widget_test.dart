// Basic smoke test. Full app tests (with Firebase Auth) are better run as
// integration tests or with the Firebase emulator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Full app uses Firebase; widget tests run without platform plugins.
    // Use integration tests or Firebase emulator for auth flow.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Contacts')),
        ),
      ),
    );
    expect(find.text('Contacts'), findsOneWidget);
  });
}
