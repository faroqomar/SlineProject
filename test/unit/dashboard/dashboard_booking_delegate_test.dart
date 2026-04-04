import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_booking_delegate.dart';
import 'package:sline_app/features/booking/models/booking_model.dart';
import '../../helpers/mock_services.dart';

void main() {
  late MockBookingService mockBookingService;
  late int notifyCount;
  late bool disposed;

  DashboardBookingDelegate buildDelegate() {
    notifyCount = 0;
    disposed = false;
    return DashboardBookingDelegate(
      bookingService: mockBookingService,
      onChanged: () => notifyCount++,
      isDisposed: () => disposed,
    );
  }

  setUp(() {
    mockBookingService = MockBookingService();
  });

  group('DashboardBookingDelegate', () {
    test('initial state is empty', () {
      final delegate = buildDelegate();
      expect(delegate.bookings, isEmpty);
      expect(delegate.bookingFilter, isNull);
      expect(delegate.bookingsLoaded, isFalse);
    });

    test('setBookings populates list and marks loaded', () {
      final delegate = buildDelegate();
      final booking = _buildBooking(id: 'b1');
      delegate.setBookings([booking]);
      expect(delegate.bookings, hasLength(1));
      expect(delegate.bookingsLoaded, isTrue);
    });

    test('clear resets all state', () {
      final delegate = buildDelegate();
      delegate.setBookings([_buildBooking(id: 'b1')]);
      delegate.clear();
      expect(delegate.bookings, isEmpty);
      expect(delegate.bookingsLoaded, isFalse);
      expect(delegate.bookingFilter, isNull);
    });

    test('setBookingFilter updates filter and notifies', () {
      final delegate = buildDelegate();
      delegate.setBookingFilter(BookingStatus.confirmed);
      expect(delegate.bookingFilter, BookingStatus.confirmed);
      expect(notifyCount, 1);
    });

    test('setBookingFilter skips if same value', () {
      final delegate = buildDelegate();
      delegate.setBookingFilter(BookingStatus.confirmed);
      notifyCount = 0;
      delegate.setBookingFilter(BookingStatus.confirmed);
      expect(notifyCount, 0);
    });

    test('acceptBooking calls bookingService', () async {
      final delegate = buildDelegate();
      when(
        () => mockBookingService.acceptBooking('b1'),
      ).thenAnswer((_) async {});

      await delegate.acceptBooking('b1');
      verify(() => mockBookingService.acceptBooking('b1')).called(1);
    });

    test('declineBooking calls bookingService', () async {
      final delegate = buildDelegate();
      when(
        () => mockBookingService.declineBooking('b1'),
      ).thenAnswer((_) async {});

      await delegate.declineBooking('b1');
      verify(() => mockBookingService.declineBooking('b1')).called(1);
    });

    test('cancelBooking calls updateBookingStatus with canceled', () async {
      final delegate = buildDelegate();
      when(
        () => mockBookingService.updateBookingStatus(
          bookingId: 'b1',
          newStatus: BookingStatus.canceled,
        ),
      ).thenAnswer((_) async => _buildBooking(id: 'b1'));

      await delegate.cancelBooking('b1');
      verify(
        () => mockBookingService.updateBookingStatus(
          bookingId: 'b1',
          newStatus: BookingStatus.canceled,
        ),
      ).called(1);
    });

    test('updateBookingStatus updates local list', () async {
      final delegate = buildDelegate();
      final original = _buildBooking(id: 'b1');
      delegate.setBookings([original]);

      final updated = _buildBooking(id: 'b1');
      when(
        () => mockBookingService.updateBookingStatus(
          bookingId: 'b1',
          newStatus: BookingStatus.inProgress,
        ),
      ).thenAnswer((_) async => updated);

      await delegate.updateBookingStatus('b1', BookingStatus.inProgress);
      expect(notifyCount, 1);
      verify(
        () => mockBookingService.updateBookingStatus(
          bookingId: 'b1',
          newStatus: BookingStatus.inProgress,
        ),
      ).called(1);
    });

    test('loadBookingsData does not reload if already loaded', () async {
      final delegate = buildDelegate();
      delegate.setBookings([_buildBooking(id: 'b1')]);
      // Already loaded — should not call service
      await delegate.loadBookingsData(UserRole.freelancer);
      verifyNever(
        () => mockBookingService.listBookingsAsProvider(
          limit: any(named: 'limit'),
        ),
      );
    });

    test('setBookingFilter does not notify when disposed', () {
      final delegate = buildDelegate();
      disposed = true;
      delegate.setBookingFilter(BookingStatus.confirmed);
      expect(notifyCount, 0);
    });
  });
}

BookingModel _buildBooking({required String id}) {
  return BookingModel.fromJson({
    'id': id,
    'client_id': 'c1',
    'provider_id': 'p1',
    'status': 'pending',
    'price': 100.0,
    'created_at': DateTime.now().toIso8601String(),
    'service_title': 'Test Booking',
  });
}
