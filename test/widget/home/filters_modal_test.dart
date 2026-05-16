import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/home/view/widgets/filters_modal.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

const Offset _sheetScrollSmall = Offset(0, -260);

Future<void> _openFiltersModal(
  WidgetTester tester,
  TaskFilterViewModel viewModel,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<TaskFilterViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    unawaited(
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        barrierColor: Colors.black87,
                        builder: (_) => const FiltersModal(),
                      ),
                    );
                  },
                  child: const Text('Open Filters'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();

  await tester.tap(find.text('Open Filters'));
  await tester.pumpAndSettle();
}

void main() {
  group('FiltersModal', () {
    testWidgets(
      'applies delivery and seller filters to the shared view model',
      (tester) async {
        final viewModel = TaskFilterViewModel();

        await _openFiltersModal(tester, viewModel);

        expect(find.byType(DraggableScrollableSheet), findsNothing);
        expect(find.byKey(FiltersModal.sheetHandleKey), findsOneWidget);

        // Scroll the single inner ListView to find delivery time chips. The
        // visual layout can grow, so target the control instead of relying on
        // a fixed offset landing point.
        final scrollableFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        );
        final deliveryFinder = find
            .text(TaskFilterViewModel.deliveryUpTo3Days)
            .hitTestable();
        await tester.scrollUntilVisible(
          find.text(TaskFilterViewModel.deliveryUpTo3Days),
          _sheetScrollSmall.dy.abs(),
          scrollable: scrollableFinder,
        );
        await tester.pumpAndSettle();
        expect(deliveryFinder, findsOneWidget);
        await tester.tap(deliveryFinder);
        await tester.pumpAndSettle();

        // Scroll more to reach seller levels without coupling to section size.
        await tester.scrollUntilVisible(
          find.text(TaskFilterViewModel.sellerLevel2),
          _sheetScrollSmall.dy.abs(),
          scrollable: scrollableFinder,
        );
        await tester.pumpAndSettle();

        final sellerFinder = find
            .text(TaskFilterViewModel.sellerLevel2)
            .hitTestable();
        expect(sellerFinder, findsOneWidget);
        await tester.tap(sellerFinder);
        await tester.pumpAndSettle();

        // Tap apply — it's fixed at the bottom so always visible
        final applyFinder = find
            .byKey(FiltersModal.applyButtonKey)
            .hitTestable();
        expect(applyFinder, findsOneWidget);
        await tester.tap(applyFinder);
        await tester.pumpAndSettle();

        expect(viewModel.deliveryTimes, <String>[
          TaskFilterViewModel.deliveryUpTo3Days,
        ]);
        expect(viewModel.sellerLevels, <String>[
          TaskFilterViewModel.sellerLevel2,
        ]);
        expect(viewModel.maxBudget, isNull);
      },
    );

    testWidgets('apply with no changes does not create a max budget filter', (
      tester,
    ) async {
      final viewModel = TaskFilterViewModel();

      await _openFiltersModal(tester, viewModel);

      expect(find.text('Apply Filters'), findsOneWidget);
      await tester.tap(find.byKey(FiltersModal.applyButtonKey));
      await tester.pumpAndSettle();

      expect(viewModel.minBudget, isNull);
      expect(viewModel.maxBudget, isNull);
      expect(viewModel.deliveryTimes, isEmpty);
      expect(viewModel.sellerLevels, isEmpty);
      expect(viewModel.sortBy, TaskFilterViewModel.sortRelevance);
    });

    testWidgets('reset clears existing advanced filters immediately', (
      tester,
    ) async {
      final viewModel = TaskFilterViewModel()
        ..applyAdvancedFilters(
          minBudget: 100,
          maxBudget: 200,
          deliveryTimes: const [TaskFilterViewModel.deliveryUpTo7Days],
          sellerLevels: const [TaskFilterViewModel.sellerTopRated],
          sortBy: TaskFilterViewModel.sortPriceHighToLow,
        );

      await _openFiltersModal(tester, viewModel);

      await tester.tap(find.byKey(FiltersModal.resetButtonKey));
      await tester.pumpAndSettle();

      // Reset now only mutates local state. Tap Apply to commit to ViewModel.
      await tester.tap(find.byKey(FiltersModal.applyButtonKey));
      await tester.pumpAndSettle();

      expect(viewModel.minBudget, isNull);
      expect(viewModel.maxBudget, isNull);
      expect(viewModel.deliveryTimes, isEmpty);
      expect(viewModel.sellerLevels, isEmpty);
      expect(viewModel.sortBy, TaskFilterViewModel.sortRelevance);
    });

    testWidgets('shows active filter count before applying changes', (
      tester,
    ) async {
      final viewModel = TaskFilterViewModel();
      final initialSortBy = viewModel.sortBy;

      await _openFiltersModal(tester, viewModel);
      expect(find.text('Apply Filters'), findsOneWidget);

      await tester.tap(find.text(TaskFilterViewModel.sortNewest).hitTestable());
      await tester.pumpAndSettle();

      expect(find.text('Apply 1 Filter'), findsOneWidget);
      expect(viewModel.sortBy, initialSortBy);
    });

    testWidgets('uses a single sheet surface and IQD budget fields', (
      tester,
    ) async {
      final viewModel = TaskFilterViewModel();

      await _openFiltersModal(tester, viewModel);

      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.byKey(FiltersModal.sheetHandleKey), findsOneWidget);
      final sheet = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(sheet.heightFactor, equals(0.86));
      expect(find.text('IQD'), findsWidgets);
      expect(find.byIcon(Icons.attach_money), findsNothing);

      await tester.drag(find.byType(ListView), _sheetScrollSmall);
      await tester.pumpAndSettle();

      expect(find.text('Delivery Time'), findsOneWidget);
    });
  });
}
