import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared.dart';

void main() {
  group('ErrorDisplayWidget', () {
    testWidgets('displays error message correctly', (tester) async {
      const error = 'Test error message';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
            ),
          ),
        ),
      );

      expect(find.text('Erreur de chargement'), findsOneWidget);
      expect(find.textContaining(error), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays custom title when provided', (tester) async {
      const error = 'Test error';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
              title: 'Custom Error Title',
            ),
          ),
        ),
      );

      expect(find.text('Custom Error Title'), findsOneWidget);
      expect(find.text('Erreur de chargement'), findsNothing);
    });

    testWidgets('displays custom message when provided', (tester) async {
      const error = 'Test error';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
              message: 'Custom error message',
            ),
          ),
        ),
      );

      expect(find.text('Custom error message'), findsOneWidget);
    });

    testWidgets('displays retry button when onRetry is provided', (tester) async {
      var retryCalled = false;
      const error = 'Test error';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      final retryButton = find.text('Réessayer');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      expect(retryCalled, isTrue);
    });

    testWidgets('does not display retry button when onRetry is null', (tester) async {
      const error = 'Test error';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
            ),
          ),
        ),
      );

      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('uses theme error color', (tester) async {
      const error = 'Test error';

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              error: Colors.red,
            ),
          ),
          home: Scaffold(
            body: ErrorDisplayWidget(
              error: error,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, Colors.red);
    });
  });
}
