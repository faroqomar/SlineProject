/// Tests Amber Dusk status colors while preserving existing enum labels.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/status_presenter.dart';

void main() {
  const colors = AmberDuskTokens.colors;

  group('StatusPresenter.bookingStatusColor', () {
    test('maps active statuses to Amber Dusk success', () {
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.active),
        colors.success,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.confirmed),
        colors.success,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.inProgress),
        colors.success,
      );
    });

    test('maps pending and review statuses to Amber Dusk warning', () {
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.pending),
        colors.warning,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.paidRequestPending),
        colors.warning,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.delivered),
        colors.warning,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.disputed),
        colors.warning,
      );
    });

    test('maps canceled-like statuses to Amber Dusk danger', () {
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.canceled),
        colors.danger,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.declined),
        colors.danger,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.noShow),
        colors.danger,
      );
    });

    test('maps completed money states to Amber Dusk text', () {
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.completed),
        colors.text,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.refunded),
        colors.text,
      );
    });

    test('returns fallback only for expired unanswered status', () {
      const customFallback = Color(0xFF123456);
      expect(
        StatusPresenter.bookingStatusColor(
          BookingStatus.expiredUnanswered,
          customFallback,
        ),
        customFallback,
      );
      expect(
        StatusPresenter.bookingStatusColor(BookingStatus.expiredUnanswered),
        colors.muted,
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
      expect(
        StatusPresenter.bookingStatusLabel(BookingStatus.noShow),
        'NO SHOW',
      );
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
      expect(
        StatusPresenter.bookingStatusLabel(BookingStatus.confirmed),
        'CONFIRMED',
      );
      expect(
        StatusPresenter.bookingStatusLabel(BookingStatus.pending),
        'PENDING',
      );
    });
  });

  group('StatusPresenter.offerStatusColor', () {
    test('maps all offer statuses to Amber Dusk semantic colors', () {
      expect(
        StatusPresenter.offerStatusColor(OfferStatus.pending),
        colors.warning,
      );
      expect(
        StatusPresenter.offerStatusColor(OfferStatus.accepted),
        colors.success,
      );
      expect(
        StatusPresenter.offerStatusColor(OfferStatus.rejected),
        colors.danger,
      );
      expect(
        StatusPresenter.offerStatusColor(OfferStatus.withdrawn),
        colors.danger,
      );
      expect(
        StatusPresenter.offerStatusColor(OfferStatus.unknown),
        colors.muted,
      );
    });
  });

  group('StatusPresenter.offerStatusLabel', () {
    test('maps all offer statuses to expected labels', () {
      expect(StatusPresenter.offerStatusLabel(OfferStatus.pending), 'Pending');
      expect(
        StatusPresenter.offerStatusLabel(OfferStatus.accepted),
        'Accepted',
      );
      expect(
        StatusPresenter.offerStatusLabel(OfferStatus.rejected),
        'Rejected',
      );
      expect(
        StatusPresenter.offerStatusLabel(OfferStatus.withdrawn),
        'Withdrawn',
      );
      expect(
        StatusPresenter.offerStatusLabel(OfferStatus.unknown),
        'Unavailable',
      );
    });
  });
}
