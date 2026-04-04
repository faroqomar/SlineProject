import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/tasks/models/expired_bid_filter.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/viewmodels/requests_filter_view_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

class MockTaskRequestsViewModel extends Mock implements TaskRequestsViewModel {}

void main() {
  late MockTaskRequestsViewModel mockRequestsVm;

  setUp(() {
    mockRequestsVm = MockTaskRequestsViewModel();
    when(() => mockRequestsVm.items).thenReturn([]);
    when(() => mockRequestsVm.hasMore).thenReturn(false);
    when(() => mockRequestsVm.isLoadingMore).thenReturn(false);
  });

  RequestsFilterViewModel buildVm() {
    return RequestsFilterViewModel(requestsVm: mockRequestsVm);
  }

  group('RequestsFilterViewModel', () {
    test('initial filter is hideExpired', () {
      final vm = buildVm();
      expect(vm.filter, ExpiredBidFilter.hideExpired);
    });

    test('setFilter changes filter and notifies', () {
      final vm = buildVm();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.setFilter(ExpiredBidFilter.showAll);
      expect(vm.filter, ExpiredBidFilter.showAll);
      expect(notifyCount, 1);
    });

    test('setFilter with same value does not notify', () {
      final vm = buildVm();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.setFilter(ExpiredBidFilter.hideExpired); // same as default
      expect(notifyCount, 0);
    });

    test('applyFilter hideExpired removes expired items', () {
      final vm = buildVm();
      final items = [
        _buildRequest(id: 'r1', isExpired: false),
        _buildRequest(id: 'r2', isExpired: true),
        _buildRequest(id: 'r3', isExpired: false),
      ];

      vm.setFilter(ExpiredBidFilter.hideExpired);
      final filtered = vm.applyFilter(items);
      expect(filtered, hasLength(2));
      expect(filtered.every((r) => !r.isExpired), isTrue);
    });

    test('applyFilter showAll returns all items', () {
      final vm = buildVm();
      final items = [
        _buildRequest(id: 'r1', isExpired: false),
        _buildRequest(id: 'r2', isExpired: true),
      ];

      vm.setFilter(ExpiredBidFilter.showAll);
      final filtered = vm.applyFilter(items);
      expect(filtered, hasLength(2));
    });

    test('applyFilter showOnlyExpired returns only expired items', () {
      final vm = buildVm();
      final items = [
        _buildRequest(id: 'r1', isExpired: false),
        _buildRequest(id: 'r2', isExpired: true),
        _buildRequest(id: 'r3', isExpired: true),
      ];

      vm.setFilter(ExpiredBidFilter.showOnlyExpired);
      final filtered = vm.applyFilter(items);
      expect(filtered, hasLength(2));
      expect(filtered.every((r) => r.isExpired), isTrue);
    });

    test('getCountString shows total when showAll', () {
      final vm = buildVm();
      vm.setFilter(ExpiredBidFilter.showAll);
      expect(vm.getCountString(10, 10), '10 offers');
    });

    test('getCountString shows filtered count when different', () {
      final vm = buildVm();
      vm.setFilter(ExpiredBidFilter.hideExpired);
      expect(vm.getCountString(10, 7), '7 of 10 offers');
    });

    test('getCountString shows total when counts match', () {
      final vm = buildVm();
      vm.setFilter(ExpiredBidFilter.hideExpired);
      expect(vm.getCountString(5, 5), '5 offers');
    });

    test('isAwarding defaults to false', () {
      final vm = buildVm();
      expect(vm.isAwarding, isFalse);
    });

    test('isAwarding setter notifies listeners', () {
      final vm = buildVm();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.isAwarding = true;
      expect(vm.isAwarding, isTrue);
      expect(notifyCount, 1);

      vm.isAwarding = false;
      expect(vm.isAwarding, isFalse);
      expect(notifyCount, 2);
    });

    test('isAwarding setter with same value does not notify', () {
      final vm = buildVm();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.isAwarding = false; // same as default
      expect(notifyCount, 0);
    });

    test('filteredItems delegates to requestsVm.items', () {
      final items = [
        _buildRequest(id: 'r1', isExpired: false),
        _buildRequest(id: 'r2', isExpired: true),
      ];
      when(() => mockRequestsVm.items).thenReturn(items);

      final vm = buildVm();
      vm.setFilter(ExpiredBidFilter.hideExpired);
      expect(vm.filteredItems, hasLength(1));
    });

    test('loadMore delegates when hasMore and not loading', () {
      when(() => mockRequestsVm.hasMore).thenReturn(true);
      when(() => mockRequestsVm.isLoadingMore).thenReturn(false);
      when(() => mockRequestsVm.loadMore()).thenAnswer((_) async {});

      final vm = buildVm();
      vm.loadMore();
      verify(() => mockRequestsVm.loadMore()).called(1);
    });

    test('loadMore does not delegate when no more pages', () {
      when(() => mockRequestsVm.hasMore).thenReturn(false);

      final vm = buildVm();
      vm.loadMore();
      verifyNever(() => mockRequestsVm.loadMore());
    });
  });
}

TaskRequest _buildRequest({required String id, bool isExpired = false}) {
  // isExpired = status == pending AND createdAt + 24h < now.
  // So: expired = pending + created 25h ago. Not expired = pending + created now.
  return TaskRequest(
    id: id,
    taskId: 'task-1',
    bidderId: 'bidder-1',
    price: 5000,
    days: 7,
    status: OfferStatus.pending,
    createdAt: isExpired
        ? DateTime.now().subtract(const Duration(hours: 25))
        : DateTime.now(),
  );
}
