import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/home/view/widgets/filters_modal.dart';
import 'package:sline_app/features/tasks/viewmodels/task_filter_view_model.dart';

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

        await tester.tap(find.text(TaskFilterViewModel.deliveryUpTo3Days));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(TaskFilterViewModel.sellerLevel2),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text(TaskFilterViewModel.sellerLevel2));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(FiltersModal.applyButtonKey));
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

      expect(viewModel.minBudget, isNull);
      expect(viewModel.maxBudget, isNull);
      expect(viewModel.deliveryTimes, isEmpty);
      expect(viewModel.sellerLevels, isEmpty);
      expect(viewModel.sortBy, TaskFilterViewModel.sortRelevance);
    });
  });
}
