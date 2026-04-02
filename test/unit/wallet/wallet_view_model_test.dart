import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/features/wallet/models/wallet_activity_model.dart';
import 'package:sline_app/features/wallet/models/wallet_balance_model.dart';
import 'package:sline_app/features/wallet/viewmodels/wallet_view_model.dart';

import '../../helpers/helpers.dart';

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

WalletBalanceModel _balance({
  num available = 5000,
  num pending = 1000,
  num held = 500,
}) {
  return WalletBalanceModel(
    availableBalance: available,
    pendingWithdrawalBalance: pending,
    heldBalance: held,
  );
}

WalletActivityModel _activity({
  required String id,
  required DateTime createdAtUtc,
  String eventType = 'release_with_fee',
  num amountGross = 100,
  num amountNet = 90,
  num feeAmount = 10,
  String currency = 'IQD',
  String? relatedEntityType,
  String? relatedEntityId,
  String? counterpartyUserId,
}) {
  return WalletActivityModel(
    journalEntryId: id,
    createdAtUtc: createdAtUtc,
    eventType: eventType,
    amountGross: amountGross,
    amountNet: amountNet,
    feeAmount: feeAmount,
    currency: currency,
    relatedEntityType: relatedEntityType,
    relatedEntityId: relatedEntityId,
    counterpartyUserId: counterpartyUserId,
  );
}

/// Creates a list of [count] activities with descending timestamps.
List<WalletActivityModel> _activityList(int count, {DateTime? startUtc}) {
  final base = startUtc ?? DateTime.utc(2026, 3, 15, 12);
  return List.generate(
    count,
    (i) => _activity(
      id: 'txn-$i',
      createdAtUtc: base.subtract(Duration(hours: i)),
    ),
  );
}

// ---------------------------------------------------------------------------
// Stub helpers -- wire up repository stubs for common scenarios
// ---------------------------------------------------------------------------

void _stubLoadWalletSuccess(
  MockWalletRepository repo, {
  WalletBalanceModel? balance,
  List<WalletActivityModel>? activities,
}) {
  final txns = activities ?? _activityList(3);
  final bal = balance ?? _balance();

  when(() => repo.getActivity(limit: 20)).thenAnswer((_) async => txns);
  when(() => repo.getWalletBalance()).thenAnswer((_) async => bal);
}

void _stubLoadMoreSuccess(
  MockWalletRepository repo, {
  List<WalletActivityModel>? activities,
}) {
  when(
    () => repo.getActivity(
      limit: 20,
      cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
    ),
  ).thenAnswer((_) async => activities ?? _activityList(5));
}

void _stubWithdrawalSuccess(MockWalletRepository repo) {
  when(
    () => repo.requestWithdrawal(amount: any(named: 'amount')),
  ).thenAnswer((_) async {});
}

void _stubGuardAllowed(MockAccountGuardService guard) {
  when(() => guard.canPerformSensitiveAction()).thenAnswer((_) async => true);
}

void _stubGuardBlocked(MockAccountGuardService guard) {
  when(() => guard.canPerformSensitiveAction()).thenAnswer((_) async => false);
}

/// Stubs all repo calls needed after a successful withdrawal
/// (the VM refreshes balance + activities).
void _stubPostWithdrawalRefresh(
  MockWalletRepository repo, {
  WalletBalanceModel? balance,
  List<WalletActivityModel>? activities,
}) {
  final txns = activities ?? _activityList(3);
  final bal = balance ?? _balance(available: 4000, pending: 2000);

  when(() => repo.getWalletBalance()).thenAnswer((_) async => bal);
  when(() => repo.getActivity(limit: 20)).thenAnswer((_) async => txns);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockWalletRepository repo;
  late MockAccountGuardService guard;
  late WalletViewModel vm;

  setUp(() {
    repo = MockWalletRepository();
    guard = MockAccountGuardService();
    vm = WalletViewModel(repo: repo, accountGuardService: guard);
  });

  tearDown(() {
    vm.dispose();
  });

  // =========================================================================
  // Balance Loading (9 tests)
  // =========================================================================
  group('Balance Loading', () {
    test('loadWallet fetches balance and activities in parallel', () async {
      final expectedBalance =
          _balance(available: 7500, pending: 200, held: 0);
      final expectedActivities = _activityList(5);
      _stubLoadWalletSuccess(
        repo,
        balance: expectedBalance,
        activities: expectedActivities,
      );

      await vm.loadWallet();

      verify(() => repo.getWalletBalance()).called(1);
      verify(() => repo.getActivity(limit: 20)).called(1);
      expect(vm.balance.availableBalance, 7500);
      expect(vm.balance.pendingWithdrawalBalance, 200);
      expect(vm.balance.heldBalance, 0);
      expect(vm.activities.length, 5);
    });

    test(
      'isLoading transitions from false to true and back to false',
      () async {
        _stubLoadWalletSuccess(repo);
        final loadingStates = <bool>[];
        vm.addListener(() => loadingStates.add(vm.isLoading));

        await vm.loadWallet();

        // First notification: isLoading = true, second: isLoading = false
        expect(loadingStates, contains(true));
        expect(loadingStates.last, isFalse);
      },
    );

    test('error is null on successful loadWallet', () async {
      _stubLoadWalletSuccess(repo);

      await vm.loadWallet();

      expect(vm.error, isNull);
    });

    test('hasLoadedWallet is true after successful loadWallet', () async {
      _stubLoadWalletSuccess(repo);

      expect(vm.hasLoadedWallet, isFalse);

      await vm.loadWallet();

      expect(vm.hasLoadedWallet, isTrue);
    });

    test('loadWallet clears previous activities before fetching', () async {
      _stubLoadWalletSuccess(repo, activities: _activityList(2));
      await vm.loadWallet();
      expect(vm.activities.length, 2);

      // Load again with different data
      _stubLoadWalletSuccess(repo, activities: _activityList(4));
      await vm.loadWallet();

      expect(vm.activities.length, 4);
    });

    test('loadWallet resets cursor on reload', () async {
      // First load with 20 items (sets cursor)
      _stubLoadWalletSuccess(repo, activities: _activityList(20));
      await vm.loadWallet();
      expect(vm.hasMore, isTrue);

      // Second load with fewer items (cursor should be reset)
      _stubLoadWalletSuccess(repo, activities: _activityList(3));
      await vm.loadWallet();

      expect(vm.hasMore, isFalse);
      expect(vm.activities.length, 3);
    });

    test('loadWallet sets cursor from last activity timestamp', () async {
      final activities = _activityList(3);
      _stubLoadWalletSuccess(repo, activities: activities);

      await vm.loadWallet();

      // hasMore should be false because 3 < 20
      expect(vm.hasMore, isFalse);
    });

    test(
      'loadWallet sets hasMore true when exactly 20 activities returned',
      () async {
        _stubLoadWalletSuccess(repo, activities: _activityList(20));

        await vm.loadWallet();

        expect(vm.hasMore, isTrue);
      },
    );

    test(
      'loadWallet sets hasMore false when fewer than 20 activities returned',
      () async {
        _stubLoadWalletSuccess(repo, activities: _activityList(5));

        await vm.loadWallet();

        expect(vm.hasMore, isFalse);
      },
    );
  });

  // =========================================================================
  // Deduplication (5 tests)
  // =========================================================================
  group('Deduplication', () {
    test('ensureLoaded called twice only triggers one loadWallet', () async {
      _stubLoadWalletSuccess(repo);

      await vm.ensureLoaded();
      await vm.ensureLoaded();

      verify(() => repo.getWalletBalance()).called(1);
      verify(() => repo.getActivity(limit: 20)).called(1);
    });

    test('forceRefresh bypasses deduplication and reloads', () async {
      _stubLoadWalletSuccess(repo);

      await vm.ensureLoaded();
      await vm.ensureLoaded(forceRefresh: true);

      verify(() => repo.getWalletBalance()).called(2);
      verify(() => repo.getActivity(limit: 20)).called(2);
    });

    test('concurrent ensureLoaded calls share the same future', () async {
      _stubLoadWalletSuccess(repo);

      // Fire two loads concurrently
      final f1 = vm.ensureLoaded();
      final f2 = vm.ensureLoaded();

      await Future.wait([f1, f2]);

      // Only one actual load
      verify(() => repo.getWalletBalance()).called(1);
      verify(() => repo.getActivity(limit: 20)).called(1);
    });

    test('_loadingFuture is null after ensureLoaded completes', () async {
      _stubLoadWalletSuccess(repo);

      await vm.ensureLoaded();

      // A subsequent forceRefresh should trigger a new load (proving
      // _loadingFuture was cleared)
      _stubLoadWalletSuccess(repo, activities: _activityList(1));
      await vm.ensureLoaded(forceRefresh: true);

      verify(() => repo.getWalletBalance()).called(2);
    });

    test(
      '_loadingFuture is null after ensureLoaded completes with error',
      () async {
        when(
          () => repo.getActivity(limit: 20),
        ).thenAnswer((_) async => throw Exception('fail'));
        when(
          () => repo.getWalletBalance(),
        ).thenAnswer((_) async => _balance());

        await vm.ensureLoaded();

        // hasLoadedWallet is false, so ensureLoaded should try again
        _stubLoadWalletSuccess(repo);
        await vm.ensureLoaded();

        // Second call should have triggered a new load
        verify(() => repo.getWalletBalance()).called(2);
      },
    );
  });

  // =========================================================================
  // Pagination (7 tests)
  // =========================================================================
  group('Pagination', () {
    test('loadMore appends new activities to existing list', () async {
      _stubLoadWalletSuccess(repo, activities: _activityList(20));
      await vm.loadWallet();
      expect(vm.activities.length, 20);

      final moreActivities = _activityList(
        5,
        startUtc: DateTime.utc(2026, 3, 14),
      );
      _stubLoadMoreSuccess(repo, activities: moreActivities);

      await vm.loadMore();

      expect(vm.activities.length, 25);
    });

    test('loadMore updates cursor to last returned activity', () async {
      _stubLoadWalletSuccess(repo, activities: _activityList(20));
      await vm.loadWallet();

      final moreActivities = _activityList(
        20,
        startUtc: DateTime.utc(2026, 3, 10),
      );
      _stubLoadMoreSuccess(repo, activities: moreActivities);

      await vm.loadMore();

      // hasMore should still be true because 20 items returned
      expect(vm.hasMore, isTrue);
    });

    test('loadMore sets hasMore false when fewer than 20 returned', () async {
      _stubLoadWalletSuccess(repo, activities: _activityList(20));
      await vm.loadWallet();

      final moreActivities = _activityList(
        10,
        startUtc: DateTime.utc(2026, 3, 10),
      );
      _stubLoadMoreSuccess(repo, activities: moreActivities);

      await vm.loadMore();

      expect(vm.hasMore, isFalse);
    });

    test('loadMore is no-op when hasMore is false', () async {
      _stubLoadWalletSuccess(repo, activities: _activityList(5));
      await vm.loadWallet();
      expect(vm.hasMore, isFalse);

      // Consume the loadWallet call count
      verify(() => repo.getActivity(limit: 20)).called(1);

      await vm.loadMore();

      // No additional getActivity calls should have been made
      verifyNever(() => repo.getActivity(limit: 20));
      verifyNever(
        () => repo.getActivity(
          limit: 20,
          cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
        ),
      );
    });

    test('loadMore is no-op when isLoading is true', () async {
      _stubLoadWalletSuccess(repo, activities: _activityList(20));
      await vm.loadWallet();

      // Consume the loadWallet call count
      verify(() => repo.getActivity(limit: 20)).called(1);

      // Simulate loadMore while another is in progress by setting isLoading
      vm.isLoading = true;

      await vm.loadMore();

      // No additional getActivity calls should have been made
      verifyNever(() => repo.getActivity(limit: 20));
      verifyNever(
        () => repo.getActivity(
          limit: 20,
          cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
        ),
      );
    });

    test('loadMore is no-op when cursor is null', () async {
      // Do not call loadWallet first, so _cursor remains null
      await vm.loadMore();

      verifyNever(
        () => repo.getActivity(
          limit: any(named: 'limit'),
          cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
        ),
      );
    });

    test('loadMore sets error on failure', () async {
      _stubLoadWalletSuccess(repo, activities: _activityList(20));
      await vm.loadWallet();

      when(
        () => repo.getActivity(
          limit: 20,
          cursorCreatedAtIso: any(named: 'cursorCreatedAtIso'),
        ),
      ).thenAnswer((_) async => throw Exception('pagination error'));

      await vm.loadMore();

      expect(vm.error, isNotNull);
      expect(vm.error, contains('pagination error'));
      expect(vm.isLoading, isFalse);
    });
  });

  // =========================================================================
  // Withdrawal (8 tests)
  // =========================================================================
  group('Withdrawal', () {
    test('checks accountGuard before proceeding with withdrawal', () async {
      _stubGuardAllowed(guard);
      _stubWithdrawalSuccess(repo);
      _stubPostWithdrawalRefresh(repo);

      await vm.requestWithdrawal(amount: 1000);

      verify(() => guard.canPerformSensitiveAction()).called(1);
    });

    test('guard blocks withdrawal and returns false with error', () async {
      _stubGuardBlocked(guard);

      final result = await vm.requestWithdrawal(amount: 1000);

      expect(result, isFalse);
      expect(vm.error, 'Your account is restricted. Please contact support.');
      verifyNever(
        () => repo.requestWithdrawal(amount: any(named: 'amount')),
      );
    });

    test(
      'successful withdrawal calls repo, refreshes data, and returns true',
      () async {
        _stubGuardAllowed(guard);
        _stubWithdrawalSuccess(repo);
        final refreshedBalance = _balance(
          available: 4000,
          pending: 2000,
          held: 500,
        );
        final refreshedActivities = _activityList(4);
        _stubPostWithdrawalRefresh(
          repo,
          balance: refreshedBalance,
          activities: refreshedActivities,
        );

        final result = await vm.requestWithdrawal(amount: 1000);

        expect(result, isTrue);
        verify(() => repo.requestWithdrawal(amount: 1000)).called(1);
        // Verify refresh happened
        verify(() => repo.getWalletBalance()).called(1);
        verify(() => repo.getActivity(limit: 20)).called(1);
        expect(vm.balance.availableBalance, 4000);
        expect(vm.balance.pendingWithdrawalBalance, 2000);
        expect(vm.activities.length, 4);
        expect(vm.hasLoadedWallet, isTrue);
        expect(vm.error, isNull);
      },
    );

    test('isWithdrawing transitions correctly during withdrawal', () async {
      _stubGuardAllowed(guard);
      _stubWithdrawalSuccess(repo);
      _stubPostWithdrawalRefresh(repo);

      final withdrawingStates = <bool>[];
      vm.addListener(() => withdrawingStates.add(vm.isWithdrawing));

      await vm.requestWithdrawal(amount: 500);

      // First notification: isWithdrawing = true, last: isWithdrawing = false
      expect(withdrawingStates.first, isTrue);
      expect(withdrawingStates.last, isFalse);
    });

    test('withdrawal Exception sets generic error message', () async {
      _stubGuardAllowed(guard);
      when(
        () => repo.requestWithdrawal(amount: any(named: 'amount')),
      ).thenAnswer((_) async => throw Exception('server error'));

      final result = await vm.requestWithdrawal(amount: 1000);

      expect(result, isFalse);
      expect(vm.error, 'Failed to request withdrawal. Please try again.');
      expect(vm.isWithdrawing, isFalse);
    });

    test('FormatException produces specific error message', () async {
      _stubGuardAllowed(guard);
      when(
        () => repo.requestWithdrawal(amount: any(named: 'amount')),
      ).thenAnswer(
        (_) async => throw const FormatException('Minimum withdrawal is 5000 IQD'),
      );

      final result = await vm.requestWithdrawal(amount: 100);

      expect(result, isFalse);
      expect(vm.error, 'Minimum withdrawal is 5000 IQD');
      expect(vm.isWithdrawing, isFalse);
    });

    test('isWithdrawing is false after guard blocks withdrawal', () async {
      _stubGuardBlocked(guard);

      await vm.requestWithdrawal(amount: 1000);

      expect(vm.isWithdrawing, isFalse);
    });

    test('withdrawal clears previous error before starting', () async {
      // Set an initial error state
      _stubGuardBlocked(guard);
      await vm.requestWithdrawal(amount: 1000);
      expect(vm.error, isNotNull);

      // Now attempt again -- error should be null at start
      String? errorDuringFirstNotification;
      var firstNotification = true;
      vm.addListener(() {
        if (firstNotification) {
          errorDuringFirstNotification = vm.error;
          firstNotification = false;
        }
      });

      _stubGuardAllowed(guard);
      _stubWithdrawalSuccess(repo);
      _stubPostWithdrawalRefresh(repo);
      await vm.requestWithdrawal(amount: 500);

      expect(errorDuringFirstNotification, isNull);
    });
  });

  // =========================================================================
  // Error & Summary (7 tests)
  // =========================================================================
  group('Error & Summary', () {
    test('loadWallet failure sets error and isLoading false', () async {
      when(
        () => repo.getActivity(limit: 20),
      ).thenAnswer((_) async => throw Exception('timeout'));
      when(
        () => repo.getWalletBalance(),
      ).thenAnswer((_) async => _balance());

      await vm.loadWallet();

      expect(vm.error, isNotNull);
      expect(vm.error, contains('timeout'));
      expect(vm.isLoading, isFalse);
    });

    test('clearError sets error to null and notifies listeners', () async {
      // Create an error state first
      when(
        () => repo.getActivity(limit: 20),
      ).thenAnswer((_) async => throw Exception('some error'));
      when(
        () => repo.getWalletBalance(),
      ).thenAnswer((_) async => _balance());
      await vm.loadWallet();
      expect(vm.error, isNotNull);

      var notified = false;
      vm.addListener(() => notified = true);

      vm.clearError();

      expect(vm.error, isNull);
      expect(notified, isTrue);
    });

    test('summary getter returns valid summary with zero balance', () {
      // vm is freshly created with WalletBalanceModel.zero() and empty
      // activities
      final summary = vm.summary;

      expect(summary.totalFunds, 0.0);
      expect(summary.availableFunds, 0.0);
      expect(summary.pendingWithdrawalFunds, 0.0);
      expect(summary.heldFunds, 0.0);
      expect(summary.hasActivity, isFalse);
      expect(summary.activityCaption, 'No recent wallet activity yet');
      expect(summary.balanceSlices.length, 3);
      // All ratios should be 0 when total is 0
      for (final slice in summary.balanceSlices) {
        expect(slice.ratio, 0.0);
      }
    });

    test('summary getter reflects loaded balance and activities', () async {
      _stubLoadWalletSuccess(
        repo,
        balance: _balance(available: 3000, pending: 1000, held: 500),
        activities: _activityList(5),
      );

      await vm.loadWallet();

      final summary = vm.summary;
      expect(summary.totalFunds, 4500.0);
      expect(summary.availableFunds, 3000.0);
      expect(summary.pendingWithdrawalFunds, 1000.0);
      expect(summary.heldFunds, 500.0);
      expect(summary.hasActivity, isTrue);
      expect(summary.activityCaption, contains('5'));
    });

    test('loadWallet with empty activities sets correct state', () async {
      _stubLoadWalletSuccess(
        repo,
        balance: _balance(available: 0, pending: 0, held: 0),
        activities: [],
      );

      await vm.loadWallet();

      expect(vm.activities, isEmpty);
      expect(vm.hasMore, isFalse);
      expect(vm.hasLoadedWallet, isTrue);
      expect(vm.error, isNull);
    });

    test('loadWallet error preserves zero balance default', () async {
      when(
        () => repo.getActivity(limit: 20),
      ).thenAnswer((_) async => throw Exception('failure'));
      when(
        () => repo.getWalletBalance(),
      ).thenAnswer((_) async => _balance());

      await vm.loadWallet();

      // Future.wait throws on the first error, so the assignment in the try
      // block never runs and balance remains the default zero()
      expect(vm.error, isNotNull);
      expect(vm.balance.availableBalance, 0);
      expect(vm.balance.pendingWithdrawalBalance, 0);
      expect(vm.balance.heldBalance, 0);
    });

    test('hasLoadedWallet is false after failed loadWallet', () async {
      when(
        () => repo.getActivity(limit: 20),
      ).thenAnswer((_) async => throw Exception('network error'));
      when(
        () => repo.getWalletBalance(),
      ).thenAnswer((_) async => _balance());

      await vm.loadWallet();

      expect(vm.hasLoadedWallet, isFalse);
    });
  });
}
