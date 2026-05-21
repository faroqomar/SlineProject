import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';

void main() {
  group('WorkItem model T35', () {
    test(
      'T35 WorkItem toJson/fromJson roundtrip preserves permissions and sort fields',
      () {
        final original = WorkItem(
          id: 'work-1',
          type: WorkItemType.booking,
          title: 'Roundtrip booking',
          counterpartyId: 'user-2',
          counterpartyName: 'Counterparty',
          counterpartyAvatar: 'avatar.png',
          counterpartyRole: 'Freelancer',
          sourceId: 'booking-1',
          statusRaw: 'delivered',
          statusUiBucket: 'Done',
          createdAt: DateTime.utc(2026, 2, 24, 10),
          scheduledAt: DateTime.utc(2026, 2, 25, 9),
          completedAt: DateTime.utc(2026, 2, 26, 9),
          lastUpdate: DateTime.utc(2026, 2, 26, 10),
          primaryActionType: PrimaryActionType.reviewDelivery,
          deepLinkRoute: '/booking/booking-1',
          permissions: WorkItemPermissions(
            canReview: true,
            canDispute: true,
          ),
          workItemId: 'booking:booking-1',
          needsReview: true,
          sortRank: 2,
          lastActivityAt: DateTime.utc(2026, 2, 26, 11, 30),
        );

        final roundTripped = WorkItem.fromJson(original.toJson());

        expect(roundTripped.id, 'work-1');
        expect(roundTripped.type, WorkItemType.booking);
        expect(roundTripped.permissions.canReview, isTrue);
        expect(roundTripped.permissions.canDispute, isTrue);
        expect(roundTripped.permissions.canPayEscrow, isFalse);
        expect(roundTripped.sortRank, 2);
        expect(roundTripped.lastActivityAt, DateTime.utc(2026, 2, 26, 11, 30));
        expect(roundTripped.needsReview, isTrue);
        expect(roundTripped.actionableNeedsReview, isTrue);
        expect(roundTripped.awaitingCounterpartyReview, isFalse);
      },
    );

    test('review helpers distinguish actionable vs waiting states', () {
      final waitingItem = WorkItem(
        id: 'work-2',
        type: WorkItemType.task,
        title: 'Waiting review task',
        counterpartyId: 'user-3',
        counterpartyName: 'Client',
        counterpartyAvatar: '',
        counterpartyRole: 'Client',
        statusRaw: 'delivered',
        statusUiBucket: 'Active',
        createdAt: DateTime.utc(2026, 3, 1, 10),
        lastUpdate: DateTime.utc(2026, 3, 1, 11),
        primaryActionType: PrimaryActionType.viewDetails,
        permissions: WorkItemPermissions(),
        needsReview: true,
      );

      expect(waitingItem.actionableNeedsReview, isFalse);
      expect(waitingItem.awaitingCounterpartyReview, isTrue);
    });
  });
}
