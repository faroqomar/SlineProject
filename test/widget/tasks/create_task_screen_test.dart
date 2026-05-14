import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/categories/data/categories_repository.dart';
import 'package:sline_app/features/categories/models/category_model.dart';
import 'package:sline_app/features/tasks/models/task_model.dart';
import 'package:sline_app/features/tasks/view/create_task_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/task_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockTaskViewModel extends Mock
    with ChangeNotifier
    implements TaskViewModel {}

class _MockCategoriesRepository extends Mock implements CategoriesRepository {}

Task _fallbackTask() {
  return Task(
    id: 'task-fallback',
    title: 'Fallback',
    description: 'Fallback description',
    budget: 10,
    userId: 'user-1',
    status: TaskStatus.open,
    createdAt: DateTime.utc(2026, 2, 24),
  );
}

Future<void> _pumpCreateTaskScreen(
  WidgetTester tester, {
  required _MockTaskViewModel taskVm,
  required _MockCategoriesRepository categoriesRepo,
}) async {
  when(() => categoriesRepo.getAll()).thenAnswer(
    (_) async => <CategoryModel>[
      CategoryModel(
        id: 'cat-design',
        name: 'Design',
        iconUrl: null,
        createdAt: DateTime.utc(2026, 2, 24),
      ),
    ],
  );
  when(() => taskVm.currentUserId).thenReturn('user-1');
  when(() => taskVm.loadCategories()).thenAnswer(
    (_) async => <CategoryModel>[
      CategoryModel(
        id: 'cat-design',
        name: 'Design',
        iconUrl: null,
        createdAt: DateTime.utc(2026, 2, 24),
      ),
    ],
  );
  when(() => taskVm.categories).thenReturn(<CategoryModel>[
    CategoryModel(
      id: 'cat-design',
      name: 'Design',
      iconUrl: null,
      createdAt: DateTime.utc(2026, 2, 24),
    ),
  ]);
  when(() => taskVm.categoriesLoading).thenReturn(false);
  when(() => taskVm.createTask(any())).thenAnswer((_) async => _fallbackTask());
  when(() => taskVm.updateTask(any(), any())).thenAnswer((_) async {});

  await pumpApp(
    tester,
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskViewModel>.value(value: taskVm),
        Provider<CategoriesRepository>.value(value: categoriesRepo),
      ],
      child: const CreateTaskScreen(),
    ),
  );
  await tester.pump();
}

Future<void> _tapPackageTier(WidgetTester tester, Key key) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final finder = find.byKey(key);
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_fallbackTask());
  });

  group('CreateTaskScreen T62-T63', () {
    testWidgets('T62 submit with empty fields shows validation snackbar', (
      tester,
    ) async {
      final taskVm = _MockTaskViewModel();
      final categoriesRepo = _MockCategoriesRepository();

      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('Please fill in title and description'), findsOneWidget);
      verifyNever(() => taskVm.createTask(any()));
      verifyNever(() => taskVm.updateTask(any(), any()));
    });

    testWidgets('T63 booking package tier switch preserves entered tier data', (
      tester,
    ) async {
      final taskVm = _MockTaskViewModel();
      final categoriesRepo = _MockCategoriesRepository();

      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      await tester.tap(find.byKey(CreateTaskScreen.bookingTypeCardKey));
      await tester.pump();

      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();

      await tester.ensureVisible(
        find.byKey(CreateTaskScreen.packagePriceFieldKey),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(CreateTaskScreen.packagePriceFieldKey),
        '50',
      );
      await tester.enterText(
        find.byKey(CreateTaskScreen.packageDescriptionFieldKey),
        'Basic package description',
      );

      await _tapPackageTier(tester, CreateTaskScreen.packageTierStandardKey);
      await tester.enterText(
        find.byKey(CreateTaskScreen.packagePriceFieldKey),
        '90',
      );
      await tester.enterText(
        find.byKey(CreateTaskScreen.packageDescriptionFieldKey),
        'Standard package description',
      );

      await _tapPackageTier(tester, CreateTaskScreen.packageTierBasicKey);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(CreateTaskScreen.packagePriceFieldKey),
            )
            .controller
            ?.text,
        '50',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(CreateTaskScreen.packageDescriptionFieldKey),
            )
            .controller
            ?.text,
        'Basic package description',
      );

      await _tapPackageTier(tester, CreateTaskScreen.packageTierStandardKey);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(CreateTaskScreen.packagePriceFieldKey),
            )
            .controller
            ?.text,
        '90',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(CreateTaskScreen.packageDescriptionFieldKey),
            )
            .controller
            ?.text,
        'Standard package description',
      );
    });

    testWidgets('submit can pop without post-pop setState exceptions', (
      tester,
    ) async {
      final taskVm = _MockTaskViewModel();
      final categoriesRepo = _MockCategoriesRepository();
      when(categoriesRepo.getAll).thenAnswer(
        (_) async => <CategoryModel>[
          CategoryModel(
            id: 'cat-design',
            name: 'Design',
            iconUrl: null,
            createdAt: DateTime.utc(2026, 2, 24),
          ),
        ],
      );
      when(() => taskVm.currentUserId).thenReturn('user-1');
      when(taskVm.loadCategories).thenAnswer(
        (_) async => <CategoryModel>[
          CategoryModel(
            id: 'cat-design',
            name: 'Design',
            iconUrl: null,
            createdAt: DateTime.utc(2026, 2, 24),
          ),
        ],
      );
      when(() => taskVm.categories).thenReturn(<CategoryModel>[
        CategoryModel(
          id: 'cat-design',
          name: 'Design',
          iconUrl: null,
          createdAt: DateTime.utc(2026, 2, 24),
        ),
      ]);
      when(() => taskVm.categoriesLoading).thenReturn(false);
      when(
        () => taskVm.createTask(any()),
      ).thenAnswer((_) async => _fallbackTask());

      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider<TaskViewModel>.value(
                              value: taskVm,
                            ),
                            Provider<CategoriesRepository>.value(
                              value: categoriesRepo,
                            ),
                          ],
                          child: const CreateTaskScreen(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pumpAndSettle();
      expect(find.text('Tender title'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byKey(CreateTaskScreen.titleFieldKey),
          matching: find.byType(EditableText),
        ),
        'Task title',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(CreateTaskScreen.descriptionFieldKey),
          matching: find.byType(EditableText),
        ),
        'Task description',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(CreateTaskScreen.budgetFieldKey),
          matching: find.byType(EditableText),
        ),
        '100',
      );
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();

      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('CreateTaskScreen T290-T305', () {
    late _MockTaskViewModel taskVm;
    late _MockCategoriesRepository categoriesRepo;

    setUp(() {
      taskVm = _MockTaskViewModel();
      categoriesRepo = _MockCategoriesRepository();
    });

    /// Helper to advance from step 1 to step 2 via the primary action button.
    Future<void> advanceToStep2(WidgetTester tester) async {
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();
    }

    /// Pump the screen in edit mode with a pre-existing task.
    Future<void> pumpEditModeScreen(
      WidgetTester tester, {
      required _MockTaskViewModel vm,
      required _MockCategoriesRepository repo,
      required Task editTask,
    }) async {
      when(() => repo.getAll()).thenAnswer(
        (_) async => <CategoryModel>[
          CategoryModel(
            id: 'cat-design',
            name: 'Design',
            iconUrl: null,
            createdAt: DateTime.utc(2026, 2, 24),
          ),
        ],
      );
      when(() => vm.currentUserId).thenReturn('user-1');
      when(() => vm.loadCategories()).thenAnswer(
        (_) async => <CategoryModel>[
          CategoryModel(
            id: 'cat-design',
            name: 'Design',
            iconUrl: null,
            createdAt: DateTime.utc(2026, 2, 24),
          ),
        ],
      );
      when(() => vm.categories).thenReturn(<CategoryModel>[
        CategoryModel(
          id: 'cat-design',
          name: 'Design',
          iconUrl: null,
          createdAt: DateTime.utc(2026, 2, 24),
        ),
      ]);
      when(() => vm.categoriesLoading).thenReturn(false);
      when(() => vm.createTask(any())).thenAnswer((_) async => _fallbackTask());
      when(() => vm.updateTask(any(), any())).thenAnswer((_) async {});

      await pumpApp(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TaskViewModel>.value(value: vm),
            Provider<CategoriesRepository>.value(value: repo),
          ],
          child: CreateTaskScreen(task: editTask),
        ),
      );
      await tester.pump();
    }

    testWidgets('T290 step 1 renders initially with task type cards', (
      tester,
    ) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      expect(find.byKey(CreateTaskScreen.tenderTypeCardKey), findsOneWidget);
      expect(find.byKey(CreateTaskScreen.bookingTypeCardKey), findsOneWidget);
      expect(find.text('Tender post'), findsOneWidget);
      expect(find.text('Booking post'), findsOneWidget);
    });

    testWidgets('T291 step 2 shows category selector', (tester) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );
      await advanceToStep2(tester);

      expect(find.text('Category'), findsOneWidget);
      // The mock provides a single Design category
      expect(find.text('Design'), findsOneWidget);
    });

    testWidgets('T292 selecting category enables Next button to advance', (
      tester,
    ) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      await advanceToStep2(tester);

      // Tap the Design category
      await tester.ensureVisible(find.text('Design'));
      await tester.tap(find.text('Design').hitTestable());
      await tester.pump();

      // Tap Continue to advance to review.
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();

      expect(find.text('Review preview'), findsOneWidget);
    });

    testWidgets('T293 step 2 renders title and description fields', (
      tester,
    ) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      await advanceToStep2(tester);

      expect(find.text('Tender title'), findsOneWidget);
      expect(find.text('Tender description'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('Budget (IQD)'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Work type'), findsOneWidget);
      // Hint texts from the source
      expect(
        find.text('e.g., Landing page for clothing brand'),
        findsOneWidget,
      );
      expect(
        find.text('Describe the project freelancers should quote...'),
        findsOneWidget,
      );
    });

    testWidgets(
      'T294 Next from step 2 with empty title/desc shows validation',
      (tester) async {
        await _pumpCreateTaskScreen(
          tester,
          taskVm: taskVm,
          categoriesRepo: categoriesRepo,
        );

        // Advance to step 2
        await advanceToStep2(tester);

        // Advance to step 3 (no validation on step 2 itself)
        await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
        await tester.pump();

        // Now on step 3, tap submit with empty title/desc
        await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
        await tester.pumpAndSettle();

        expect(
          find.text('Please fill in title and description'),
          findsOneWidget,
        );
        verifyNever(() => taskVm.createTask(any()));
      },
    );

    testWidgets('T295 step 2 title field accepts text input', (tester) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      await advanceToStep2(tester);

      // Title is the first TextFormField on step 2
      await tester.enterText(find.byType(TextFormField).at(0), 'My New Task');
      await tester.pump();

      expect(find.text('My New Task'), findsOneWidget);
    });

    testWidgets('T296 step 2 description field accepts text input', (
      tester,
    ) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      await advanceToStep2(tester);

      // Description is the second TextFormField on step 2
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'A detailed description',
      );
      await tester.pump();

      expect(find.text('A detailed description'), findsOneWidget);
    });

    testWidgets('T297 progress bar shows step 1 of 3 initially', (
      tester,
    ) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      // LinearProgressIndicator value should be 1/3 on step 1
      final progressFinder = find.byType(LinearProgressIndicator);
      expect(progressFinder, findsOneWidget);

      final progressWidget = tester.widget<LinearProgressIndicator>(
        progressFinder,
      );
      expect(progressWidget.value, closeTo(1 / 3, 0.01));

      // Step labels should be visible
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('T298 Back button returns to previous step', (tester) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      // Advance to step 2
      await advanceToStep2(tester);
      expect(find.text('Tender title'), findsOneWidget);

      // Back returns to the Type step without discarding entered state.
      await tester.tap(find.text('Back'));
      await tester.pump();

      // Should be back at step 1 with the type cards
      expect(find.text('Create a post'), findsWidgets);
      expect(find.byKey(CreateTaskScreen.tenderTypeCardKey), findsOneWidget);
    });

    testWidgets('T299 tender details step shows budget field', (tester) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      // Tender is selected by default; advance to details.
      await advanceToStep2(tester);

      expect(find.text('Budget (IQD)'), findsOneWidget);
      expect(find.text('Enter amount'), findsOneWidget);
      expect(find.text('Deadline'), findsOneWidget);
    });

    testWidgets('T299a review step renders a live tender preview', (
      tester,
    ) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      await advanceToStep2(tester);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Landing page redesign',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Need a polished storefront.',
      );
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();

      expect(find.text('Review preview'), findsOneWidget);
      expect(find.text('Landing page redesign'), findsOneWidget);
      expect(find.text('TENDER'), findsOneWidget);
    });

    testWidgets('T300 tender deadline chip selection works', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpCreateTaskScreen(
          tester,
          taskVm: taskVm,
          categoriesRepo: categoriesRepo,
        );

        await advanceToStep2(tester);

        // Deadline chips: '3 Days', '1 Week', '2 Weeks', '1 Month'
        expect(find.text('3 Days'), findsOneWidget);
        expect(find.text('1 Week'), findsOneWidget);
        expect(find.text('2 Weeks'), findsOneWidget);
        expect(find.text('1 Month'), findsOneWidget);

        // Tap the '1 Week' chip
        await tester.ensureVisible(find.text('1 Week'));
        await tester.tap(find.text('1 Week'));
        await tester.pump();

        // The chip should still be visible (no crash, selection applied)
        expect(find.text('1 Week'), findsOneWidget);

        final selectedSemantics = tester.getSemantics(
          find.byKey(const ValueKey<String>('create_task_deadline_7')),
        );
        final unselectedSemantics = tester.getSemantics(
          find.byKey(const ValueKey<String>('create_task_deadline_3')),
        );

        expect(
          selectedSemantics.flagsCollection.isSelected,
          ui.Tristate.isTrue,
        );
        expect(
          unselectedSemantics.flagsCollection.isSelected,
          ui.Tristate.isFalse,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('T301 booking details step shows package price field', (
      tester,
    ) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      // Select booking type
      await tester.tap(find.byKey(CreateTaskScreen.bookingTypeCardKey));
      await tester.pump();

      // Advance to details.
      await advanceToStep2(tester);

      expect(find.byKey(CreateTaskScreen.packagePriceFieldKey), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Seniority'), findsOneWidget);
      expect(find.text('Period'), findsOneWidget);
      expect(
        find.byKey(CreateTaskScreen.packageDescriptionFieldKey),
        findsOneWidget,
      );
      expect(find.byKey(CreateTaskScreen.packageTierBasicKey), findsOneWidget);
      expect(
        find.byKey(CreateTaskScreen.packageTierStandardKey),
        findsOneWidget,
      );
      expect(
        find.byKey(CreateTaskScreen.packageTierPremiumKey),
        findsOneWidget,
      );
    });

    testWidgets('T302 final step submit calls vm.createTask', (tester) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      // Advance to step 2
      await advanceToStep2(tester);

      // Fill title and description
      await tester.enterText(find.byType(TextFormField).at(0), 'Valid Title');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Valid Description',
      );
      await tester.enterText(find.byType(TextFormField).at(3), '200');

      // Advance to review.
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();

      // Submit
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pumpAndSettle();

      verify(() => taskVm.createTask(any())).called(1);
    });

    testWidgets('T303 edit mode pre-fills title and description', (
      tester,
    ) async {
      final editTask = Task(
        id: 'task-edit-1',
        title: 'Existing Title',
        description: 'Existing Description',
        budget: 150,
        userId: 'user-1',
        status: TaskStatus.open,
        createdAt: DateTime.utc(2026, 3, 1),
      );

      await pumpEditModeScreen(
        tester,
        vm: taskVm,
        repo: categoriesRepo,
        editTask: editTask,
      );

      // In edit mode the header says 'Edit post'
      expect(find.text('Edit post'), findsOneWidget);

      // Advance to step 2 to see the pre-filled fields
      await advanceToStep2(tester);

      // Title should be pre-filled
      final titleField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(0),
      );
      expect(titleField.controller?.text, 'Existing Title');

      // Description should be pre-filled
      final descField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );
      expect(descField.controller?.text, 'Existing Description');
    });

    testWidgets('T304 close button is present', (tester) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      // The close icon is in the header
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('T305 progress bar updates to step 2 after advancing', (
      tester,
    ) async {
      await _pumpCreateTaskScreen(
        tester,
        taskVm: taskVm,
        categoriesRepo: categoriesRepo,
      );

      // Advance to step 2
      await advanceToStep2(tester);

      final progressWidget = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressWidget.value, closeTo(2 / 3, 0.01));
    });
  });
}
