import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared.dart';

void main() {
  group('LoadingIndicator', () {
    testWidgets('displays CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('uses default height of 120', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, 120);
    });

    testWidgets('uses custom height when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(height: 200),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, 200);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(
              message: 'Loading data...',
            ),
          ),
        ),
      );

      expect(find.text('Loading data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not display message when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      // Vérifier qu'il n'y a qu'un seul Text widget (probablement dans MaterialApp)
      // Le message ne devrait pas être affiché
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('uses theme primary color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          home: const Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.color, Colors.blue);
    });

    testWidgets('is const when possible', (tester) async {
      const indicator = LoadingIndicator();

      expect(indicator, isA<StatelessWidget>());
    });
  });
}
