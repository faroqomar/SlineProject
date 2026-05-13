import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'SLine'**
  String get appTitle;

  /// Bottom nav: Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav: Search tab
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// Bottom nav: Dashboard tab
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Bottom nav: Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Bottom nav: Notifications tab
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// Bottom nav: Wallet tab
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// Wallet balance heading
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE BALANCE'**
  String get availableBalance;

  /// Wallet withdrawal action label
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// Wallet top-up action label
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get topUp;

  /// Create task concept section heading
  ///
  /// In en, this message translates to:
  /// **'Create a post'**
  String get createPost;

  /// Tender task type option title
  ///
  /// In en, this message translates to:
  /// **'Tender post'**
  String get tenderPostTitle;

  /// Tender task type option subtitle
  ///
  /// In en, this message translates to:
  /// **'Client request with budget, deadline, and offers.'**
  String get tenderPostSubtitle;

  /// Booking task type option title
  ///
  /// In en, this message translates to:
  /// **'Booking post'**
  String get bookingPostTitle;

  /// Booking task type option subtitle
  ///
  /// In en, this message translates to:
  /// **'Freelancer service package with price.'**
  String get bookingPostSubtitle;

  /// Booking task role field label
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// Booking task role field hint
  ///
  /// In en, this message translates to:
  /// **'e.g., UX designer'**
  String get roleHint;

  /// Booking task seniority field label
  ///
  /// In en, this message translates to:
  /// **'Seniority'**
  String get seniorityLabel;

  /// Booking task seniority field hint
  ///
  /// In en, this message translates to:
  /// **'e.g., Senior'**
  String get seniorityHint;

  /// Tenders screen search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search tenders…'**
  String get searchTenders;

  /// Fallback booking service title
  ///
  /// In en, this message translates to:
  /// **'Booked service'**
  String get bookedService;

  /// Booking details screen title
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// Booking details service section title
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get bookingService;

  /// Booking created date line
  ///
  /// In en, this message translates to:
  /// **'Booked on {date}'**
  String bookedOn(String date);

  /// Booking client role label
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get bookingClient;

  /// Booking provider role label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get bookingProvider;

  /// Booking counterparty subtitle for client
  ///
  /// In en, this message translates to:
  /// **'Booking requester'**
  String get bookingRequester;

  /// Booking counterparty subtitle for provider
  ///
  /// In en, this message translates to:
  /// **'Assigned service provider'**
  String get assignedServiceProvider;

  /// Booking timeline section title
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get bookingTimeline;

  /// Booking timeline booked label
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get bookingTimelineBooked;

  /// Booking timeline due label
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get bookingTimelineDue;

  /// Booking timeline missing deadline value
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get noDeadline;

  /// Booking timeline delivery label
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get bookingTimelineDelivery;

  /// Booking delivery duration in days
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {0 days} =1 {1 day} other {{count} days}}'**
  String bookingDeliveryDays(int count);

  /// Legacy slot booking warning label
  ///
  /// In en, this message translates to:
  /// **'Legacy slot-based booking'**
  String get legacySlotBasedBooking;

  /// Reject booking action label
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// Booking awaiting payment action label
  ///
  /// In en, this message translates to:
  /// **'Awaiting Payment'**
  String get awaitingPayment;

  /// Cancel booking action label
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// Escrow booking funds action label
  ///
  /// In en, this message translates to:
  /// **'Escrow Funds'**
  String get escrowFunds;

  /// Issue booking refund action label
  ///
  /// In en, this message translates to:
  /// **'Issue Refund'**
  String get issueRefund;

  /// Decline booking action label
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// Accept booking job action label
  ///
  /// In en, this message translates to:
  /// **'Accept Job'**
  String get acceptJob;

  /// Mark booking delivered action label
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get markDelivered;

  /// Dispute unavailable message when task data is missing
  ///
  /// In en, this message translates to:
  /// **'This booking cannot be disputed because task data is missing.'**
  String get bookingCannotDisputeMissingTask;

  /// Booking dispute reason text field hint
  ///
  /// In en, this message translates to:
  /// **'Describe the problem with this booking'**
  String get describeBookingProblem;

  /// Dispute submitted success snackbar
  ///
  /// In en, this message translates to:
  /// **'Dispute submitted.'**
  String get disputeSubmitted;

  /// Dispute submission failure fallback
  ///
  /// In en, this message translates to:
  /// **'Dispute failed.'**
  String get disputeFailed;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Pending Confirmation'**
  String get bookingStatusPendingConfirmation;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get bookingStatusCanceled;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'No Show'**
  String get bookingStatusNoShow;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get bookingStatusInProgress;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get bookingStatusDeclined;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bookingStatusActive;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Request Pending'**
  String get bookingStatusRequestPending;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Delivered (Review)'**
  String get bookingStatusDeliveredReview;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get bookingStatusRefunded;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get bookingStatusExpired;

  /// Booking status label
  ///
  /// In en, this message translates to:
  /// **'Disputed (Under Review)'**
  String get bookingStatusDisputedUnderReview;

  /// Booking status update success snackbar
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get statusUpdated;

  /// Booking status update failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get statusUpdateFailed;

  /// Report issue action and dialog title
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// Active dispute banner message
  ///
  /// In en, this message translates to:
  /// **'Work frozen — in dispute.'**
  String get workFrozenInDispute;

  /// Open dispute banner message
  ///
  /// In en, this message translates to:
  /// **'Dispute under review. Approve and release disabled.'**
  String get disputeUnderReviewReleaseDisabled;

  /// Disabled action while a guard is loading
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// Approve and release booking funds action
  ///
  /// In en, this message translates to:
  /// **'Approve & Release Funds'**
  String get approveReleaseFunds;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get actionLogin;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get actionLogout;

  /// Generic submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Generic save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Generic delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Generic confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// Retry after error
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Retry hint shown on tappable media fallback states
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get tapToRetry;

  /// Generic loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get stateLoading;

  /// Generic empty state text
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get stateEmpty;

  /// Search empty results
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get stateNoResults;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get errorNetwork;

  /// Session expired error
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorSessionExpired;

  /// Generic fallback error
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Theme settings label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Language settings label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
