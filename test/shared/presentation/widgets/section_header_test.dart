import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('displays title correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const SectionHeader(
                  title: 'Test Section',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
    });

    testWidgets('applies custom top and bottom spacing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const SectionHeader(
                  title: 'Test Section',
                  top: 32,
                  bottom: 16,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
      // Vérifier que le padding est appliqué
      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.text('Test Section'),
          matching: find.byType(Padding),
        ),
      );
      final edgeInsets = padding.padding as EdgeInsets;
      expect(edgeInsets.top, 32);
      expect(edgeInsets.bottom, 16);
    });

    testWidgets('uses theme text style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const SectionHeader(
                  title: 'Test Section',
                ),
              ],
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Test Section'));
      expect(text.style?.fontWeight, FontWeight.bold);
      expect(text.style?.letterSpacing, 0.5);
    });

    testWidgets('is const when possible', (tester) async {
      const header = SectionHeader(
        title: 'Test',
        top: 0,
        bottom: 8,
      );

      expect(header, isA<StatelessWidget>());
    });
  });
}
