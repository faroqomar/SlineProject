import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/constants/auth_messages.dart';
import 'package:sline_app/core/models/account_guard_state.dart';
import 'package:sline_app/core/models/user_profile.dart';
import 'package:sline_app/features/auth/viewmodels/auth_form_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mock_services.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

UserProfile _testProfile({String id = 'u-1'}) {
  return UserProfile(id: id, fullName: 'Test', email: 'test@x.com');
}

const _activeGuard = AccountGuardState(
  isAuthenticated: true,
  isRevoked: false,
  isRestricted: false,
  accountStatus: 'active',
);

const _bannedGuard = AccountGuardState(
  isAuthenticated: true,
  isRevoked: false,
  isRestricted: true,
  accountStatus: 'banned',
);

const _suspendedGuard = AccountGuardState(
  isAuthenticated: true,
  isRevoked: false,
  isRestricted: true,
  accountStatus: 'suspended',
);

const _revokedGuard = AccountGuardState(
  isAuthenticated: true,
  isRevoked: true,
  isRestricted: false,
  accountStatus: 'active',
);

// ---------------------------------------------------------------------------
// Fake AuthResponse (needed for signIn return type)
// ---------------------------------------------------------------------------

class _FakeAuthResponse extends Fake implements AuthResponse {}

void main() {
  late MockAuthRepository authRepo;
  late MockAccountGuardService guardService;

  setUp(() {
    authRepo = MockAuthRepository();
    guardService = MockAccountGuardService();

    // Default stubs
    when(
      () => authRepo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _FakeAuthResponse());

    when(() => authRepo.signOut()).thenAnswer((_) async {});

    when(
      () => authRepo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        fullName: any(named: 'fullName'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => authRepo.getCurrentUserProfileWithRetry(
        maxRetries: any(named: 'maxRetries'),
        retryDelay: any(named: 'retryDelay'),
      ),
    ).thenAnswer((_) async => _testProfile());

    when(
      () => authRepo.getCurrentUserProfileWithRetry(),
    ).thenAnswer((_) async => _testProfile());

    when(() => authRepo.sendPasswordResetEmail(any())).thenAnswer((_) async {});

    when(() => authRepo.updatePassword(any())).thenAnswer((_) async {});

    when(
      () => guardService.evaluateCurrentUser(),
    ).thenAnswer((_) async => _activeGuard);
  });

  AuthFormViewModel buildVM() {
    return AuthFormViewModel(
      authRepo: authRepo,
      accountGuardService: guardService,
    );
  }

  group('AuthFormViewModel', () {
    // ----- 1. Construction: initial state -----
    test('initial state is not loading and has no error', () {
      final vm = buildVM();
      addTearDown(vm.dispose);

      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
    });

    // ----- 2. signIn happy path -----
    test('login happy path calls signIn and returns true', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      final result = await vm.login(email: 'a@b.com', password: '123456');

      expect(result, isTrue);
      expect(vm.error, isNull);
      verify(
        () => authRepo.signIn(email: 'a@b.com', password: '123456'),
      ).called(1);
    });

    // ----- 3. signIn error sets error state -----
    test('login error sets mapped error message', () async {
      when(
        () => authRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      final vm = buildVM();
      addTearDown(vm.dispose);

      final result = await vm.login(email: 'a@b.com', password: 'wrong');

      expect(result, isFalse);
      expect(vm.error, 'Email or password is incorrect.');
    });

    // ----- 4. signUp happy path -----
    test('register happy path calls signUp and returns true', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      final result = await vm.register(
        email: 'new@x.com',
        password: 'pass1234',
        fullName: 'New User',
      );

      expect(result, isTrue);
      expect(vm.error, isNull);
      verify(
        () => authRepo.signUp(
          email: 'new@x.com',
          password: 'pass1234',
          fullName: 'New User',
        ),
      ).called(1);
    });

    // ----- 5. signUp error sets error state -----
    test('register error sets mapped error message', () async {
      when(
        () => authRepo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          fullName: any(named: 'fullName'),
        ),
      ).thenThrow(const AuthException('Email already registered'));

      final vm = buildVM();
      addTearDown(vm.dispose);

      final result = await vm.register(
        email: 'dup@x.com',
        password: 'pass1234',
        fullName: 'Dup User',
      );

      expect(result, isFalse);
      expect(vm.error, 'An account with this email already exists.');
    });

    // ----- 6. signIn loading state transitions -----
    test('login sets isLoading true during operation', () async {
      final loadingStates = <bool>[];
      final vm = buildVM();
      addTearDown(vm.dispose);

      vm.addListener(() => loadingStates.add(vm.isLoading));

      await vm.login(email: 'a@b.com', password: '123456');

      // _setError(null) fires first (isLoading=false), then _setLoading(true),
      // then the guard/success path, then _setLoading(false) in finally.
      expect(loadingStates, contains(true));
      expect(loadingStates.last, isFalse);
    });

    // ----- 7. signIn with restricted (banned) account -----
    test('login with banned account signs out and sets banned error', () async {
      when(
        () => guardService.evaluateCurrentUser(),
      ).thenAnswer((_) async => _bannedGuard);

      final vm = buildVM();
      addTearDown(vm.dispose);

      final result = await vm.login(email: 'a@b.com', password: '123456');

      expect(result, isFalse);
      expect(vm.error, AuthMessages.accountBanned);
      verify(() => authRepo.signOut()).called(1);
    });

    // ----- 8. signIn with suspended account -----
    test(
      'login with suspended account signs out and sets suspended error',
      () async {
        when(
          () => guardService.evaluateCurrentUser(),
        ).thenAnswer((_) async => _suspendedGuard);

        final vm = buildVM();
        addTearDown(vm.dispose);

        final result = await vm.login(email: 'a@b.com', password: '123456');

        expect(result, isFalse);
        expect(vm.error, AuthMessages.accountSuspended);
        verify(() => authRepo.signOut()).called(1);
      },
    );

    // ----- 9. clearError resets error -----
    test('clearError resets error to null', () async {
      when(
        () => authRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      final vm = buildVM();
      addTearDown(vm.dispose);

      await vm.login(email: 'a@b.com', password: 'wrong');
      expect(vm.error, isNotNull);

      vm.clearError();
      expect(vm.error, isNull);
    });

    // ----- 10. Account guard revoked check on sign in -----
    test(
      'login with revoked session signs out and sets session invalid error',
      () async {
        when(
          () => guardService.evaluateCurrentUser(),
        ).thenAnswer((_) async => _revokedGuard);

        final vm = buildVM();
        addTearDown(vm.dispose);

        final result = await vm.login(email: 'a@b.com', password: '123456');

        expect(result, isFalse);
        expect(vm.error, AuthMessages.sessionInvalid);
        verify(() => authRepo.signOut()).called(1);
      },
    );

    // ----- 11. register with null profile triggers sign out -----
    test('register with null profile returns false and sets error', () async {
      when(
        () => authRepo.getCurrentUserProfileWithRetry(),
      ).thenAnswer((_) async => null);

      final vm = buildVM();
      addTearDown(vm.dispose);

      final result = await vm.register(
        email: 'new@x.com',
        password: 'pass1234',
        fullName: 'User',
      );

      expect(result, isFalse);
      expect(vm.error, AuthMessages.profileProvisioningFailed);
      verify(() => authRepo.signOut()).called(1);
    });

    // ----- 12. resetPassword happy path -----
    test('resetPassword succeeds and returns true', () async {
      final vm = buildVM();
      addTearDown(vm.dispose);

      final result = await vm.resetPassword('a@b.com');

      expect(result, isTrue);
      expect(vm.error, isNull);
      verify(() => authRepo.sendPasswordResetEmail('a@b.com')).called(1);
    });

    // ----- 13. resetPassword error -----
    test('resetPassword error sets error message', () async {
      when(
        () => authRepo.sendPasswordResetEmail(any()),
      ).thenThrow(Exception('Network error'));

      final vm = buildVM();
      addTearDown(vm.dispose);

      final result = await vm.resetPassword('a@b.com');

      expect(result, isFalse);
      expect(vm.error, isNotNull);
    });

    // ----- 14. login clears previous error before starting -----
    test('login clears previous error before starting', () async {
      when(
        () => authRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      final vm = buildVM();
      addTearDown(vm.dispose);

      // First call fails
      await vm.login(email: 'a@b.com', password: 'wrong');
      expect(vm.error, isNotNull);

      // Reset stub to succeed
      when(
        () => authRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _FakeAuthResponse());

      await vm.login(email: 'a@b.com', password: 'right');
      expect(vm.error, isNull);
    });
  });
}
