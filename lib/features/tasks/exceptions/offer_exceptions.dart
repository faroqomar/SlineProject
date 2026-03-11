/// Exceptions for tender offer operations.
///
/// This library provides custom exceptions for handling tender task lifecycle
/// errors, particularly around price validation and offer acceptance.
///
/// ## Usage
///
/// ```dart
/// try {
///   await service.awardOffer(offerId, expectedPriceCents: 50000);
/// } on PriceMismatchException catch (e) {
///   // Show user-friendly error with old and new prices
///   showDialog(message: e.userMessage);
/// } on OfferAlreadyAcceptedException catch (e) {
///   // Idempotency: treat as success
///   return true;
/// }
/// ```
library;

import 'package:sline_app/core/utils/format_price.dart';

/// Thrown when the expected price doesn't match the actual offer price.
///
/// This exception indicates that the freelancer updated their offer price
/// between when the client loaded the page and when they clicked Accept.
/// The client should be prompted to review the updated terms.
class PriceMismatchException implements Exception {
  /// The price (in cents) the client expected when clicking Accept.
  final int expectedCents;

  /// The actual current price (in cents) of the offer.
  final int actualCents;

  /// Creates a new price mismatch exception.
  const PriceMismatchException({
    required this.expectedCents,
    required this.actualCents,
  });

  @override
  String toString() =>
      'PriceMismatchException: expected $expectedCents cents, got $actualCents cents';

  /// Returns a user-friendly error message suitable for display in the UI.
  String get userMessage {
    final expectedIqd = PriceFormatter.formatPrice(expectedCents / 100);
    final actualIqd = PriceFormatter.formatPrice(actualCents / 100);
    return 'The freelancer updated their offer from $expectedIqd to $actualIqd. Please review the new price before accepting.';
  }
}

/// Thrown when attempting to accept an offer that has already been accepted.
///
/// This exception supports idempotency - calling accept twice on the same
/// offer should not fail, but should indicate the desired state (accepted)
/// has already been achieved.
class OfferAlreadyAcceptedException implements Exception {
  /// Creates a new already accepted exception.
  const OfferAlreadyAcceptedException();

  @override
  String toString() =>
      'OfferAlreadyAcceptedException: This offer has already been accepted';

  /// Returns a user-friendly message.
  String get userMessage => 'This offer has already been accepted.';
}
