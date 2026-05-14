/// Tests search-screen accessibility semantics for the Amber Dusk tabs.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/features/search/services/search_service.dart';
import 'package:sline_app/features/search/view/search_screen.dart';
import 'package:sline_app/features/search/viewmodels/search_view_model.dart';

class _MockSearchService extends Mock implements SearchService {}

void main() {
  testWidgets('search tabs expose button role and selected state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final viewModel = SearchViewModel(_MockSearchService());
    addTearDown(viewModel.dispose);
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: SearchScreen(viewModel: viewModel),
        ),
      );
      await tester.pump();

      final findWork = tester.getSemantics(
        find.byKey(const ValueKey<String>('search_tab_find_work')),
      );
      final findTalent = tester.getSemantics(
        find.byKey(const ValueKey<String>('search_tab_find_talent')),
      );

      expect(findWork.flagsCollection.isButton, isTrue);
      expect(findWork.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(findTalent.flagsCollection.isButton, isTrue);
      expect(findTalent.flagsCollection.isSelected, ui.Tristate.isFalse);
    } finally {
      semantics.dispose();
    }
  });
}
