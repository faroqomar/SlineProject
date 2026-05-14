import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/sliver_tab_bar_delegate.dart';

void main() {
  group('SliverTabBarDelegate', () {
    testWidgets('T-CW001 renders TabBar child inside CustomScrollView', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const DefaultTabController(
            length: 2,
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverTabBarDelegate(
                      TabBar(
                        tabs: [
                          Tab(text: 'Tab A'),
                          Tab(text: 'Tab B'),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
    });

    test('T-CW002 maxExtent and minExtent return TabBar preferred size', () {
      const tabBar = TabBar(
        tabs: [
          Tab(text: 'X'),
          Tab(text: 'Y'),
        ],
      );
      const delegate = SliverTabBarDelegate(tabBar);

      expect(delegate.maxExtent, equals(tabBar.preferredSize.height));
      expect(delegate.minExtent, equals(tabBar.preferredSize.height));
    });

    test('T-CW003 shouldRebuild returns false for same tabBar', () {
      const tabBar = TabBar(
        tabs: [
          Tab(text: 'A'),
          Tab(text: 'B'),
        ],
      );
      const delegate1 = SliverTabBarDelegate(tabBar);
      const delegate2 = SliverTabBarDelegate(tabBar);

      expect(delegate1.shouldRebuild(delegate2), isFalse);
    });

    testWidgets('T-CW004 applies custom backgroundColor', (tester) async {
      final customSurface = AmberDuskTokens.colors.surfaceRaised;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverTabBarDelegate(
                      const TabBar(
                        tabs: [
                          Tab(text: 'A'),
                          Tab(text: 'B'),
                        ],
                      ),
                      backgroundColor: customSurface,
                    ),
                  ),
                  const SliverFillRemaining(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // SliverTabBarDelegate wraps TabBar in a Container with BoxDecoration
      final containers = tester.widgetList<Container>(
        find.ancestor(
          of: find.byType(TabBar),
          matching: find.byType(Container),
        ),
      );
      final hasCustomBg = containers.any((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.color == customSurface;
      });
      expect(hasCustomBg, isTrue);
    });

    testWidgets('T-CW005 uses Amber Dusk surface with themed border', (
      tester,
    ) async {
      final cardTheme = AmberDuskTokens.widgetTheme.cards;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: DefaultTabController(
            length: 2,
            child: Material(
              child: Builder(
                builder: (context) {
                  const delegate = SliverTabBarDelegate(
                    TabBar(
                      tabs: [
                        Tab(text: 'A'),
                        Tab(text: 'B'),
                      ],
                    ),
                  );
                  const double shrinkOffset = 1;
                  const overlapsContent = true;
                  return delegate.build(context, shrinkOffset, overlapsContent);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final containers = tester
          .widgetList<Container>(
            find.ancestor(
              of: find.byType(TabBar),
              matching: find.byType(Container),
            ),
          )
          .toList();
      expect(containers, isNotEmpty);
      final container = containers.first;
      final rawDecoration = container.decoration;
      if (rawDecoration is! BoxDecoration) {
        throw TestFailure(
          'Expected SliverTabBarDelegate decoration to be BoxDecoration.',
        );
      }
      final decoration = rawDecoration;
      final rawBorder = decoration.border;
      if (rawBorder is! Border) {
        throw TestFailure('Expected SliverTabBarDelegate border to be Border.');
      }
      final border = rawBorder;

      expect(decoration.color, cardTheme.panel.background);
      expect(border.bottom.color, cardTheme.border);
      expect(border.bottom.width, cardTheme.borderWidth);
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });
}
