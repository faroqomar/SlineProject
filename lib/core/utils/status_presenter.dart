import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// Shared Amber Dusk status color and label helpers for booking and offer UIs.
///
/// Labels remain tied to the existing domain enums while colors follow the
/// Open Design semantic buckets: muted, amber, forest, cream, and rust.
class StatusPresenter {
  StatusPresenter._();

  static AmberDuskColorTokens get _colors => AmberDuskTokens.colors;

  /// Resolves the booking status accent without changing enum labels or flow.
  static Color bookingStatusColor(BookingStatus status, [Color? fallback]) {
    final f = fallback ?? _colors.muted;
    switch (status) {
      case BookingStatus.confirmed:
      case BookingStatus.active:
      case BookingStatus.inProgress:
        return _colors.success;
      case BookingStatus.pending:
      case BookingStatus.paidRequestPending:
      case BookingStatus.delivered:
      case BookingStatus.disputed:
        return _colors.warning;
      case BookingStatus.canceled:
      case BookingStatus.declined:
      case BookingStatus.noShow:
        return _colors.danger;
      case BookingStatus.completed:
      case BookingStatus.refunded:
        return _colors.text;
      case BookingStatus.expiredUnanswered:
        return f;
    }
  }

  /// Returns the user-facing booking status label used by existing badges.
  static String bookingStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.paidRequestPending:
        return 'REQUEST PENDING';
      case BookingStatus.inProgress:
        return 'IN PROGRESS';
      case BookingStatus.noShow:
        return 'NO SHOW';
      case BookingStatus.expiredUnanswered:
        return 'EXPIRED';
      case BookingStatus.disputed:
        return 'DISPUTED';
      default:
        return status.name.toUpperCase();
    }
  }

  /// Resolves offer status accents using the Amber Dusk semantic status set.
  static Color offerStatusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return _colors.warning;
      case OfferStatus.accepted:
        return _colors.success;
      case OfferStatus.rejected:
      case OfferStatus.withdrawn:
        return _colors.danger;
      case OfferStatus.unknown:
        return _colors.muted;
    }
  }

  /// Returns the user-facing offer status label used by existing offer cards.
  static String offerStatusLabel(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return 'Pending';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.rejected:
        return 'Rejected';
      case OfferStatus.withdrawn:
        return 'Withdrawn';
      case OfferStatus.unknown:
        return 'Unavailable';
    }
  }
}
