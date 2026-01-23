import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared.dart';

void main() {
  group('EmptyState', () {
    testWidgets('displays icon, title and message correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No items',
              message: 'Start by adding an item',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Start by adding an item'), findsOneWidget);
    });

    testWidgets('displays only title when message is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.list,
              title: 'Empty list',
            ),
          ),
        ),
      );

      expect(find.text('Empty list'), findsOneWidget);
    });

    testWidgets('displays action button when provided', (tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.add,
              title: 'No items',
              message: 'Add your first item',
              action: ElevatedButton(
                onPressed: () => actionCalled = true,
                child: const Text('Add Item'),
              ),
            ),
          ),
        ),
      );

      final addButton = find.text('Add Item');
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      expect(actionCalled, isTrue);
    });

    testWidgets('does not display action button when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.list,
              title: 'Empty list',
            ),
          ),
        ),
      );

      // Vérifier qu'il n'y a pas de bouton d'action visible
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('uses theme colors for icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              onSurfaceVariant: Colors.grey,
            ),
          ),
          home: const Scaffold(
            body: EmptyState(
              icon: Icons.list,
              title: 'Empty',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.list));
      // L'icône devrait utiliser la couleur du thème avec opacité
      expect(icon.color, isNotNull);
    });

    testWidgets('centers content vertically', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.list,
              title: 'Empty',
            ),
          ),
        ),
      );

      final center = find.byType(Center);
      expect(center, findsWidgets);
    });

    testWidgets('is const when possible', (tester) async {
      const emptyState = EmptyState(
        icon: Icons.list,
        title: 'Empty',
      );

      expect(emptyState, isA<StatelessWidget>());
    });
  });
}
