import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/auth/data/auth_repository.dart';
import 'package:sline_app/features/auth/viewmodels/auth_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _testEmail = 'faroqomar97@gmail.com';
const _testPassword = '11223344';

void main() {
  group('AuthViewModel T01-T05', () {
    late _MockAuthRepository authRepo;
    late StreamController<AuthState> authStateController;
    late AuthViewModel viewModel;

    setUp(() {
      authRepo = _MockAuthRepository();
      authStateController = StreamController<AuthState>(sync: true);

      when(
        () => authRepo.getCurrentUserProfile(),
      ).thenAnswer((_) async => <String, dynamic>{'full_name': 'Test User'});

      viewModel = AuthViewModel(
        authRepo: authRepo,
        authStateChanges: authStateController.stream,
      );
    });

    tearDown(() async {
      viewModel.dispose();
      await authStateController.close();
    });

    test('T01 login success sets loading and clears error', () async {
      final loadingStates = <bool>[];

      when(
        () => authRepo.signIn(email: _testEmail, password: _testPassword),
      ).thenAnswer((_) async => AuthResponse());

      viewModel.addListener(() {
        loadingStates.add(viewModel.isLoading);
      });

      final result = await viewModel.login(
        email: _testEmail,
        password: _testPassword,
      );

      expect(result, isTrue);
      expect(viewModel.error, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(loadingStates, contains(true));
      expect(loadingStates.last, isFalse);
      verify(
        () => authRepo.signIn(email: _testEmail, password: _testPassword),
      ).called(1);
      verify(() => authRepo.getCurrentUserProfile()).called(1);
    });

    test('T02 invalid credentials maps friendly message', () async {
      when(
        () => authRepo.signIn(email: _testEmail, password: _testPassword),
      ).thenThrow(Exception('invalid login credentials'));

      final result = await viewModel.login(
        email: _testEmail,
        password: _testPassword,
      );

      expect(result, isFalse);
      expect(viewModel.error, 'Invalid email or password. Please try again.');
      expect(viewModel.isLoading, isFalse);
    });

    test('T03 register duplicate email maps account-exists error', () async {
      when(
        () => authRepo.signUp(
          email: _testEmail,
          password: _testPassword,
          fullName: any(named: 'fullName'),
        ),
      ).thenThrow(Exception('user already registered'));

      final result = await viewModel.register(
        email: _testEmail,
        password: _testPassword,
        fullName: 'Test User',
      );

      expect(result, isFalse);
      expect(viewModel.error, 'An account with this email already exists.');
      expect(viewModel.isLoading, isFalse);
    });

    test('T04 queued session-expired callback fires after callback set', () {
      var callbackCalls = 0;

      authStateController.addError(Exception('session expired'));

      expect(callbackCalls, 0);

      viewModel.onSessionExpired = () {
        callbackCalls += 1;
      };

      expect(callbackCalls, 1);

      viewModel.onSessionExpired = () {
        callbackCalls += 100;
      };

      expect(callbackCalls, 1);
    });

    test('T05 logout failure sets error and resets loading', () async {
      when(() => authRepo.signOut()).thenThrow(Exception('network connection'));

      final result = await viewModel.logout();

      expect(result, isFalse);
      expect(viewModel.error, 'Network error. Please check your connection.');
      expect(viewModel.isLoading, isFalse);
    });
  });
}
