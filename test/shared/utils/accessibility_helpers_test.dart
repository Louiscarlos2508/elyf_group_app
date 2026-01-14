import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared/utils/accessibility_helpers.dart';

void main() {
  group('ContrastChecker', () {
    test('calcule correctement le contraste entre noir et blanc', () {
      final ratio = ContrastChecker.calculateContrastRatio(
        Colors.black,
        Colors.white,
      );
      // Noir sur blanc devrait avoir un ratio proche de 21:1
      expect(ratio, greaterThan(20.0));
      expect(ratio, lessThanOrEqualTo(21.0));
    });

    test('calcule correctement le contraste entre blanc et noir', () {
      final ratio = ContrastChecker.calculateContrastRatio(
        Colors.white,
        Colors.black,
      );
      // Blanc sur noir devrait avoir un ratio proche de 21:1
      expect(ratio, greaterThan(20.0));
      expect(ratio, lessThanOrEqualTo(21.0));
    });

    test(
      'calcule correctement le contraste entre deux couleurs similaires',
      () {
        final ratio = ContrastChecker.calculateContrastRatio(
          Colors.grey.shade600,
          Colors.grey.shade700,
        );
        // Deux gris similaires devraient avoir un faible ratio
        expect(ratio, lessThan(5.0));
      },
    );

    test('vérifie que noir sur blanc respecte WCAG AA', () {
      final meets = ContrastChecker.meetsContrastRatio(
        foreground: Colors.black,
        background: Colors.white,
        level: ContrastLevel.aa,
      );
      expect(meets, isTrue);
    });

    test('vérifie que noir sur blanc respecte WCAG AAA', () {
      final meets = ContrastChecker.meetsContrastRatio(
        foreground: Colors.black,
        background: Colors.white,
        level: ContrastLevel.aaa,
      );
      expect(meets, isTrue);
    });

    test('vérifie que deux couleurs similaires ne respectent pas WCAG AA', () {
      final meets = ContrastChecker.meetsContrastRatio(
        foreground: Colors.grey.shade400,
        background: Colors.grey.shade500,
        level: ContrastLevel.aa,
      );
      expect(meets, isFalse);
    });

    test('vérifie le contraste pour texte large (WCAG AA)', () {
      // Texte large nécessite 3:1 minimum pour AA
      final meets = ContrastChecker.meetsContrastRatio(
        foreground: Colors.grey.shade700,
        background: Colors.grey.shade100,
        isLargeText: true,
        level: ContrastLevel.aa,
      );
      // Devrait être vrai car 700 sur 100 devrait avoir > 3:1
      expect(meets, isTrue);
    });

    test('ajuste la couleur si le contraste est insuffisant', () {
      final adjusted = ContrastChecker.adjustColorForContrast(
        foreground: Colors.grey.shade400,
        background: Colors.grey.shade500,
        level: ContrastLevel.aa,
      );
      // Devrait retourner une couleur ajustée (pas null)
      expect(adjusted, isNotNull);

      // La couleur ajustée devrait avoir un meilleur contraste
      final adjustedMeets = ContrastChecker.meetsContrastRatio(
        foreground: adjusted!,
        background: Colors.grey.shade500,
        level: ContrastLevel.aa,
      );
      expect(adjustedMeets, isTrue);
    });

    test('retourne null si le contraste est déjà suffisant', () {
      final adjusted = ContrastChecker.adjustColorForContrast(
        foreground: Colors.black,
        background: Colors.white,
        level: ContrastLevel.aa,
      );
      expect(adjusted, isNull);
    });
  });

  group('AccessibleWidgets', () {
    testWidgets('accessibleButton ajoute les semantics correctes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleWidgets.accessibleButton(
              label: 'Bouton de test',
              hint: 'Appuyez pour continuer',
              onTap: () {},
              child: const Text('Test'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.text('Test'));
      expect(semantics, isNotNull);
      expect(semantics.label, 'Bouton de test');
      expect(semantics.hint, 'Appuyez pour continuer');
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('accessibleTextField ajoute les semantics correctes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleWidgets.accessibleTextField(
              label: 'Email',
              hint: 'Entrez votre email',
              value: 'test@example.com',
              child: const TextField(),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(TextField));
      expect(semantics, isNotNull);
      expect(semantics.label, 'Email');
      expect(semantics.hint, 'Entrez votre email');
      expect(semantics.value, 'test@example.com');
    });

    testWidgets('accessibleTextField ajoute "requis" si required', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleWidgets.accessibleTextField(
              label: 'Email',
              required: true,
              child: const TextField(),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(TextField));
      expect(semantics.label, 'Email (requis)');
    });

    testWidgets('accessibleImage exclut semantics si décorative', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleWidgets.accessibleImage(
              image: const Icon(Icons.image),
              excludeSemantics: true,
            ),
          ),
        ),
      );

      // Si excludeSemantics est true, l'image ne devrait pas avoir de semantics
      final semantics = tester.getSemantics(find.byIcon(Icons.image));
      // Le widget devrait être dans un ExcludeSemantics, donc pas de semantics
      expect(semantics.label, isEmpty);
    });

    testWidgets('accessibleHeader ajoute les semantics d\'en-tête', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleWidgets.accessibleHeader(
              level: 1,
              child: const Text('Titre principal'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.text('Titre principal'));
      expect(semantics, isNotNull);
      expect(semantics.hasFlag(SemanticsFlag.isHeader), isTrue);
      expect(semantics.headingLevel, 1);
    });
  });
}
