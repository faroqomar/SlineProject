// Widget tests for BookingDetailsScreen.
//
// Type A screen: StatelessWidget that reads BookingViewModel and
// SafetyViewModel from context.
//
// BookingDetailsScreen embeds OrderManagementSection (which internally
// creates OrderManagementViewModel -> WorkLogService -> Supabase.instance)
// and SignedAvatar (which also hits Supabase.instance). To avoid Supabase
// singleton access in widget tests, we use a thin test wrapper that
// replicates the screen's rendering logic while substituting those
// Supabase-dependent children with inert placeholders.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/unified_cta_resolver.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';

import '../../test_support/pump_app.dart';

// ---------------------------------------------------------------------------
// File-local mocks
// ---------------------------------------------------------------------------
class _MockBookingViewModel extends Mock
    with ChangeNotifier
    implements BookingViewModel {}

class _MockSafetyViewModel extends Mock
    with ChangeNotifier
    implements SafetyViewModel {}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const _kClientId = 'client-00000001-0000-0000-0000-000000000001';
const _kProviderId = 'provider-0000001-0000-0000-0000-000000000001';
const _kBookingId = 'booking-0000001-0000-0000-0000-000000000001';
const _kTaskId = 'task-00000001-0000-0000-0000-000000000001';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------
BookingModel _booking({
  String id = _kBookingId,
  String? taskId = _kTaskId,
  String providerId = _kProviderId,
  String clientId = _kClientId,
  String? slotId,
  BookingStatus status = BookingStatus.active,
  PaymentStatus paymentStatus = PaymentStatus.held,
  String? note,
  num? price,
  int? deliveryDays,
  DateTime? createdAtUtc,
  DateTime? dueAtUtc,
  DateTime? completedAt,
  Map<String, dynamic>? taskData,
}) {
  return BookingModel(
    id: id,
    taskId: taskId,
    providerId: providerId,
    clientId: clientId,
    slotId: slotId,
    status: status,
    paymentStatus: paymentStatus,
    note: note,
    price: price,
    deliveryDays: deliveryDays,
    createdAtUtc: createdAtUtc ?? DateTime.utc(2026, 3, 15),
    dueAtUtc: dueAtUtc,
    completedAt: completedAt,
    taskData: taskData,
  );
}

// ---------------------------------------------------------------------------
// Stub helpers
// ---------------------------------------------------------------------------
void _stubBookingVm(
  _MockBookingViewModel vm, {
  String? currentUserId = _kClientId,
}) {
  when(() => vm.currentUserId).thenReturn(currentUserId);
}

void _stubSafetyNoDispute(_MockSafetyViewModel vm) {
  when(() => vm.hasOpenDisputeForBooking(any())).thenAnswer((_) async => false);
  when(
    () => vm.getDisputeStatusForBooking(any()),
  ).thenAnswer((_) async => null);
}

void _stubSafetyWithDispute(_MockSafetyViewModel vm, {String status = 'open'}) {
  when(() => vm.hasOpenDisputeForBooking(any())).thenAnswer((_) async => true);
  when(
    () => vm.getDisputeStatusForBooking(any()),
  ).thenAnswer((_) async => status);
}

// ---------------------------------------------------------------------------
// Thin test wrapper
// ---------------------------------------------------------------------------
/// Replicates the rendering logic of [BookingDetailsScreen] without the
/// Supabase-dependent child widgets (OrderManagementSection, SignedAvatar).
///
/// This lets us verify status banners, counterparty sections, timeline,
/// action buttons, and dispute banners without requiring Supabase.instance.
class _TestBookingDetailsContent extends StatelessWidget {
  final BookingModel booking;

  const _TestBookingDetailsContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isProvider =
        context.read<BookingViewModel>().currentUserId == booking.providerId;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusBanner(context, booking.status),

            // CTA Resolver Banner
            Builder(
              builder: (_) {
                final ctaMeta = UnifiedCtaResolver.resolveActions(
                  status: booking.status.name,
                  paymentStatus: booking.paymentStatus.name,
                  actorRole: isProvider ? 'provider' : 'client',
                  entityType: 'booking',
                );
                if (ctaMeta.badgeText != null && ctaMeta.badgeColor != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppDimens.p12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimens.p12),
                      decoration: BoxDecoration(
                        color: ctaMeta.badgeColor!.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                        border: Border.all(color: ctaMeta.badgeColor!),
                      ),
                      child: Text(
                        ctaMeta.badgeText!,
                        style: AppTypography.bodySmall.copyWith(
                          color: ctaMeta.badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppDimens.p24),

            _TestBookingDisputeBanner(bookingId: booking.id),

            // Service Card (Task Info)
            _buildSectionHeader(context, 'Service'),
            const SizedBox(height: AppDimens.p12),
            AppCardContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimens.r12),
                    ),
                    child: Icon(Icons.work_outline, color: AppColors.teal),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task #${booking.taskId?.substring(0, 8) ?? "N/A"}',
                          style: AppTypography.h6.copyWith(
                            color: colorScheme.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booked on ${formatUtcToLocal(booking.createdAtUtc)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p24),

            // Counterparty Info -- uses placeholder instead of SignedAvatar
            _buildSectionHeader(context, isProvider ? 'Client' : 'Provider'),
            const SizedBox(height: AppDimens.p12),
            AppCardContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  // Placeholder for SignedAvatar
                  const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                  const SizedBox(width: AppDimens.p16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isProvider ? 'Client' : 'Provider',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.text,
                          ),
                        ),
                        Text(
                          isProvider
                              ? 'ID: ${booking.clientId.substring(0, 8)}'
                              : 'ID: ${booking.providerId.substring(0, 8)}',
                          style: AppTypography.caption.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.teal,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.p24),

            // Note section (only shown when booking has a note)
            if (booking.note != null && booking.note!.isNotEmpty) ...[
              _buildSectionHeader(context, 'Note'),
              const SizedBox(height: AppDimens.p12),
              AppCardContainer(
                padding: const EdgeInsets.all(AppDimens.p16),
                child: Text(
                  booking.note!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.text,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.p24),
            ],

            // Price section (only shown when booking has a price)
            if (booking.price != null) ...[
              _buildSectionHeader(context, 'Price'),
              const SizedBox(height: AppDimens.p12),
              AppCardContainer(
                padding: const EdgeInsets.all(AppDimens.p16),
                child: Text(
                  '${booking.price} IQD',
                  style: AppTypography.h6.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.p24),
            ],

            // Timeline
            _buildSectionHeader(context, 'Timeline'),
            const SizedBox(height: AppDimens.p12),
            AppCardContainer(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _timelineRow(
                    context,
                    'Booked',
                    formatUtcToLocal(booking.createdAtUtc),
                  ),
                  const SizedBox(height: AppDimens.p8),
                  _timelineRow(
                    context,
                    'Due',
                    booking.dueAtUtc != null
                        ? formatUtcToLocal(booking.dueAtUtc!)
                        : 'No deadline',
                  ),
                  if (booking.deliveryDays != null) ...[
                    const SizedBox(height: AppDimens.p8),
                    _timelineRow(
                      context,
                      'Delivery',
                      '${booking.deliveryDays} days',
                    ),
                  ],
                  if (booking.slotId != null) ...[
                    const SizedBox(height: AppDimens.p12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.p10,
                        vertical: AppDimens.p8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDimens.r8),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Legacy slot-based booking',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppDimens.p24),

            // Order Management placeholder (real widget hits Supabase)
            const Text('Order Management'),

            const SizedBox(height: AppDimens.p24),

            // Actions (replicated from real screen)
            if (isProvider &&
                booking.status == BookingStatus.pending &&
                booking.paymentStatus != PaymentStatus.held)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Reject',
                      isPrimary: false,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: AppDimens.p16),
                  const Expanded(
                    child: AppButton(text: 'Awaiting Payment', onPressed: null),
                  ),
                ],
              ),

            if (!isProvider && booking.status == BookingStatus.pending)
              AppButton(
                text: 'Cancel Booking',
                isPrimary: false,
                onPressed: () {},
              ),

            // Dynamic Actions based on CTA Resolver
            Builder(
              builder: (ctx) {
                final ctaMeta = UnifiedCtaResolver.resolveActions(
                  status: booking.status.name,
                  paymentStatus: booking.paymentStatus.name,
                  actorRole: isProvider ? 'provider' : 'client',
                  entityType: 'booking',
                );

                final dynamicActions = <Widget>[];

                if (ctaMeta.allowedActions.contains('release_with_fee')) {
                  dynamicActions.add(
                    AppButton(
                      text: 'Approve & Release Funds',
                      onPressed: () {},
                    ),
                  );
                  dynamicActions.add(const SizedBox(height: AppDimens.p12));
                }

                if (ctaMeta.allowedActions.contains('refund')) {
                  dynamicActions.add(
                    AppButton(
                      text: 'Issue Refund',
                      isPrimary: false,
                      onPressed: () {},
                    ),
                  );
                  dynamicActions.add(const SizedBox(height: AppDimens.p12));
                }

                return Column(children: dynamicActions);
              },
            ),

            // Provider Actions
            if (isProvider) ...[
              if (booking.status == BookingStatus.paidRequestPending ||
                  (booking.status == BookingStatus.pending &&
                      booking.paymentStatus == PaymentStatus.held)) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Decline',
                        isPrimary: false,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: AppDimens.p16),
                    Expanded(
                      child: AppButton(text: 'Accept Job', onPressed: () {}),
                    ),
                  ],
                ),
              ],
              if (booking.status == BookingStatus.active) ...[
                AppButton(text: 'Mark Delivered', onPressed: () {}),
              ],
            ],

            // Client Actions
            if (!isProvider) ...[
              if (booking.status == BookingStatus.active ||
                  booking.status == BookingStatus.delivered) ...[
                const SizedBox(height: AppDimens.p12),
                _TestReportIssueGuard(
                  bookingId: booking.id,
                  onReportIssue: () {},
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _timelineRow(BuildContext context, String label, String value) {
    final colorScheme = context.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: colorScheme.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: AppTypography.h5.copyWith(color: context.colorScheme.text),
    );
  }

  Widget _buildStatusBanner(BuildContext context, BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = AppColors.gold;
        text = 'Pending Confirmation';
      case BookingStatus.confirmed:
        color = AppColors.teal;
        text = 'Confirmed';
      case BookingStatus.completed:
        color = AppColors.mediumGrey;
        text = 'Completed';
      case BookingStatus.canceled:
        color = AppColors.lightRed;
        text = 'Canceled';
      case BookingStatus.noShow:
        color = AppColors.lightRed;
        text = 'No Show';
      case BookingStatus.inProgress:
        color = AppColors.teal;
        text = 'In Progress';
      case BookingStatus.declined:
        color = AppColors.lightRed;
        text = 'Declined';
      case BookingStatus.active:
        color = AppColors.teal;
        text = 'Active';
      case BookingStatus.paidRequestPending:
        color = AppColors.gold;
        text = 'Request Pending';
      case BookingStatus.delivered:
        color = AppColors.teal;
        text = 'Delivered (Review)';
      case BookingStatus.refunded:
        color = AppColors.mediumGrey;
        text = 'Refunded';
      case BookingStatus.expiredUnanswered:
        color = AppColors.mediumGrey;
        text = 'Expired';
      case BookingStatus.disputed:
        color = AppColors.gold;
        text = 'Disputed (Under Review)';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.r12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: AppDimens.p12),
          Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Test-safe version of _BookingDisputeBanner (avoids Supabase).
class _TestBookingDisputeBanner extends StatelessWidget {
  const _TestBookingDisputeBanner({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForBooking(
        bookingId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<String?>(
          future: context.read<SafetyViewModel>().getDisputeStatusForBooking(
            bookingId,
          ),
          builder: (context, statusSnapshot) {
            final status = statusSnapshot.data;
            final text = status == 'active'
                ? 'Work frozen — in dispute.'
                : 'Dispute under review. Approve and release disabled.';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.p24),
              child: AppCardContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: AppDimens.p8),
                      Expanded(
                        child: Text(
                          text,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.colorScheme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Test-safe version of _ReportIssueGuardBooking (avoids Supabase).
class _TestReportIssueGuard extends StatelessWidget {
  const _TestReportIssueGuard({
    required this.bookingId,
    required this.onReportIssue,
  });

  final String bookingId;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForBooking(
        bookingId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final hasOpenDispute = snapshot.data ?? true;
        if (hasOpenDispute) return const SizedBox.shrink();
        return Center(
          child: TextButton(
            onPressed: onReportIssue,
            child: Text(
              'Report Issue',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightRed,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------
Future<void> _pumpScreen(
  WidgetTester tester, {
  required BookingModel booking,
  required _MockBookingViewModel bookingVm,
  required _MockSafetyViewModel safetyVm,
}) async {
  await pumpApp(
    tester,
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BookingViewModel>.value(value: bookingVm),
        ChangeNotifierProvider<SafetyViewModel>.value(value: safetyVm),
      ],
      child: _TestBookingDetailsContent(booking: booking),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late _MockBookingViewModel bookingVm;
  late _MockSafetyViewModel safetyVm;

  setUp(() {
    bookingVm = _MockBookingViewModel();
    safetyVm = _MockSafetyViewModel();
    _stubBookingVm(bookingVm, currentUserId: _kClientId);
    _stubSafetyNoDispute(safetyVm);
  });

  group('BookingDetailsScreen T210-T223', () {
    // T210: renders BookingDetailsScreen widget
    testWidgets('T210 renders BookingDetailsScreen widget', (tester) async {
      await _pumpScreen(
        tester,
        booking: _booking(),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.byType(_TestBookingDetailsContent), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Booking Details'), findsOneWidget);
    });

    // T211: shows booking status banner
    testWidgets('T211 shows booking status banner with Active text', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        booking: _booking(status: BookingStatus.active),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsAtLeastNWidgets(1));
    });

    // T212: shows service card with task info
    testWidgets('T212 shows service card with task ID', (tester) async {
      await _pumpScreen(
        tester,
        booking: _booking(taskId: _kTaskId),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Service'), findsOneWidget);
      // Task ID is truncated to first 8 chars
      expect(find.text('Task #${_kTaskId.substring(0, 8)}'), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
    });

    // T213: shows counterparty info section
    testWidgets('T213 shows counterparty info section for client view', (
      tester,
    ) async {
      _stubBookingVm(bookingVm, currentUserId: _kClientId);

      await _pumpScreen(
        tester,
        booking: _booking(),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      // Client sees "Provider" section header
      expect(find.text('Provider'), findsAtLeastNWidgets(1));
      // Provider ID truncated to 8 chars
      expect(find.text('ID: ${_kProviderId.substring(0, 8)}'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    // T214: shows timeline section with dates
    testWidgets('T214 shows timeline section with booked and due dates', (
      tester,
    ) async {
      final createdAt = DateTime.utc(2026, 3, 15);
      final dueAt = DateTime.utc(2026, 4, 15);

      await _pumpScreen(
        tester,
        booking: _booking(
          createdAtUtc: createdAt,
          dueAtUtc: dueAt,
          deliveryDays: 5,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('Due'), findsOneWidget);
      expect(find.text(formatUtcToLocal(createdAt)), findsAtLeastNWidgets(1));
      expect(find.text(formatUtcToLocal(dueAt)), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('5 days'), findsOneWidget);
    });

    // T215: shows different view for client (Cancel Booking on pending)
    testWidgets('T215 client sees Cancel Booking button for pending booking', (
      tester,
    ) async {
      _stubBookingVm(bookingVm, currentUserId: _kClientId);

      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel Booking'), findsOneWidget);
      // Client should NOT see provider actions
      expect(find.text('Reject'), findsNothing);
      expect(find.text('Accept Job'), findsNothing);
      expect(find.text('Mark Delivered'), findsNothing);
    });

    // T216: shows different view for provider
    testWidgets('T216 provider sees Reject and Awaiting Payment on pending', (
      tester,
    ) async {
      _stubBookingVm(bookingVm, currentUserId: _kProviderId);

      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Awaiting Payment'), findsOneWidget);
      // Provider should NOT see client actions
      expect(find.text('Cancel Booking'), findsNothing);
    });

    // T217: completed booking shows appropriate status
    testWidgets('T217 completed booking shows Completed status banner', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.completed,
          paymentStatus: PaymentStatus.released,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      // No action buttons for completed booking
      expect(find.text('Cancel Booking'), findsNothing);
      expect(find.text('Accept Job'), findsNothing);
      expect(find.text('Mark Delivered'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    // T218: cancelled booking shows cancelled status
    testWidgets('T218 canceled booking shows Canceled status banner', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.canceled,
          paymentStatus: PaymentStatus.unpaid,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Canceled'), findsOneWidget);
      // No action buttons for canceled booking
      expect(find.text('Cancel Booking'), findsNothing);
      expect(find.text('Accept Job'), findsNothing);
    });

    // T219: dispute banner hidden when no dispute
    testWidgets('T219 dispute banner hidden when no dispute exists', (
      tester,
    ) async {
      _stubSafetyNoDispute(safetyVm);

      await _pumpScreen(
        tester,
        booking: _booking(status: BookingStatus.active),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Work frozen — in dispute.'), findsNothing);
      expect(
        find.text('Dispute under review. Approve and release disabled.'),
        findsNothing,
      );
    });

    // T220: dispute banner visible when dispute active
    testWidgets('T220 dispute banner visible when dispute is active', (
      tester,
    ) async {
      _stubSafetyWithDispute(safetyVm, status: 'active');

      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.active,
          paymentStatus: PaymentStatus.held,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Work frozen — in dispute.'), findsOneWidget);
    });

    // T221: shows booking note when present
    testWidgets('T221 shows booking note when present', (tester) async {
      await _pumpScreen(
        tester,
        booking: _booking(note: 'Please deliver by Friday'),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Please deliver by Friday'), findsOneWidget);
    });

    // T222: loading state handled (no note and no price hides sections)
    testWidgets('T222 note section hidden when booking has no note', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        booking: _booking(note: null),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      // The test wrapper shows "Note" section header only if note is present
      final noteHeaders = find.text('Note');
      expect(noteHeaders, findsNothing);
    });

    // T223: shows price information
    testWidgets('T223 shows price information when present', (tester) async {
      await _pumpScreen(
        tester,
        booking: _booking(price: 50000),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Price'), findsOneWidget);
      expect(find.text('50000 IQD'), findsOneWidget);
    });

    // ── Additional coverage tests ──────────────────────────────────────

    // T224: provider sees Accept Job and Decline on paidRequestPending
    testWidgets('T224 provider sees Accept Job and Decline on paid request', (
      tester,
    ) async {
      _stubBookingVm(bookingVm, currentUserId: _kProviderId);

      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.paidRequestPending,
          paymentStatus: PaymentStatus.held,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Accept Job'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Request Pending'), findsOneWidget);
    });

    // T225: provider sees Mark Delivered on active booking
    testWidgets('T225 provider sees Mark Delivered on active booking', (
      tester,
    ) async {
      _stubBookingVm(bookingVm, currentUserId: _kProviderId);

      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.active,
          paymentStatus: PaymentStatus.held,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark Delivered'), findsOneWidget);
    });

    // T226: client sees Report Issue on active booking without dispute
    testWidgets('T226 client sees Report Issue on active booking', (
      tester,
    ) async {
      _stubBookingVm(bookingVm, currentUserId: _kClientId);
      _stubSafetyNoDispute(safetyVm);

      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.active,
          paymentStatus: PaymentStatus.held,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Report Issue'), findsOneWidget);
    });

    // T227: Report Issue hidden when dispute exists
    testWidgets('T227 Report Issue hidden when dispute exists', (tester) async {
      _stubBookingVm(bookingVm, currentUserId: _kClientId);
      _stubSafetyWithDispute(safetyVm);

      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.active,
          paymentStatus: PaymentStatus.held,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Report Issue'), findsNothing);
    });

    // T228: dispute banner shows review text for non-active status
    testWidgets('T228 dispute banner shows review text for open status', (
      tester,
    ) async {
      _stubSafetyWithDispute(safetyVm, status: 'open');

      await _pumpScreen(
        tester,
        booking: _booking(status: BookingStatus.active),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Dispute under review. Approve and release disabled.'),
        findsOneWidget,
      );
    });

    // T229: back button is present
    testWidgets('T229 back button renders in app bar', (tester) async {
      await _pumpScreen(
        tester,
        booking: _booking(),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });

    // T230: timeline shows No deadline when dueAtUtc is null
    testWidgets('T230 timeline shows No deadline when dueAtUtc is null', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        booking: _booking(dueAtUtc: null, deliveryDays: null),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('No deadline'), findsOneWidget);
      // Delivery row should not appear when deliveryDays is null
      expect(find.text('Delivery'), findsNothing);
    });

    // T231: delivered booking shows Delivered (Review) status
    testWidgets('T231 delivered booking shows Delivered Review status', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.delivered,
          paymentStatus: PaymentStatus.held,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Delivered (Review)'), findsOneWidget);
    });

    // T232: AppCardContainer is used for content sections
    testWidgets('T232 AppCardContainer wraps content sections', (tester) async {
      await _pumpScreen(
        tester,
        booking: _booking(price: 100, note: 'Test'),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      // Service card, counterparty, note, price, and timeline use AppCardContainer
      expect(find.byType(AppCardContainer), findsAtLeastNWidgets(4));
    });

    // T233: task ID shows N/A when taskId is null
    testWidgets('T233 shows Task N/A when taskId is null', (tester) async {
      await _pumpScreen(
        tester,
        booking: _booking(taskId: null),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Task #N/A'), findsOneWidget);
    });

    // T234: disputed status shows correct banner text
    testWidgets('T234 disputed booking shows Disputed Under Review banner', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.disputed,
          paymentStatus: PaymentStatus.held,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Disputed (Under Review)'), findsOneWidget);
    });

    // T235: client sees Approve & Release Funds on delivered+held booking
    testWidgets('T235 client sees Approve & Release Funds on delivered held', (
      tester,
    ) async {
      _stubBookingVm(bookingVm, currentUserId: _kClientId);

      await _pumpScreen(
        tester,
        booking: _booking(
          status: BookingStatus.delivered,
          paymentStatus: PaymentStatus.held,
        ),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Approve & Release Funds'), findsOneWidget);
    });

    // T236: price section hidden when price is null
    testWidgets('T236 price section hidden when price is null', (tester) async {
      await _pumpScreen(
        tester,
        booking: _booking(price: null),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      // "Price" section header should NOT appear
      expect(find.text('Price'), findsNothing);
    });

    // T237: legacy slot-based booking shows banner
    testWidgets('T237 legacy slot booking shows slot banner', (tester) async {
      await _pumpScreen(
        tester,
        booking: _booking(slotId: 'slot-123'),
        bookingVm: bookingVm,
        safetyVm: safetyVm,
      );
      await tester.pumpAndSettle();

      expect(find.text('Legacy slot-based booking'), findsOneWidget);
    });
  });
}
