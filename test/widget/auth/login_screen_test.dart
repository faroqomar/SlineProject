import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/features/auth/data/auth_repository.dart';
import 'package:sline_app/features/auth/view/login_screen.dart';
import 'package:sline_app/features/auth/viewmodels/auth_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../test_support/pump_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeAuthViewModel extends AuthViewModel {
  _FakeAuthViewModel({required this.loginResult, this.errorMessage})
    : super(
        authRepo: _MockAuthRepository(),
        authStateChanges: const Stream<AuthState>.empty(),
      );

  final bool loginResult;
  final String? errorMessage;

  String? capturedEmail;
  String? capturedPassword;

  @override
  bool get isLoading => false;

  @override
  String? get error => errorMessage;

  @override
  Future<bool> login({required String email, required String password}) async {
    capturedEmail = email;
    capturedPassword = password;
    return loginResult;
  }
}

class _TestNavigatorObserver extends NavigatorObserver {
  int didReplaceCount = 0;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    didReplaceCount += 1;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

List<Widget> _stubMainNavScreens() {
  return const [
    Center(key: ValueKey('stub_home_screen'), child: Text('Stub Home')),
    Center(child: Text('Stub Tender')),
    Center(child: Text('Stub Booking')),
    Center(child: Text('Stub Dashboard')),
    Center(child: Text('Stub Messages')),
    Center(child: Text('Stub Profile')),
    Center(child: Text('Stub Wallet')),
  ];
}

WidgetBuilder _stubMainNavigationBuilder() {
  return (_) => ChangeNotifierProvider(
    create: (_) => NavigationProvider(),
    child: MainNavigationScreen(screens: _stubMainNavScreens()),
  );
}

void main() {
  group('LoginScreen T46-T49', () {
    testWidgets('T46 form shows required validation messages', (tester) async {
      final fakeAuthVm = _FakeAuthViewModel(loginResult: false);

      await pumpApp(
        tester,
        LoginScreen(authViewModelFactory: () => fakeAuthVm),
      );

      await tester.tap(find.byKey(LoginScreen.signInButtonKey));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('T47 sign-in tap calls login with trimmed email/password', (
      tester,
    ) async {
      final fakeAuthVm = _FakeAuthViewModel(
        loginResult: false,
        errorMessage: 'ignored',
      );

      await pumpApp(
        tester,
        LoginScreen(authViewModelFactory: () => fakeAuthVm),
      );

      await tester.enterText(
        find.byKey(LoginScreen.emailFieldKey),
        '  faroqomar97@gmail.com  ',
      );
      await tester.enterText(
        find.byKey(LoginScreen.passwordFieldKey),
        '  11223344  ',
      );
      await tester.tap(find.byKey(LoginScreen.signInButtonKey));
      await tester.pump();

      expect(fakeAuthVm.capturedEmail, 'faroqomar97@gmail.com');
      expect(fakeAuthVm.capturedPassword, '11223344');
    });

    testWidgets('T48 successful login navigates to main navigation screen', (
      tester,
    ) async {
      final fakeAuthVm = _FakeAuthViewModel(loginResult: true);
      final observer = _TestNavigatorObserver();

      await pumpApp(
        tester,
        LoginScreen(
          authViewModelFactory: () => fakeAuthVm,
          mainNavigationBuilder: _stubMainNavigationBuilder(),
        ),
        navigatorObservers: [observer],
      );

      await tester.enterText(
        find.byKey(LoginScreen.emailFieldKey),
        'faroqomar97@gmail.com',
      );
      await tester.enterText(
        find.byKey(LoginScreen.passwordFieldKey),
        '11223344',
      );
      await tester.tap(find.byKey(LoginScreen.signInButtonKey));
      await tester.pumpAndSettle();

      expect(observer.didReplaceCount, greaterThan(0));
      expect(find.byKey(const ValueKey('stub_home_screen')), findsOneWidget);
    });

    testWidgets('T49 failed login shows snackbar error text', (tester) async {
      final fakeAuthVm = _FakeAuthViewModel(
        loginResult: false,
        errorMessage: 'Invalid login attempt from fake VM',
      );

      await pumpApp(
        tester,
        LoginScreen(
          authViewModelFactory: () => fakeAuthVm,
          mainNavigationBuilder: _stubMainNavigationBuilder(),
        ),
      );

      await tester.enterText(
        find.byKey(LoginScreen.emailFieldKey),
        'faroqomar97@gmail.com',
      );
      await tester.enterText(
        find.byKey(LoginScreen.passwordFieldKey),
        '11223344',
      );
      await tester.tap(find.byKey(LoginScreen.signInButtonKey));
      await tester.pump(); // start snackbar animation
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Invalid login attempt from fake VM'), findsOneWidget);
      expect(find.byKey(const ValueKey('stub_home_screen')), findsNothing);
    });
  });
}
