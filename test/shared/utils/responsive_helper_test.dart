import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elyf_groupe_app/shared/utils/responsive_helper.dart';

void main() {
  group('ResponsiveHelper', () {
    testWidgets('isMobile returns true for mobile screens (< 600px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isMobile(context), isTrue);
              expect(ResponsiveHelper.isTablet(context), isFalse);
              expect(ResponsiveHelper.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isMobile returns true at mobile breakpoint (599px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(599, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isMobile(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet returns true for tablet screens (600px - 1023px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1200)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isMobile(context), isFalse);
              expect(ResponsiveHelper.isTablet(context), isTrue);
              expect(ResponsiveHelper.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet returns true at tablet breakpoint (600px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isTablet(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktop returns true for desktop screens (>= 1024px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1440, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isMobile(context), isFalse);
              expect(ResponsiveHelper.isTablet(context), isFalse);
              expect(ResponsiveHelper.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktop returns true at desktop breakpoint (1024px)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isWideScreen returns true for tablet and desktop (>= 600px)', (
      tester,
    ) async {
      // Test tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1200)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isWideScreen(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );

      // Test desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1440, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isWideScreen(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );

      // Test mobile (should be false)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isWideScreen(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('isExtendedScreen returns true for screens >= 800px', (
      tester,
    ) async {
      // Test extended screen
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1200)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isExtendedScreen(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );

      // Test non-extended screen
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(799, 1200)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isExtendedScreen(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('screenWidth returns correct width', (tester) async {
      const width = 800.0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(width, 1200)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.screenWidth(context), equals(width));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('screenHeight returns correct height', (tester) async {
      const height = 1200.0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, height)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.screenHeight(context), equals(height));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('adaptivePadding returns correct padding for mobile', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              final padding = ResponsiveHelper.adaptivePadding(context);
              expect(padding, equals(const EdgeInsets.all(16)));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('adaptivePadding returns correct padding for tablet', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1200)),
          child: Builder(
            builder: (context) {
              final padding = ResponsiveHelper.adaptivePadding(context);
              expect(padding, equals(const EdgeInsets.all(20)));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('adaptivePadding returns correct padding for desktop', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1440, 900)),
          child: Builder(
            builder: (context) {
              final padding = ResponsiveHelper.adaptivePadding(context);
              expect(padding, equals(const EdgeInsets.all(24)));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets(
      'adaptiveHorizontalPadding returns correct padding for mobile',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                final padding = ResponsiveHelper.adaptiveHorizontalPadding(
                  context,
                );
                expect(
                  padding,
                  equals(const EdgeInsets.symmetric(horizontal: 16)),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );

    testWidgets(
      'adaptiveHorizontalPadding returns correct padding for tablet',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(800, 1200)),
            child: Builder(
              builder: (context) {
                final padding = ResponsiveHelper.adaptiveHorizontalPadding(
                  context,
                );
                expect(
                  padding,
                  equals(const EdgeInsets.symmetric(horizontal: 20)),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );

    testWidgets(
      'adaptiveHorizontalPadding returns correct padding for desktop',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(1440, 900)),
            child: Builder(
              builder: (context) {
                final padding = ResponsiveHelper.adaptiveHorizontalPadding(
                  context,
                );
                expect(
                  padding,
                  equals(const EdgeInsets.symmetric(horizontal: 24)),
                );
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );

    testWidgets('adaptiveGridColumns returns 1 for mobile', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.adaptiveGridColumns(context), equals(1));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('adaptiveGridColumns returns 2 for tablet', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1200)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.adaptiveGridColumns(context), equals(2));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('adaptiveGridColumns returns 3 for desktop', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1440, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveHelper.adaptiveGridColumns(context), equals(3));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
