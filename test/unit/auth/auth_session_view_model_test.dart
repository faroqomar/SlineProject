import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/constants/auth_messages.dart';
import 'package:sline_app/core/models/user_profile.dart';
import 'package:sline_app/features/auth/data/auth_repository.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUser extends Mock implements User {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal [UserProfile] for test assertions.
UserProfile _testProfile({
  String id = 'user-123',
  String fullName = 'Test User',
  String email = 'test@example.com',
}) {
  return UserProfile(id: id, fullName: fullName, email: email);
}

/// Configures [_MockUser] with an id and email.
_MockUser _configuredMockUser({
  String id = 'user-123',
  String email = 'test@example.com',
}) {
  final user = _MockUser();
  when(() => user.id).thenReturn(id);
  when(() => user.email).thenReturn(email);
  return user;
}

void main() {
  // AuthChangeEvent is an enum and may be used with any() in verify calls.
  setUpAll(() {
    registerFallbackValue(AuthChangeEvent.signedIn);
  });

  group('AuthSessionViewModel', () {
    late _MockAuthRepository authRepo;
    late StreamController<AuthState> authStreamController;
    late _MockUser mockUser;

    setUp(() {
      authRepo = _MockAuthRepository();
      authStreamController = StreamController<AuthState>.broadcast(sync: true);
      mockUser = _configuredMockUser();

      // Default: unauthenticated user (no current user).
      when(() => authRepo.currentUser).thenReturn(null);

      // Default: signOut succeeds.
      when(() => authRepo.signOut()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await authStreamController.close();
    });

    // -----------------------------------------------------------------------
    // Helper to build the VM. Pre-configures common stubs BEFORE construction
    // because the constructor calls _initAuthListener + _loadInitialProfile.
    // -----------------------------------------------------------------------

    /// Creates a VM where the user is NOT authenticated.
    AuthSessionViewModel buildUnauthenticatedVM() {
      when(() => authRepo.currentUser).thenReturn(null);
      return AuthSessionViewModel(
        authRepo: authRepo,
        authStateChanges: authStreamController.stream,
      );
    }

    /// Creates a VM where the user IS authenticated and a profile is returned.
    AuthSessionViewModel buildAuthenticatedVM({UserProfile? profile}) {
      final effectiveProfile = profile ?? _testProfile();
      when(() => authRepo.currentUser).thenReturn(mockUser);
      when(
        () => authRepo.getCurrentUserProfileWithRetry(),
      ).thenAnswer((_) async => effectiveProfile);
      return AuthSessionViewModel(
        authRepo: authRepo,
        authStateChanges: authStreamController.stream,
      );
    }

    // =======================================================================
    // Construction & Initial State
    // =======================================================================

    group('Construction & Initial State', () {
      test('constructs without error when user is not authenticated', () {
        final vm = buildUnauthenticatedVM();
        addTearDown(vm.dispose);

        expect(vm.error, isNull);
        expect(vm.currentUserProfile, isNull);
        expect(vm.isAuthenticated, isFalse);
        expect(vm.currentUserId, isNull);
        expect(vm.currentUserEmail, isNull);
        expect(vm.isLoading, isFalse);
      });

      test('constructs and loads profile when user is authenticated', () async {
        final profile = _testProfile();
        final vm = buildAuthenticatedVM(profile: profile);
        addTearDown(vm.dispose);

        // Allow the async _loadInitialProfile to complete.
        await Future<void>.delayed(Duration.zero);

        expect(vm.isAuthenticated, isTrue);
        expect(vm.currentUserId, 'user-123');
        expect(vm.currentUserEmail, 'test@example.com');
        expect(vm.currentUserProfile, isNotNull);
        expect(vm.currentUserProfile!.id, 'user-123');
        expect(vm.currentUserProfile!.fullName, 'Test User');
        expect(vm.error, isNull);
        expect(vm.isLoading, isFalse);
      });

      test('error defaults to null on construction', () {
        final vm = buildUnauthenticatedVM();
        addTearDown(vm.dispose);

        expect(vm.error, isNull);
      });

      test('currentUserProfile defaults to null on construction', () {
        final vm = buildUnauthenticatedVM();
        addTearDown(vm.dispose);

        expect(vm.currentUserProfile, isNull);
      });
    });

    // =======================================================================
    // Auth State Stream
    // =======================================================================

    group('Auth State Stream', () {
      test(
        'signedIn event sets isAuthenticated true and loads profile',
        () async {
          // Start unauthenticated.
          final vm = buildUnauthenticatedVM();
          addTearDown(vm.dispose);

          expect(vm.isAuthenticated, isFalse);
          expect(vm.currentUserProfile, isNull);

          // Now simulate sign-in: stub the repo to return a user and profile.
          final profile = _testProfile();
          when(() => authRepo.currentUser).thenReturn(mockUser);
          when(
            () => authRepo.getCurrentUserProfileWithRetry(),
          ).thenAnswer((_) async => profile);

          authStreamController.add(
            const AuthState(AuthChangeEvent.signedIn, null),
          );

          // Allow the async profile load to complete.
          await Future<void>.delayed(Duration.zero);

          expect(vm.isAuthenticated, isTrue);
          expect(vm.currentUserProfile, isNotNull);
          expect(vm.currentUserProfile!.id, 'user-123');
          expect(vm.isLoading, isFalse);
          verify(() => authRepo.getCurrentUserProfileWithRetry()).called(1);
        },
      );

      test('signedOut event clears profile', () async {
        // Start authenticated with a profile.
        final vm = buildAuthenticatedVM();
        addTearDown(vm.dispose);
        await Future<void>.delayed(Duration.zero);

        expect(vm.currentUserProfile, isNotNull);

        // Simulate sign-out.
        when(() => authRepo.currentUser).thenReturn(null);
        authStreamController.add(
          const AuthState(AuthChangeEvent.signedOut, null),
        );

        // Allow stream handler to process.
        await Future<void>.delayed(Duration.zero);

        expect(vm.currentUserProfile, isNull);
      });

      test('tokenRefreshed event does not reload profile', () async {
        final vm = buildAuthenticatedVM();
        addTearDown(vm.dispose);
        await Future<void>.delayed(Duration.zero);

        // Reset interaction count so we can verify no new call.
        clearInteractions(authRepo);
        when(() => authRepo.currentUser).thenReturn(mockUser);

        authStreamController.add(
          const AuthState(AuthChangeEvent.tokenRefreshed, null),
        );
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => authRepo.getCurrentUserProfileWithRetry());
      });

      test('passwordRecovery event sets pending flag when no callback', () {
        final vm = buildUnauthenticatedVM();
        addTearDown(vm.dispose);

        // No callback registered yet.
        expect(vm.onPasswordRecovery, isNull);

        authStreamController.add(
          const AuthState(AuthChangeEvent.passwordRecovery, null),
        );

        // The pending flag is private, but we can verify it fires when we
        // later set the callback.
        var callbackFired = false;
        vm.onPasswordRecovery = () {
          callbackFired = true;
        };

        expect(
          callbackFired,
          isTrue,
          reason: 'Pending password recovery should fire on callback set',
        );
      });

      test(
        'passwordRecovery event fires callback immediately if registered',
        () {
          final vm = buildUnauthenticatedVM();
          addTearDown(vm.dispose);

          var callbackFired = false;
          vm.onPasswordRecovery = () {
            callbackFired = true;
          };

          authStreamController.add(
            const AuthState(AuthChangeEvent.passwordRecovery, null),
          );

          expect(callbackFired, isTrue);
        },
      );

      test('userUpdated event reloads profile', () async {
        final vm = buildAuthenticatedVM();
        addTearDown(vm.dispose);
        await Future<void>.delayed(Duration.zero);

        // The constructor load already called it once.
        verify(() => authRepo.getCurrentUserProfileWithRetry()).called(1);

        final updatedProfile = _testProfile(fullName: 'Updated Name');
        when(
          () => authRepo.getCurrentUserProfileWithRetry(),
        ).thenAnswer((_) async => updatedProfile);

        authStreamController.add(
          const AuthState(AuthChangeEvent.userUpdated, null),
        );
        await Future<void>.delayed(Duration.zero);

        expect(vm.currentUserProfile!.fullName, 'Updated Name');
        verify(() => authRepo.getCurrentUserProfileWithRetry()).called(1);
      });
    });

    // =======================================================================
    // Profile Loading
    // =======================================================================

    group('Profile Loading', () {
      test('success sets currentUserProfile', () async {
        final profile = _testProfile(fullName: 'Jane Doe');
        final vm = buildAuthenticatedVM(profile: profile);
        addTearDown(vm.dispose);

        await Future<void>.delayed(Duration.zero);

        expect(vm.currentUserProfile, isNotNull);
        expect(vm.currentUserProfile!.fullName, 'Jane Doe');
        expect(vm.error, isNull);
        expect(vm.isLoading, isFalse);
      });

      test(
        'null profile from retry triggers logout and sets profileProvisioningFailed error',
        () async {
          when(() => authRepo.currentUser).thenReturn(mockUser);
          when(
            () => authRepo.getCurrentUserProfileWithRetry(),
          ).thenAnswer((_) async => null);

          final vm = AuthSessionViewModel(
            authRepo: authRepo,
            authStateChanges: authStreamController.stream,
          );
          addTearDown(vm.dispose);

          await Future<void>.delayed(Duration.zero);

          verify(() => authRepo.signOut()).called(1);
          expect(vm.error, AuthMessages.profileProvisioningFailed);
          expect(vm.isLoading, isFalse);
        },
      );

      test(
        'exception during profile fetch triggers logout and sets sessionInvalid error',
        () async {
          when(() => authRepo.currentUser).thenReturn(mockUser);
          when(
            () => authRepo.getCurrentUserProfileWithRetry(),
          ).thenThrow(Exception('network timeout'));

          final vm = AuthSessionViewModel(
            authRepo: authRepo,
            authStateChanges: authStreamController.stream,
          );
          addTearDown(vm.dispose);

          await Future<void>.delayed(Duration.zero);

          verify(() => authRepo.signOut()).called(1);
          expect(vm.error, AuthMessages.sessionInvalid);
          expect(vm.isLoading, isFalse);
        },
      );

      test(
        'uses getCurrentUserProfileWithRetry (not single-attempt method)',
        () async {
          final vm = buildAuthenticatedVM();
          addTearDown(vm.dispose);
          await Future<void>.delayed(Duration.zero);

          verify(() => authRepo.getCurrentUserProfileWithRetry()).called(1);
          verifyNever(() => authRepo.getCurrentUserProfile());
        },
      );

      test('isLoading is true during profile fetch', () async {
        final completer = Completer<UserProfile?>();
        when(() => authRepo.currentUser).thenReturn(mockUser);
        when(
          () => authRepo.getCurrentUserProfileWithRetry(),
        ).thenAnswer((_) => completer.future);

        final vm = AuthSessionViewModel(
          authRepo: authRepo,
          authStateChanges: authStreamController.stream,
        );
        addTearDown(vm.dispose);

        // Give the microtask a chance to start _loadInitialProfile.
        await Future<void>.delayed(Duration.zero);

        expect(vm.isLoading, isTrue);

        // Complete the profile fetch.
        completer.complete(_testProfile());
        await Future<void>.delayed(Duration.zero);

        expect(vm.isLoading, isFalse);
      });
    });

    // =======================================================================
    // Logout
    // =======================================================================

    group('Logout', () {
      test('calls signOut and clears profile', () async {
        final vm = buildAuthenticatedVM();
        addTearDown(vm.dispose);
        await Future<void>.delayed(Duration.zero);

        expect(vm.currentUserProfile, isNotNull);

        when(() => authRepo.currentUser).thenReturn(null);
        await vm.logout();

        verify(() => authRepo.signOut()).called(1);
        expect(vm.currentUserProfile, isNull);
        expect(vm.isLoading, isFalse);
      });

      test('handles signOut failure gracefully without crashing', () async {
        final vm = buildAuthenticatedVM();
        addTearDown(vm.dispose);
        await Future<void>.delayed(Duration.zero);

        when(
          () => authRepo.signOut(),
        ).thenThrow(Exception('network unavailable'));

        // Should not throw.
        await vm.logout();

        expect(vm.isLoading, isFalse);
        // Profile is NOT cleared because signOut threw before the assignment.
        // The catch block absorbs the error gracefully.
      });

      test('logout sets isLoading true then false', () async {
        final signOutCompleter = Completer<void>();
        when(
          () => authRepo.signOut(),
        ).thenAnswer((_) => signOutCompleter.future);

        final vm = buildAuthenticatedVM();
        addTearDown(vm.dispose);
        await Future<void>.delayed(Duration.zero);

        final logoutFuture = vm.logout();

        // isLoading should be true while signOut is pending.
        expect(vm.isLoading, isTrue);

        signOutCompleter.complete();
        await logoutFuture;

        expect(vm.isLoading, isFalse);
      });

      test('logout clears any existing error', () async {
        // Create a VM that fails profile load to produce an error.
        when(() => authRepo.currentUser).thenReturn(mockUser);
        when(
          () => authRepo.getCurrentUserProfileWithRetry(),
        ).thenThrow(Exception('some error'));

        final vm = AuthSessionViewModel(
          authRepo: authRepo,
          authStateChanges: authStreamController.stream,
        );
        addTearDown(vm.dispose);
        await Future<void>.delayed(Duration.zero);

        expect(vm.error, isNotNull);

        // Now logout: signOut was already called by the error path, reset it.
        reset(authRepo);
        when(() => authRepo.currentUser).thenReturn(null);
        when(() => authRepo.signOut()).thenAnswer((_) async {});

        await vm.logout();

        // clearError is called at the start of logout.
        expect(vm.error, isNull);
      });
    });

    // =======================================================================
    // Error & Session Expiry
    // =======================================================================

    group('Error & Session Expiry', () {
      test('clearError sets error to null and notifies listeners', () async {
        // Produce an error state.
        when(() => authRepo.currentUser).thenReturn(mockUser);
        when(
          () => authRepo.getCurrentUserProfileWithRetry(),
        ).thenThrow(Exception('forced error'));

        final vm = AuthSessionViewModel(
          authRepo: authRepo,
          authStateChanges: authStreamController.stream,
        );
        addTearDown(vm.dispose);
        await Future<void>.delayed(Duration.zero);

        expect(vm.error, isNotNull);

        var notified = false;
        vm.addListener(() {
          notified = true;
        });

        vm.clearError();

        expect(vm.error, isNull);
        expect(notified, isTrue);
      });

      test(
        'onSessionExpired consumes pending flag when callback is set after stream error',
        () {
          final vm = buildUnauthenticatedVM();
          addTearDown(vm.dispose);

          // Simulate a stream error (which sets _pendingSessionExpired).
          authStreamController.addError(Exception('stream error'));

          var expiredCallbackFired = false;
          vm.onSessionExpired = () {
            expiredCallbackFired = true;
          };

          expect(
            expiredCallbackFired,
            isTrue,
            reason: 'Pending session expiry should fire on callback set',
          );
        },
      );

      test(
        'onSessionExpired fires immediately when callback already set and stream errors',
        () {
          final vm = buildUnauthenticatedVM();
          addTearDown(vm.dispose);

          var expiredCallbackFired = false;
          vm.onSessionExpired = () {
            expiredCallbackFired = true;
          };

          authStreamController.addError(Exception('stream error'));

          expect(expiredCallbackFired, isTrue);
        },
      );

      test('onPasswordRecovery consumes pending flag', () {
        final vm = buildUnauthenticatedVM();
        addTearDown(vm.dispose);

        // Emit password recovery before callback is registered.
        authStreamController.add(
          const AuthState(AuthChangeEvent.passwordRecovery, null),
        );

        var recoveryFired = false;
        vm.onPasswordRecovery = () {
          recoveryFired = true;
        };

        expect(recoveryFired, isTrue);

        // Setting callback again should NOT re-fire (flag was consumed).
        var secondFire = false;
        vm.onPasswordRecovery = () {
          secondFire = true;
        };

        expect(
          secondFire,
          isFalse,
          reason: 'Pending flag should be consumed after first callback',
        );
      });

      test('setting onSessionExpired to null does not fire pending', () {
        final vm = buildUnauthenticatedVM();
        addTearDown(vm.dispose);

        authStreamController.addError(Exception('stream error'));

        // Setting to null should not throw or fire anything.
        vm.onSessionExpired = null;
        expect(vm.onSessionExpired, isNull);
      });

      test('setting onPasswordRecovery to null does not fire pending', () {
        final vm = buildUnauthenticatedVM();
        addTearDown(vm.dispose);

        authStreamController.add(
          const AuthState(AuthChangeEvent.passwordRecovery, null),
        );

        // Setting to null should not throw or fire anything.
        vm.onPasswordRecovery = null;
        expect(vm.onPasswordRecovery, isNull);
      });
    });

    // =======================================================================
    // Dispose
    // =======================================================================

    group('Dispose', () {
      test('cancels auth subscription on dispose', () async {
        final vm = buildUnauthenticatedVM();

        // Dispose the VM.
        vm.dispose();

        // Emitting after dispose should not cause errors.
        // The controller is still open (tearDown closes it), but the
        // subscription should have been cancelled.
        authStreamController.add(
          const AuthState(AuthChangeEvent.signedIn, null),
        );

        // Allow microtask to settle.
        await Future<void>.delayed(Duration.zero);

        // If subscription were still active, it would try to call
        // _loadInitialProfile which would call getCurrentUserProfileWithRetry.
        // We never stubbed it for the unauthenticated case, so it would fail.
        // No crash = subscription was cancelled.
        verifyNever(() => authRepo.getCurrentUserProfileWithRetry());
      });

      test('stream error after dispose does not crash', () async {
        final vm = buildUnauthenticatedVM();
        vm.dispose();

        // Should not throw.
        authStreamController.addError(Exception('post-dispose error'));
        await Future<void>.delayed(Duration.zero);
      });

      test(
        'multiple auth state events after dispose do not trigger profile loads',
        () async {
          final vm = buildAuthenticatedVM();
          await Future<void>.delayed(Duration.zero);

          // One call from construction.
          verify(() => authRepo.getCurrentUserProfileWithRetry()).called(1);

          vm.dispose();

          // Emit multiple events after dispose.
          authStreamController.add(
            const AuthState(AuthChangeEvent.signedIn, null),
          );
          authStreamController.add(
            const AuthState(AuthChangeEvent.userUpdated, null),
          );
          authStreamController.add(
            const AuthState(AuthChangeEvent.signedOut, null),
          );

          await Future<void>.delayed(Duration.zero);

          // No additional calls should have been made.
          verifyNever(() => authRepo.getCurrentUserProfileWithRetry());
        },
      );
    });

    // =======================================================================
    // Delegate Properties
    // =======================================================================

    group('Delegate Properties', () {
      test('currentUserId delegates to authRepo.currentUser.id', () {
        when(() => authRepo.currentUser).thenReturn(mockUser);
        when(
          () => authRepo.getCurrentUserProfileWithRetry(),
        ).thenAnswer((_) async => _testProfile());

        final vm = AuthSessionViewModel(
          authRepo: authRepo,
          authStateChanges: authStreamController.stream,
        );
        addTearDown(vm.dispose);

        expect(vm.currentUserId, 'user-123');
      });

      test('currentUserEmail delegates to authRepo.currentUser.email', () {
        when(() => authRepo.currentUser).thenReturn(mockUser);
        when(
          () => authRepo.getCurrentUserProfileWithRetry(),
        ).thenAnswer((_) async => _testProfile());

        final vm = AuthSessionViewModel(
          authRepo: authRepo,
          authStateChanges: authStreamController.stream,
        );
        addTearDown(vm.dispose);

        expect(vm.currentUserEmail, 'test@example.com');
      });

      test('isAuthenticated returns false when currentUser is null', () {
        when(() => authRepo.currentUser).thenReturn(null);

        final vm = AuthSessionViewModel(
          authRepo: authRepo,
          authStateChanges: authStreamController.stream,
        );
        addTearDown(vm.dispose);

        expect(vm.isAuthenticated, isFalse);
      });

      test('isAuthenticated returns true when currentUser is present', () {
        when(() => authRepo.currentUser).thenReturn(mockUser);
        when(
          () => authRepo.getCurrentUserProfileWithRetry(),
        ).thenAnswer((_) async => _testProfile());

        final vm = AuthSessionViewModel(
          authRepo: authRepo,
          authStateChanges: authStreamController.stream,
        );
        addTearDown(vm.dispose);

        expect(vm.isAuthenticated, isTrue);
      });
    });
  });
}
