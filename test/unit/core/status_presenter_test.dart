import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/utils/status_presenter.dart';

void main() {
  group('StatusPresenter.bookingStatusColor', () {
    test('maps active/confirmed statuses to teal', () {
      expect(StatusPresenter.bookingStatusColor(BookingStatus.active), AppColors.teal);
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.confirmed),
        AppColors.teal,
      );
    });

    test('maps pending and paidRequestPending to gold', () {
      expect(StatusPresenter.bookingStatusColor(BookingStatus.pending), AppColors.gold);
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.paidRequestPending),
        AppColors.gold,
      );
    });

    test('maps canceled-like statuses to lightRed', () {
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.canceled),
        AppColors.lightRed,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.declined),
        AppColors.lightRed,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.delivered),
        AppColors.lightRed,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.noShow),
        AppColors.lightRed,
      );
    });

    test('returns fallback for unhandled statuses', () {
      const customFallback = Color(0xFF123456);
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.refunded, customFallback),
        customFallback,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.refunded),
        AppColors.mediumGrey,
      );
    });
  });

  group('StatusPresenter.bookingStatusLabel', () {
    test('returns explicit labels for special statuses', () {
      expect(
        StatusPresenter.bookingStatusLabel(BookingStatus.paidRequestPending),
        'REQUEST PENDING',
      );
      expect(
        StatusPresenter.bookingStatusLabel(BookingStatus.inProgress),
        'IN PROGRESS',
      );
      expect(StatusPresenter.bookingStatusLabel(BookingStatus.noShow), 'NO SHOW');
      expect(
        StatusPresenter.bookingStatusLabel(BookingStatus.expiredUnanswered),
        'EXPIRED',
      );
      expect(
        StatusPresenter.bookingStatusLabel(BookingStatus.disputed),
        'DISPUTED',
      );
    });

    test('falls back to uppercase enum name for normal statuses', () {
      expect(StatusPresenter.bookingStatusLabel(BookingStatus.confirmed), 'CONFIRMED');
      expect(StatusPresenter.bookingStatusLabel(BookingStatus.pending), 'PENDING');
    });
  });

  group('StatusPresenter.offerStatusColor', () {
    test('maps all offer statuses to expected colors', () {
      expect(StatusPresenter.offerStatusColor(OfferStatus.pending), AppColors.gold);
      expect(StatusPresenter.offerStatusColor(OfferStatus.accepted), AppColors.teal);
      expect(
        StatusPresenter.offerStatusColor(OfferStatus.rejected),
        AppColors.lightRed,
      );
      expect(
        StatusPresenter.offerStatusColor(OfferStatus.withdrawn),
        AppColors.lightRed,
      );
      expect(StatusPresenter.offerStatusColor(OfferStatus.unknown), AppColors.lightRed);
    });
  });

  group('StatusPresenter.offerStatusLabel', () {
    test('maps all offer statuses to expected labels', () {
      expect(StatusPresenter.offerStatusLabel(OfferStatus.pending), 'Pending');
      expect(StatusPresenter.offerStatusLabel(OfferStatus.accepted), 'Accepted');
      expect(StatusPresenter.offerStatusLabel(OfferStatus.rejected), 'Rejected');
      expect(StatusPresenter.offerStatusLabel(OfferStatus.withdrawn), 'Withdrawn');
      expect(StatusPresenter.offerStatusLabel(OfferStatus.unknown), 'Unavailable');
    });
  });
}
