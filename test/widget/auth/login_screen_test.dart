import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/features/auth/data/auth_repository.dart';
import 'package:sline_app/features/auth/view/login_screen.dart';
import 'package:sline_app/features/auth/viewmodels/auth_form_view_model.dart';

import '../../test_support/pump_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

// A fake AuthFormViewModel that allows us to control the outcome of auth operations
class _FakeAuthFormViewModel extends AuthFormViewModel {
  // Changed class name and extends
  bool _isLoading = false;
  String? _error;
  bool shouldSucceed = true; // New property
  String? expectedEmail; // New property
  String? expectedPassword; // New property

  _FakeAuthFormViewModel({
    this.shouldSucceed = true,
    String? initialError,
  }) // Adjusted constructor
  : _error = initialError,
       super(
         authRepo: _MockAuthRepository(),
       ); // AuthFormViewModel requires authRepo

  @override
  bool get isLoading => _isLoading; // New getter implementation

  @override
  String? get error => _error; // New getter implementation

  @override
  Future<bool> login({required String email, required String password}) async {
    // Adjusted method signature
    expectedEmail = email;
    expectedPassword = password;
    _isLoading = true;
    notifyListeners();

    _isLoading = false;
    if (shouldSucceed) {
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error =
          _error ??
          'Invalid credentials'; // Use initialError if provided, otherwise default
      notifyListeners();
      return false;
    }
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
      final fakeAuthVm = _FakeAuthFormViewModel(shouldSucceed: false);

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
      final fakeAuthVm = _FakeAuthFormViewModel(
        shouldSucceed: false,
        initialError: 'ignored',
      );

      await pumpApp(
        tester,
        LoginScreen(authViewModelFactory: () => fakeAuthVm),
      );

      await tester.enterText(
        find.byKey(LoginScreen.emailFieldKey),
        '  test@example.com  ',
      );
      await tester.enterText(
        find.byKey(LoginScreen.passwordFieldKey),
        '  password123  ',
      );
      await tester.tap(find.byKey(LoginScreen.signInButtonKey));
      await tester.pump();

      expect(fakeAuthVm.expectedEmail, 'test@example.com');
      expect(fakeAuthVm.expectedPassword, 'password123');
    });

    testWidgets('T48 successful login navigates to main navigation screen', (
      tester,
    ) async {
      final fakeAuthVm = _FakeAuthFormViewModel(shouldSucceed: true);
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
      final fakeAuthVm = _FakeAuthFormViewModel(
        shouldSucceed: false,
        initialError: 'Invalid login attempt from fake VM',
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

  group('LoginScreen Phase 9 — animations & inline errors', () {
    testWidgets(
      'stagger animation completes and all form fields visible after 600ms',
      (tester) async {
        final fakeAuthVm = _FakeAuthFormViewModel();

        await pumpApp(
          tester,
          LoginScreen(authViewModelFactory: () => fakeAuthVm),
        );

        // Advance past the stagger animation (500ms emphasis + margin)
        await tester.pump(const Duration(milliseconds: 600));

        // All form elements should be fully visible
        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.byKey(LoginScreen.emailFieldKey), findsOneWidget);
        expect(find.byKey(LoginScreen.passwordFieldKey), findsOneWidget);
        expect(find.byKey(LoginScreen.signInButtonKey), findsOneWidget);
        expect(find.text("Don't have an account? "), findsOneWidget);
      },
    );

    testWidgets(
      'inline error appears below fields on empty submit (not in SnackBar)',
      (tester) async {
        final fakeAuthVm = _FakeAuthFormViewModel(shouldSucceed: false);

        await pumpApp(
          tester,
          LoginScreen(authViewModelFactory: () => fakeAuthVm),
        );

        // Let stagger finish
        await tester.pump(const Duration(milliseconds: 600));

        // Tap sign-in with empty fields
        await tester.tap(find.byKey(LoginScreen.signInButtonKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Inline errors should appear (not inside a SnackBar)
        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter your password'), findsOneWidget);

        // Verify they are NOT inside a SnackBar
        expect(
          find.ancestor(
            of: find.text('Please enter your email'),
            matching: find.byType(SnackBar),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('validation check icon appears after entering valid email', (
      tester,
    ) async {
      final fakeAuthVm = _FakeAuthFormViewModel();

      await pumpApp(
        tester,
        LoginScreen(authViewModelFactory: () => fakeAuthVm),
      );

      // Let stagger finish
      await tester.pump(const Duration(milliseconds: 600));

      // Type a valid email
      await tester.enterText(
        find.byKey(LoginScreen.emailFieldKey),
        'test@example.com',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the check_circle icon is present (validation icon)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
