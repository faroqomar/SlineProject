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
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();

      await tester.enterText(
        find.byKey(CreateTaskScreen.packagePriceFieldKey),
        '50',
      );
      await tester.enterText(
        find.byKey(CreateTaskScreen.packageDescriptionFieldKey),
        'Basic package description',
      );

      await tester.tap(find.byKey(CreateTaskScreen.packageTierStandardKey));
      await tester.pump();
      await tester.enterText(
        find.byKey(CreateTaskScreen.packagePriceFieldKey),
        '90',
      );
      await tester.enterText(
        find.byKey(CreateTaskScreen.packageDescriptionFieldKey),
        'Standard package description',
      );

      await tester.tap(find.byKey(CreateTaskScreen.packageTierBasicKey));
      await tester.pump();
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

      await tester.tap(find.byKey(CreateTaskScreen.packageTierStandardKey));
      await tester.pump();
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

      await tester.tap(find.text('Design').first);
      await tester.pump();
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'Task title');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Task description',
      );
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.tap(find.byKey(CreateTaskScreen.primaryActionButtonKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
