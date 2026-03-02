import 'package:flutter/material.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';

/// Shared status color and label helpers for booking and offer UIs
/// (dashboard cards, lists, badges) to avoid duplication.
class StatusPresenter {
  StatusPresenter._();

  static Color bookingStatusColor(BookingStatus status, [Color? fallback]) {
    final f = fallback ?? AppColors.mediumGrey;
    switch (status) {
      case BookingStatus.confirmed:
      case BookingStatus.active:
        return AppColors.teal;
      case BookingStatus.pending:
      case BookingStatus.paidRequestPending:
        return AppColors.gold;
      case BookingStatus.canceled:
      case BookingStatus.declined:
      case BookingStatus.delivered:
        return AppColors.lightRed;
      case BookingStatus.completed:
        return AppColors.gold;
      default:
        return f;
    }
  }

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
      default:
        return status.name.toUpperCase();
    }
  }

  static Color offerStatusColor(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return AppColors.gold;
      case OfferStatus.accepted:
        return AppColors.teal;
      case OfferStatus.rejected:
      case OfferStatus.withdrawn:
      case OfferStatus.unknown:
        return AppColors.lightRed;
    }
  }

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
