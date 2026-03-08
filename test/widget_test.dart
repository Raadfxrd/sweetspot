import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SweetspotApp(),
      ),
    );

    // Verify the app bar title is rendered
    expect(find.text('SWEETSPOT'), findsOneWidget);
  });

  testWidgets('Room canvas is shown', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SweetspotApp(),
      ),
    );

    await tester.pump();

    // Verify the room setup panel header
    expect(find.text('ROOM DIMENSIONS'), findsOneWidget);
  });
}
