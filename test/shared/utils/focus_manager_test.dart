import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared/utils/focus_manager.dart';

void main() {
  group('AppFocusManager', () {
    testWidgets('nextFocus déplace le focus vers le prochain champ', (tester) async {
      final focusNode1 = FocusNode();
      final focusNode2 = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode1),
                TextField(focusNode: focusNode2),
              ],
            ),
          ),
        ),
      );

      // Focus initial sur le premier champ
      focusNode1.requestFocus();
      await tester.pump();

      expect(focusNode1.hasFocus, isTrue);
      expect(focusNode2.hasFocus, isFalse);

      // Déplacer vers le prochain champ
      final context = tester.element(find.byType(Scaffold));
      AppFocusManager.nextFocus(context);
      await tester.pump();

      expect(focusNode1.hasFocus, isFalse);
      expect(focusNode2.hasFocus, isTrue);
    });

    testWidgets('unfocusAll enlève le focus de tous les champs', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(focusNode: focusNode),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);

      final context = tester.element(find.byType(Scaffold));
      AppFocusManager.unfocusAll(context);
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('requestFocus déplace le focus vers un node spécifique', (tester) async {
      final focusNode1 = FocusNode();
      final focusNode2 = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode1),
                TextField(focusNode: focusNode2),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      
      // Demander le focus sur le deuxième champ
      AppFocusManager.requestFocus(context, focusNode2);
      await tester.pump();

      expect(focusNode1.hasFocus, isFalse);
      expect(focusNode2.hasFocus, isTrue);
    });

    testWidgets('hasFocus vérifie si un node a le focus', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(focusNode: focusNode),
          ),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      
      expect(AppFocusManager.hasFocus(context, focusNode), isFalse);

      focusNode.requestFocus();
      await tester.pump();

      expect(AppFocusManager.hasFocus(context, focusNode), isTrue);
    });
  });

  group('FocusMixin', () {
    testWidgets('FocusMixin crée et gère les focus nodes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(),
        ),
      );

      final state = tester.state<_TestState>(find.byType(_TestWidget));
      
      expect(state.emailFocus, isNotNull);
      expect(state.emailFocus.debugLabel, 'email');
      
      state.dispose();
    });
  });

  group('FocusTrap', () {
    testWidgets('crée un FocusScope avec autofocus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FocusTrap(
              autofocus: true,
              child: const Text('Test'),
            ),
          ),
        ),
      );

      // FocusTrap crée un FocusScope, qui est un widget interne
      // On vérifie simplement que le widget se construit sans erreur
      expect(find.text('Test'), findsOneWidget);
    });
  });
}

class _TestWidget extends StatefulWidget {
  const _TestWidget();

  @override
  State<_TestWidget> createState() => _TestState();
}

class _TestState extends State<_TestWidget> with FocusMixin {
  late final FocusNode emailFocus = createFocusNode(debugLabel: 'email');

  @override
  Widget build(BuildContext context) => const SizedBox();

  @override
  void dispose() {
    disposeFocusNodes();
    super.dispose();
  }
}

