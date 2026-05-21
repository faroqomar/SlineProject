// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SLine';

  @override
  String get back => 'Back';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navProfile => 'Profile';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navWallet => 'Wallet';

  @override
  String get availableBalance => 'AVAILABLE BALANCE';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get topUp => 'Top up';

  @override
  String get createPost => 'Create a post';

  @override
  String get tenderPostTitle => 'Tender post';

  @override
  String get tenderPostSubtitle =>
      'Client request with budget, deadline, and offers.';

  @override
  String get bookingPostTitle => 'Booking post';

  @override
  String get bookingPostSubtitle => 'Freelancer service package with price.';

  @override
  String get roleLabel => 'Role';

  @override
  String get roleHint => 'e.g., UX designer';

  @override
  String get seniorityLabel => 'Seniority';

  @override
  String get seniorityHint => 'e.g., Senior';

  @override
  String get searchTenders => 'Search tenders…';

  @override
  String get bookedService => 'Booked service';

  @override
  String get bookingDetails => 'Booking Details';

  @override
  String get bookingService => 'Service';

  @override
  String bookedOn(String date) {
    return 'Booked on $date';
  }

  @override
  String get bookingClient => 'Client';

  @override
  String get bookingProvider => 'Provider';

  @override
  String get bookingRequester => 'Booking requester';

  @override
  String get assignedServiceProvider => 'Assigned service provider';

  @override
  String get bookingTimeline => 'Timeline';

  @override
  String get bookingTimelineBooked => 'Booked';

  @override
  String get bookingTimelineDue => 'Due';

  @override
  String get noDeadline => 'No deadline';

  @override
  String get bookingTimelineDelivery => 'Delivery';

  @override
  String bookingDeliveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get legacySlotBasedBooking => 'Legacy slot-based booking';

  @override
  String get reject => 'Reject';

  @override
  String get awaitingPayment => 'Awaiting Payment';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get escrowFunds => 'Escrow Funds';

  @override
  String get issueRefund => 'Issue Refund';

  @override
  String get decline => 'Decline';

  @override
  String get acceptJob => 'Accept Job';

  @override
  String get markDelivered => 'Mark Delivered';

  @override
  String get bookingCannotDisputeMissingTask =>
      'This booking cannot be disputed because task data is missing.';

  @override
  String get describeBookingProblem => 'Describe the problem with this booking';

  @override
  String get disputeSubmitted => 'Dispute submitted.';

  @override
  String get disputeFailed => 'Dispute failed.';

  @override
  String get bookingStatusPendingConfirmation => 'Pending Confirmation';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusCanceled => 'Canceled';

  @override
  String get bookingStatusNoShow => 'No Show';

  @override
  String get bookingStatusInProgress => 'In Progress';

  @override
  String get bookingStatusDeclined => 'Declined';

  @override
  String get bookingStatusActive => 'Active';

  @override
  String get bookingStatusRequestPending => 'Request Pending';

  @override
  String get bookingStatusDeliveredReview => 'Delivered (Review)';

  @override
  String get bookingStatusRefunded => 'Refunded';

  @override
  String get bookingStatusExpired => 'Expired';

  @override
  String get bookingStatusDisputedUnderReview => 'Disputed (Under Review)';

  @override
  String get statusUpdated => 'Status updated';

  @override
  String get statusUpdateFailed => 'Failed to update status';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get workFrozenInDispute => 'Work frozen — in dispute.';

  @override
  String get disputeUnderReviewReleaseDisabled =>
      'Dispute under review. Approve and release disabled.';

  @override
  String get checking => 'Checking…';

  @override
  String get approveReleaseFunds => 'Approve & Release Funds';

  @override
  String get actionLogin => 'Log In';

  @override
  String get actionLogout => 'Log Out';

  @override
  String get actionSubmit => 'Submit';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionRetry => 'Retry';

  @override
  String get tapToRetry => 'Tap to retry';

  @override
  String get stateLoading => 'Loading...';

  @override
  String get stateEmpty => 'Nothing here yet';

  @override
  String get stateNoResults => 'No results found';

  @override
  String get errorNetwork =>
      'Please check your internet connection and try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';
}
