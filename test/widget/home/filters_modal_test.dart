import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/home/view/widgets/filters_modal.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

const Offset _sheetDragLarge = Offset(0, -500);
const Offset _sheetDragSmall = Offset(0, -200);

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
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const FiltersModal(),
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

        // Expand the sheet to full height so all filters are visible.
        // The drag handle area is at the top of the sheet — drag up to expand.
        final sheetFinder = find.byType(DraggableScrollableSheet);
        await tester.drag(sheetFinder, _sheetDragLarge);
        await tester.pumpAndSettle();

        // Now scroll the inner ListView to find delivery time chips
        final listFinder = find.byType(ListView);
        await tester.drag(listFinder, _sheetDragSmall);
        await tester.pumpAndSettle();

        final deliveryFinder = find
            .text(TaskFilterViewModel.deliveryUpTo3Days)
            .hitTestable();
        expect(deliveryFinder, findsOneWidget);
        await tester.tap(deliveryFinder);
        await tester.pumpAndSettle();

        // Scroll more to reach seller levels
        await tester.drag(listFinder, _sheetDragSmall);
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
      },
    );

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
      // Scroll to make Apply button visible in DraggableScrollableSheet.
      final sheetFinder = find.byType(DraggableScrollableSheet);
      await tester.drag(sheetFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

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
  });
}
