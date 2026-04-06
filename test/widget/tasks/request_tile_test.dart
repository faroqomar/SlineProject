/// Widget tests for RequestTile.
///
/// RequestTile is a StatelessWidget that renders a single task request (bid)
/// in a Card. It shows price, delivery days, bidder name, status, action
/// buttons, error messages, and favorite toggle via Consumer of FavoritesViewModel.
///
/// T-numbers: T250 -- T261.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/favorites/viewmodels/favorites_view_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/view/widgets/requests/widgets/request_tile.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

import '../../test_support/pump_app.dart';

// ---------------------------------------------------------------------------
// File-local mocks
// ---------------------------------------------------------------------------
class _MockFavoritesViewModel extends Mock
    with ChangeNotifier
    implements FavoritesViewModel {}

class _MockTaskRequestsViewModel extends Mock
    with ChangeNotifier
    implements TaskRequestsViewModel {}

// ---------------------------------------------------------------------------
// Shared constants and helpers
// ---------------------------------------------------------------------------
const _kTaskId = 'task-100';

TaskRequest _makeRequest({
  String id = 'req-1',
  String bidderId = 'bidder-1',
  int price = 50000,
  int days = 7,
  String? bidderName = 'Ahmed K.',
  OfferStatus status = OfferStatus.pending,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  DateTime? createdAt,
  String? taskTitle,
  DateTime? paymentDeadline,
}) {
  return TaskRequest(
    id: id,
    taskId: _kTaskId,
    bidderId: bidderId,
    price: price,
    days: days,
    status: status,
    paymentStatus: paymentStatus,
    // Recent time so the bid is NOT expired (within 24h)
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 1)),
    bidderName: bidderName,
    taskTitle: taskTitle,
    paymentDeadline: paymentDeadline,
  );
}

/// Pumps a RequestTile wrapped in the necessary providers.
Future<void> _pumpTile(
  WidgetTester tester, {
  required TaskRequest request,
  bool isOwner = true,
  bool isLoading = false,
  VoidCallback? onAccept,
  VoidCallback? onReject,
  String? errorMessage,
  VoidCallback? onRetryError,
  VoidCallback? onDismissError,
  _MockFavoritesViewModel? favoritesVm,
  _MockTaskRequestsViewModel? viewModel,
  String? viewerUserId,
}) async {
  final favVm = favoritesVm ?? _MockFavoritesViewModel();
  when(() => favVm.isPending(any())).thenReturn(false);

  await pumpApp(
    tester,
    ChangeNotifierProvider<FavoritesViewModel>.value(
      value: favVm,
      child: Scaffold(
        body: SingleChildScrollView(
          child: RequestTile(
            request: request,
            isOwner: isOwner,
            isLoading: isLoading,
            onAccept: onAccept,
            onReject: onReject,
            errorMessage: errorMessage,
            onRetryError: onRetryError,
            onDismissError: onDismissError,
            favoritesVM: favVm,
            viewerUserId: viewerUserId,
            viewModel: viewModel,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('RequestTile widget', () {
    // -----------------------------------------------------------------------
    // T250: renders RequestTile widget
    // -----------------------------------------------------------------------
    testWidgets('T250: renders RequestTile widget', (tester) async {
      final request = _makeRequest();
      await _pumpTile(tester, request: request);

      expect(find.byKey(Key('request_tile_${request.id}')), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T251: shows freelancer name from bidderName
    // -----------------------------------------------------------------------
    testWidgets('T251: renders tile with correct key and delivery days', (
      tester,
    ) async {
      final request = _makeRequest(bidderName: 'Sara M.');
      await _pumpTile(tester, request: request);

      // bidderName is not rendered as visible text in RequestTile — it is
      // only used internally for the favorite button and payment summary.
      // This test verifies the tile renders correctly with the expected key
      // and subtitle content.
      expect(find.byKey(Key('request_tile_${request.id}')), findsOneWidget);
      // The subtitle shows days and status text
      expect(find.textContaining('7 days'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T252: shows formatted price
    // -----------------------------------------------------------------------
    testWidgets('T252: shows formatted price', (tester) async {
      // 50000 -> "50K IQD" per PriceFormatter
      final request = _makeRequest(price: 50000);
      await _pumpTile(tester, request: request);

      expect(find.text('50K IQD'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T253: shows delivery days
    // -----------------------------------------------------------------------
    testWidgets('T253: shows delivery days', (tester) async {
      final request = _makeRequest(days: 14);
      await _pumpTile(tester, request: request);

      expect(find.textContaining('14 days'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T254: shows accept/reject buttons when callbacks provided
    // -----------------------------------------------------------------------
    testWidgets('T254: shows accept/reject buttons when callbacks provided', (
      tester,
    ) async {
      final request = _makeRequest(status: OfferStatus.pending);
      await _pumpTile(
        tester,
        request: request,
        isOwner: true,
        onAccept: () {},
        onReject: () {},
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T255: hides accept/reject when callbacks null
    // -----------------------------------------------------------------------
    testWidgets('T255: hides accept/reject when callbacks null', (
      tester,
    ) async {
      final request = _makeRequest(status: OfferStatus.pending);
      await _pumpTile(
        tester,
        request: request,
        isOwner: true,
        onAccept: null,
        onReject: null,
      );

      // Icons.check_circle (green accept) should NOT be present
      expect(find.byIcon(Icons.check_circle), findsNothing);
      // Icons.cancel (red reject) should NOT be present as an action button
      // Note: Icons.cancel may exist from other uses; check via tooltip
      expect(find.byTooltip('Award'), findsNothing);
      expect(find.byTooltip('Reject'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // T256: tapping accept triggers onAccept
    // -----------------------------------------------------------------------
    testWidgets('T256: tapping accept triggers onAccept', (tester) async {
      var acceptCalled = false;
      final request = _makeRequest(status: OfferStatus.pending);
      await _pumpTile(
        tester,
        request: request,
        isOwner: true,
        onAccept: () => acceptCalled = true,
        onReject: () {},
      );

      await tester.tap(find.byTooltip('Award'));
      await tester.pump();

      expect(acceptCalled, isTrue);
    });

    // -----------------------------------------------------------------------
    // T257: tapping reject triggers onReject
    // -----------------------------------------------------------------------
    testWidgets('T257: tapping reject triggers onReject', (tester) async {
      var rejectCalled = false;
      final request = _makeRequest(status: OfferStatus.pending);
      await _pumpTile(
        tester,
        request: request,
        isOwner: true,
        onAccept: () {},
        onReject: () => rejectCalled = true,
      );

      await tester.tap(find.byTooltip('Reject'));
      await tester.pump();

      expect(rejectCalled, isTrue);
    });

    // -----------------------------------------------------------------------
    // T258: shows loading state when isLoading true
    // -----------------------------------------------------------------------
    testWidgets('T258: shows loading state when isLoading true', (
      tester,
    ) async {
      final request = _makeRequest(status: OfferStatus.pending);
      await _pumpTile(
        tester,
        request: request,
        isOwner: true,
        isLoading: true,
        onAccept: () {},
        onReject: () {},
      );

      // When isOwner && isLoading, a CircularProgressIndicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The status label should say "Processing..."
      expect(find.textContaining('Processing...'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T259: shows error message when errorMessage set
    // -----------------------------------------------------------------------
    testWidgets('T259: shows error message when errorMessage set', (
      tester,
    ) async {
      final request = _makeRequest();
      await _pumpTile(
        tester,
        request: request,
        errorMessage: 'Something went wrong',
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // T260: shows retry button when onRetryError provided
    // -----------------------------------------------------------------------
    testWidgets('T260: shows retry button when onRetryError provided', (
      tester,
    ) async {
      var retryCalled = false;
      final mockVm = _MockTaskRequestsViewModel();
      // The retry button is only shown when isRetryableError returns true
      when(() => mockVm.isRetryableError(any())).thenReturn(true);

      final request = _makeRequest();
      await _pumpTile(
        tester,
        request: request,
        errorMessage: 'Network error occurred',
        onRetryError: () => retryCalled = true,
        viewModel: mockVm,
      );

      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retryCalled, isTrue);
    });

    // -----------------------------------------------------------------------
    // T261: awarded offer shows status indicator
    // -----------------------------------------------------------------------
    testWidgets('T261: awarded offer shows status indicator', (tester) async {
      // An accepted + unpaid request shows "Accepted . Awaiting Payment" status
      final request = _makeRequest(
        status: OfferStatus.accepted,
        paymentStatus: PaymentStatus.unpaid,
      );
      await _pumpTile(tester, request: request, isOwner: true);

      expect(find.textContaining('Accepted'), findsWidgets);
    });
  });
}
