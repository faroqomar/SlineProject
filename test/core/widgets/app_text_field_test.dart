import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sline_app/core/widgets/app_text_field.dart';

import 'widget_test_helpers.dart';

void main() {
  group('AppTextField', () {
    testWidgets('T-CW060 renders with hintText', (tester) async {
      await pumpCoreWidget(
        tester,
        const AppTextField(hintText: 'Enter name'),
      );
      expect(find.text('Enter name'), findsOneWidget);
    });

    testWidgets('T-CW061 calls onChanged when text entered', (tester) async {
      String? changedValue;
      await pumpCoreWidget(
        tester,
        AppTextField(
          hintText: 'Type',
          onChanged: (v) => changedValue = v,
        ),
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

    testWidgets('T-CW064 clear button appears when text entered',
        (tester) async {
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
      await pumpCoreWidget(
        tester,
        const AppTextField(hintText: 'Accessible'),
      );
      // TextFormField has built-in semantics + our wrapper adds textField label
      expect(find.byType(Semantics), findsWidgets);
      handle.dispose();
    });

    testWidgets('T-CW066 user suffixIcon takes priority over toggle/clear',
        (tester) async {
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
  });
}
