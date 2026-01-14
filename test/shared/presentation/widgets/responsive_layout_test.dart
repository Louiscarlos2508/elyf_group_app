import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared/utils/responsive_helper.dart';
import 'package:elyf_groupe_app/app/theme/design_tokens.dart';

/// Tests d'intégration pour les layouts responsive
void main() {
  group('Responsive Layout Integration Tests', () {
    testWidgets('adaptive padding respects breakpoints', (tester) async {
      Widget testWidget(BuildContext context) {
        final padding = ResponsiveHelper.adaptivePadding(context);
        return Container(padding: padding, child: const Text('Test'));
      }

      // Test mobile
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(builder: testWidget),
          ),
        ),
      );

      var container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, equals(const EdgeInsets.all(16)));

      // Test tablet
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1200)),
            child: Builder(builder: testWidget),
          ),
        ),
      );

      container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, equals(const EdgeInsets.all(20)));

      // Test desktop
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1440, 900)),
            child: Builder(builder: testWidget),
          ),
        ),
      );

      container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, equals(const EdgeInsets.all(24)));
    });

    testWidgets('grid columns adapt to screen size', (tester) async {
      Widget testWidget(BuildContext context) {
        final columns = ResponsiveHelper.adaptiveGridColumns(context);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
          ),
          itemBuilder: (context, index) => Container(),
          itemCount: 10,
        );
      }

      // Test mobile - 1 column
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(builder: testWidget),
          ),
        ),
      );

      var gridDelegate =
          tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      expect(gridDelegate.crossAxisCount, equals(1));

      // Test tablet - 2 columns
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1200)),
            child: Builder(builder: testWidget),
          ),
        ),
      );

      gridDelegate =
          tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      expect(gridDelegate.crossAxisCount, equals(2));

      // Test desktop - 3 columns
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1440, 900)),
            child: Builder(builder: testWidget),
          ),
        ),
      );

      gridDelegate =
          tester.widget<GridView>(find.byType(GridView)).gridDelegate
              as SliverGridDelegateWithFixedCrossAxisCount;
      expect(gridDelegate.crossAxisCount, equals(3));
    });

    testWidgets('design tokens work with responsive layouts', (tester) async {
      Widget testWidget(BuildContext context) {
        final isMobile = ResponsiveHelper.isMobile(context);
        return Container(
          padding: EdgeInsets.all(
            isMobile ? AppSpacing.small : AppSpacing.medium,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            boxShadow: AppShadows.medium(Colors.black),
          ),
          child: const Text('Test'),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(builder: testWidget),
          ),
        ),
      );

      // Vérifier que les design tokens sont appliqués
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, equals(const EdgeInsets.all(AppSpacing.small)));

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(AppRadius.card));
      expect(decoration.boxShadow, isNotNull);
    });

    testWidgets(
      'LayoutBuilder provides correct constraints at different screen sizes',
      (tester) async {
        Widget testWidget(BuildContext context) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > AppSizes.breakpointWide;
              return SizedBox(
                width: isWide ? 1200 : 600,
                child: const Text('Test'),
              );
            },
          );
        }

        // Test narrow screen
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: Builder(builder: testWidget),
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.width, equals(600));

        // Test wide screen
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1440, 900)),
              child: Builder(builder: testWidget),
            ),
          ),
        );

        final sizedBoxWide = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBoxWide.width, equals(1200));
      },
    );

    testWidgets('responsive breakpoints align with design tokens', (
      tester,
    ) async {
      // Vérifier que les breakpoints utilisés correspondent aux design tokens
      expect(
        ResponsiveHelper.mobileBreakpoint,
        lessThan(AppSizes.breakpointMedium),
      );

      expect(
        ResponsiveHelper.tabletBreakpoint,
        greaterThan(AppSizes.breakpointMedium),
      );

      expect(
        ResponsiveHelper.desktopBreakpoint,
        greaterThan(AppSizes.breakpointWide),
      );
    });
  });
}
