import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared/presentation/widgets/adaptive_navigation_scaffold.dart';

void main() {
  group('AdaptiveNavigationScaffold - Responsive Behavior', () {
    final testSections = [
      NavigationSection(
        label: 'Section 1',
        icon: Icons.home,
        builder: () => const Center(child: Text('Content 1')),
      ),
      NavigationSection(
        label: 'Section 2',
        icon: Icons.settings,
        builder: () => const Center(child: Text('Content 2')),
      ),
      NavigationSection(
        label: 'Section 3',
        icon: Icons.person,
        builder: () => const Center(child: Text('Content 3')),
      ),
    ];

    testWidgets('displays drawer on mobile screens (< 600px)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: 'Test App',
            ),
          ),
        ),
      );

      // Vérifier que le scaffold est présent
      expect(find.byType(Scaffold), findsOneWidget);

      // Sur mobile, il devrait y avoir un AppBar avec un menu drawer
      expect(find.byType(AppBar), findsOneWidget);

      // Vérifier qu'il y a un IconButton pour ouvrir le drawer (menu hamburger)
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Ouvrir le drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Vérifier que le drawer est ouvert et contient les sections
      expect(find.text('Section 1'), findsOneWidget);
      expect(find.text('Section 2'), findsOneWidget);
      expect(find.text('Section 3'), findsOneWidget);
    });

    testWidgets('displays NavigationRail on tablet screens (600px - 1023px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1200)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: 'Test App',
            ),
          ),
        ),
      );

      // Vérifier que le NavigationRail est présent
      expect(find.byType(NavigationRail), findsOneWidget);

      // Vérifier qu'il n'y a pas de drawer sur tablette
      expect(find.byIcon(Icons.menu), findsNothing);

      // Vérifier que le NavigationRail n'est pas étendu (compact mode)
      final navigationRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navigationRail.extended, isFalse);
      expect(navigationRail.labelType, NavigationRailLabelType.selected);

      // Vérifier que le contenu est affiché
      expect(find.text('Content 1'), findsOneWidget);
    });

    testWidgets('displays NavigationRail on desktop screens (>= 1024px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1440, 900)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: 'Test App',
            ),
          ),
        ),
      );

      // Vérifier que le NavigationRail est présent
      expect(find.byType(NavigationRail), findsOneWidget);

      // Vérifier qu'il n'y a pas de drawer sur desktop
      expect(find.byIcon(Icons.menu), findsNothing);

      // Vérifier que le contenu est affiché
      expect(find.text('Content 1'), findsOneWidget);
    });

    testWidgets('displays extended NavigationRail on wide screens (>= 800px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 900)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: 'Test App',
            ),
          ),
        ),
      );

      // Vérifier que le NavigationRail est présent et étendu
      final navigationRail = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(navigationRail.extended, isTrue);
      expect(navigationRail.labelType, NavigationRailLabelType.none);
    });

    testWidgets(
      'displays compact NavigationRail on narrow desktop screens (800px - 1024px)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(900, 1200)),
              child: AdaptiveNavigationScaffold(
                sections: testSections,
                appTitle: 'Test App',
              ),
            ),
          ),
        );

        // À 900px de large, c'est encore une tablette, donc compact
        final navigationRail = tester.widget<NavigationRail>(
          find.byType(NavigationRail),
        );
        expect(navigationRail.extended, isFalse);
      },
    );

    testWidgets('switches content when section is selected on mobile', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: 'Test App',
            ),
          ),
        ),
      );

      // Vérifier le contenu initial (Section 1)
      expect(find.text('Content 1'), findsOneWidget);
      expect(find.text('Content 2'), findsNothing);

      // Ouvrir le drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Sélectionner Section 2
      await tester.tap(find.text('Section 2'));
      await tester.pumpAndSettle();

      // Vérifier que le contenu a changé
      expect(find.text('Content 1'), findsNothing);
      expect(find.text('Content 2'), findsOneWidget);
    });

    testWidgets('switches content when section is selected on tablet/desktop', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 900)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: 'Test App',
            ),
          ),
        ),
      );

      // Vérifier le contenu initial (Section 1)
      expect(find.text('Content 1'), findsOneWidget);
      expect(find.text('Content 2'), findsNothing);

      // Trouver et cliquer sur la deuxième destination du NavigationRail
      final navigationRail = find.byType(NavigationRail);
      expect(navigationRail, findsOneWidget);

      // Sélectionner la deuxième destination (index 1)
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Vérifier que le contenu a changé
      expect(find.text('Content 1'), findsNothing);
      expect(find.text('Content 2'), findsOneWidget);
    });

    testWidgets('displays AppBar with correct title on all screen sizes', (
      tester,
    ) async {
      const appTitle = 'Test App Title';

      // Test mobile
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: appTitle,
            ),
          ),
        ),
      );

      expect(find.text(appTitle), findsOneWidget);

      // Test tablet
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1200)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: appTitle,
            ),
          ),
        ),
      );

      expect(find.text(appTitle), findsOneWidget);

      // Test desktop
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1440, 900)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: appTitle,
            ),
          ),
        ),
      );

      expect(find.text(appTitle), findsOneWidget);
    });

    testWidgets('displays loading widget when isLoading is true', (
      tester,
    ) async {
      const loadingWidget = Center(child: CircularProgressIndicator());

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: AdaptiveNavigationScaffold(
              sections: testSections,
              appTitle: 'Test App',
              isLoading: true,
              loadingWidget: loadingWidget,
            ),
          ),
        ),
      );

      // Vérifier que le loading widget est affiché
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('caches widgets for performance', (tester) async {
      int buildCount = 0;

      final sectionsWithCounter = [
        NavigationSection(
          label: 'Section 1',
          icon: Icons.home,
          builder: () {
            buildCount++;
            return Center(child: Text('Content 1 (built $buildCount times)'));
          },
        ),
        NavigationSection(
          label: 'Section 2',
          icon: Icons.settings,
          builder: () {
            buildCount++;
            return const Center(child: Text('Content 2'));
          },
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1200)),
            child: AdaptiveNavigationScaffold(
              sections: sectionsWithCounter,
              appTitle: 'Test App',
            ),
          ),
        ),
      );

      // Premier build de Section 1
      expect(buildCount, equals(1));
      expect(find.textContaining('Content 1'), findsOneWidget);

      // Passer à Section 2
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(buildCount, equals(2));
      expect(find.textContaining('Content 2'), findsOneWidget);

      // Revenir à Section 1 - ne devrait pas rebuild
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      // Le buildCount ne devrait pas avoir augmenté car le widget est en cache
      expect(buildCount, equals(2));
      expect(find.textContaining('Content 1'), findsOneWidget);
    });
  });
}
