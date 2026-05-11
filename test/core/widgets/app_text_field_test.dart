import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';

import 'widget_test_helpers.dart';

void main() {
  group('AppTextField', () {
    testWidgets('T-CW060 renders with hintText', (tester) async {
      await pumpCoreWidget(tester, const AppTextField(hintText: 'Enter name'));
      expect(find.text('Enter name'), findsOneWidget);
    });

    testWidgets('T-CW060a uses Amber Dusk field fill and borderless shape', (
      tester,
    ) async {
      final fieldTheme = AmberDuskTokens.widgetTheme.fields;
      await pumpCoreWidget(tester, const AppTextField(hintText: 'Token field'));

      final inputDecorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      final decoration = inputDecorator.decoration;
      final border = decoration.border! as OutlineInputBorder;

      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, fieldTheme.background);
      expect(decoration.contentPadding, fieldTheme.padding);
      expect(border.borderRadius.topLeft.x, fieldTheme.radius);
      expect(border.borderSide, BorderSide.none);
      expect(editableText.style.fontSize, fieldTheme.textStyle.fontSize);
    });

    testWidgets('T-CW060b renders uppercase Amber Dusk field label', (
      tester,
    ) async {
      final fieldTheme = AmberDuskTokens.widgetTheme.fields;
      await pumpCoreWidget(
        tester,
        const AppTextField(labelText: 'Full name', hintText: 'Enter name'),
      );

      final inputDecorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );

      expect(fieldTheme.labelUppercase, isTrue);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(
        inputDecorator.decoration.labelStyle?.fontSize,
        fieldTheme.labelStyle.fontSize,
      );
      expect(
        inputDecorator.decoration.labelStyle?.fontWeight,
        fieldTheme.labelStyle.fontWeight,
      );
    });

    testWidgets('T-CW061 calls onChanged when text entered', (tester) async {
      String? changedValue;
      await pumpCoreWidget(
        tester,
        AppTextField(hintText: 'Type', onChanged: (v) => changedValue = v),
      );
      await tester.enterText(find.byType(TextFormField), 'hello');
      expect(changedValue, equals('hello'));
    });

    testWidgets('T-CW062 validator shows error', (tester) async {
      final formKey = GlobalKey<FormState>();
      await pumpCoreWidget(
        tester,
        Form(
          key: formKey,
          child: AppTextField(
            hintText: 'Required',
            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
          ),
        ),
      );
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('T-CW063 password toggle switches visibility', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppTextField(
          hintText: 'Password',
          obscureText: true,
          showPasswordToggle: true,
        ),
      );

      // Initially obscured — eye-off icon visible
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Now visible — eye icon shown
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('T-CW064 clear button appears when text entered', (
      tester,
    ) async {
      final controller = TextEditingController();
      await pumpCoreWidget(
        tester,
        AppTextField(
          hintText: 'Clear me',
          controller: controller,
          showClearButton: true,
        ),
      );

      // No clear button when empty
      expect(find.byIcon(Icons.close), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextFormField), 'test');
      await tester.pump();

      // Clear button appears
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap clear
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Field is empty again
      expect(controller.text, isEmpty);
    });

    testWidgets('T-CW065 has Semantics wrapper', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCoreWidget(tester, const AppTextField(hintText: 'Accessible'));
      // TextFormField has built-in semantics + our wrapper adds textField label
      expect(find.byType(Semantics), findsWidgets);
      handle.dispose();
    });

    testWidgets('T-CW066 user suffixIcon takes priority over toggle/clear', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        const AppTextField(
          hintText: 'Custom suffix',
          suffixIcon: Icon(Icons.search),
          showPasswordToggle: true,
          showClearButton: true,
          obscureText: true,
        ),
      );
      // User-provided search icon visible, not eye or clear
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('T-CW067 exposes Amber focus label styling', (tester) async {
      final fieldTheme = AmberDuskTokens.widgetTheme.fields;

      await pumpCoreWidget(
        tester,
        const AppTextField(labelText: 'Title', hintText: 'Title'),
      );
      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      final inputDecorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(
        inputDecorator.decoration.floatingLabelStyle?.color,
        AmberDuskTokens.colors.primary,
      );
      expect(
        inputDecorator.decoration.floatingLabelStyle?.fontSize,
        fieldTheme.labelStyle.fontSize,
      );
    });

    testWidgets('T-CW068 preserves disabled field state', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppTextField(hintText: 'Disabled', enabled: false),
      );

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
    });

    testWidgets('T-CW069 renders Amber counter text', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppTextField(hintText: 'Counter', maxLength: 5),
      );
      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.pump();

      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('T-CW070 accepts long multi-line text without overflow', (
      tester,
    ) async {
      await pumpCoreWidget(
        tester,
        const AppTextField(hintText: 'Long text', maxLines: 2),
      );
      await tester.enterText(
        find.byType(TextFormField),
        'This is a long field value that should remain inside the input area.',
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
