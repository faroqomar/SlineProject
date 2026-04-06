import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import 'package:sline_app/features/wallet/services/ledger_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Low-level booking data access layer.
///
/// New booking creation is server-authoritative through edge functions, so this
/// service only reads and mutates existing booking rows.
class BookingService {
  BookingService(this._client);

  final SupabaseClient _client;

  static const String _bookingsTable = 'bookings';
  static const String _bookingSelect =
      'id, task_id, provider_id, client_id, slot_id, status, payment_status, '
      'note, price, package_id, requirements, created_at, due_at, '
      'delivery_days, completed_at, tasks(*)';

  Future<List<BookingModel>> listBookingsAsClient({
    int limit = 50,
    String? cursorCreatedAtIso,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      var query = _client
          .from(_bookingsTable)
          .select(_bookingSelect)
          .eq('client_id', uid);

      if (cursorCreatedAtIso != null) {
        query = query.lt('created_at', cursorCreatedAtIso);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List<dynamic>)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to list client bookings',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      rethrow;
    }
  }

  Future<List<BookingModel>> listBookingsAsProvider({
    int limit = 50,
    String? cursorCreatedAtIso,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      var query = _client
          .from(_bookingsTable)
          .select(_bookingSelect)
          .eq('provider_id', uid);

      if (cursorCreatedAtIso != null) {
        query = query.lt('created_at', cursorCreatedAtIso);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List<dynamic>)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to list provider bookings',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      rethrow;
    }
  }

  Future<List<BookingModel>> getPendingRequests({int limit = 50}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final data = await _client
          .from(_bookingsTable)
          .select(_bookingSelect)
          .eq('provider_id', uid)
          .eq('status', 'paid_request_pending')
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List<dynamic>)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to get pending requests',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      return [];
    }
  }

  Future<BookingModel> createBookingDraft({
    required String taskId,
    String? note,
    String? packageId,
    Map<String, dynamic>? requirements,
  }) async {
    try {
      AppLogger.i(
        'Calling rpc_create_booking_draft_validated for task $taskId',
        tag: 'Booking',
      );
      final res = await _client.rpc(
        'rpc_create_booking_draft_validated',
        params: {
          'p_task_id': taskId,
          'p_note': note,
          'p_package_id': packageId,
          'p_requirements': requirements ?? {},
        },
      );
      return BookingModel.fromJson(res as Map<String, dynamic>);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to create booking draft for task $taskId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      rethrow;
    }
  }

  /// Updates booking status. Enforces guard: client cannot set canceled when status is delivered
  /// (use Report Issue / dispute flow instead). Plan: PLAN_BookingLifecycle_2026-03-08_PlanCritic.
  Future<BookingModel> updateBookingStatus({
    required String bookingId,
    required BookingStatus newStatus,
  }) async {
    final uid = _client.auth.currentUser?.id;
    try {
      if (newStatus == BookingStatus.canceled && uid != null) {
        final current = await getBookingById(bookingId);
        final isClient = current.clientId == uid;
        if (isClient && current.status == BookingStatus.delivered) {
          AppLogger.w(
            'Blocked client from canceling delivered booking',
            tag: 'Booking',
          );
          throw StateError(
            'You cannot cancel after delivery. Use Report Issue to open a dispute.',
          );
        }
      }

      final res = await _client
          .from(_bookingsTable)
          .update({'status': _mapStatusToDb(newStatus)})
          .eq('id', bookingId)
          .select(_bookingSelect)
          .single();

      AppLogger.i(
        'Updated booking $bookingId status to $newStatus',
        tag: 'Booking',
      );
      return BookingModel.fromJson(res as Map<String, dynamic>);
    } on Exception catch (e, st) {
      if (e is StateError) rethrow;
      AppLogger.e(
        'Failed to update booking status for $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      rethrow;
    }
  }

  Future<BookingModel> getBookingById(String bookingId) async {
    try {
      final res = await _client
          .from(_bookingsTable)
          .select(_bookingSelect)
          .eq('id', bookingId)
          .single();
      return BookingModel.fromJson(res);
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to get booking by id $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      rethrow;
    }
  }

  Future<void> escrowHoldBooking(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      await LedgerService(_client).submitPaymentEvent(
        eventType: 'escrow_hold',
        relatedEntityType: 'booking',
        relatedEntityId: booking.id,
        amountGross: booking.price ?? 0,
        meta: {},
      );
      AppLogger.i(
        'Escrow hold submitted for booking $bookingId',
        tag: 'Booking',
      );
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to hold escrow for booking $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      rethrow;
    }
  }

  Future<void> approveAndRelease(String bookingId) async {
    try {
      await _client.rpc(
        'rpc_approve_delivery',
        params: {'entity_type': 'booking', 'entity_id': bookingId},
      );
      AppLogger.i(
        'Approve and release submitted for booking $bookingId',
        tag: 'Booking',
      );
    } on PostgrestException catch (e, st) {
      final friendly = ErrorMapper.map(e);
      AppLogger.e(
        'Failed to release booking $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
        json: {'mappedMessage': friendly},
      );
      throw Exception(friendly);
    } on Exception catch (e, st) {
      final friendly = ErrorMapper.map(e);
      AppLogger.e(
        'Failed to release booking $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
        json: {'mappedMessage': friendly},
      );
      throw Exception(friendly);
    }
  }

  Future<void> declineBooking(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);

      if (booking.status != BookingStatus.declined) {
        await updateBookingStatus(
          bookingId: booking.id,
          newStatus: BookingStatus.declined,
        );
      }

      await LedgerService(_client).submitPaymentEvent(
        eventType: 'refund',
        relatedEntityType: 'booking',
        relatedEntityId: booking.id,
        amountGross: booking.price ?? 0,
        meta: {},
      );
      AppLogger.i(
        'Decline and refund submitted for booking $bookingId',
        tag: 'Booking',
      );
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to decline booking $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      rethrow;
    }
  }

  Future<void> markDelivered(String bookingId) async {
    try {
      await updateBookingStatus(
        bookingId: bookingId,
        newStatus: BookingStatus.delivered,
      );
      AppLogger.i('Marked booking $bookingId as delivered', tag: 'Booking');
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to mark booking $bookingId as delivered',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      rethrow;
    }
  }

  Future<void> acceptBooking(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);

      if (booking.status == BookingStatus.paidRequestPending) {
        await updateBookingStatus(
          bookingId: bookingId,
          newStatus: BookingStatus.active,
        );
      } else if (booking.status == BookingStatus.pending &&
          booking.paymentStatus == PaymentStatus.held) {
        AppLogger.w(
          'Promoting pending held booking before accept',
          tag: 'Booking',
          json: {'booking_id': bookingId},
        );
        await updateBookingStatus(
          bookingId: bookingId,
          newStatus: BookingStatus.paidRequestPending,
        );
        await updateBookingStatus(
          bookingId: bookingId,
          newStatus: BookingStatus.active,
        );
      } else {
        AppLogger.w(
          'Blocked accept booking due to invalid state',
          tag: 'Booking',
          json: {
            'booking_id': bookingId,
            'status': booking.status.name,
            'payment_status': booking.paymentStatus.name,
          },
        );
        throw StateError('Client payment is still pending.');
      }
      AppLogger.i('Accepted booking $bookingId', tag: 'Booking');
    } on Exception catch (e, st) {
      AppLogger.e(
        'Failed to accept booking $bookingId',
        error: e,
        stackTrace: st,
        tag: 'Booking',
      );
      rethrow;
    }
  }

  String _mapStatusToDb(BookingStatus status) {
    switch (status) {
      case BookingStatus.paidRequestPending:
        return 'paid_request_pending';
      case BookingStatus.active:
        return 'active';
      case BookingStatus.delivered:
        return 'delivered';
      case BookingStatus.refunded:
        return 'refunded';
      case BookingStatus.expiredUnanswered:
        return 'expired_unanswered';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.noShow:
        return 'no_show';
      case BookingStatus.disputed:
        return 'disputed';
      case BookingStatus.declined:
        return 'canceled';
      default:
        return status.name;
    }
  }
}
