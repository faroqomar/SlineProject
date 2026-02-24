import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/dashboard/services/dashboard_permission_service.dart';

void main() {
  group('DashboardPermissionService T19-T22', () {
    test('T21 booking confirmed (freelancer) allows canStart', () {
      final permissions = DashboardPermissionService.calculatePermissions(
        userRole: UserRole.freelancer,
        type: WorkItemType.booking,
        status: BookingStatus.confirmed,
      );

      expect(permissions.canStart, isTrue);
      expect(permissions.canComplete, isFalse);
      expect(permissions.canCancel, isTrue);
      expect(permissions.canReschedule, isTrue);
    });

    test('T22 task completed (client) allows canApprove', () {
      final permissions = DashboardPermissionService.calculatePermissions(
        userRole: UserRole.client,
        type: WorkItemType.task,
        status: TaskStatus.completed,
      );

      expect(permissions.canApprove, isTrue);
      expect(permissions.canStart, isFalse);
      expect(permissions.canComplete, isFalse);
      expect(permissions.canCancel, isFalse);
    });

    test(
      'T19 unified delivered (client) gives reviewDelivery primary action',
      () {
        final action = DashboardPermissionService.getPrimaryAction(
          userRole: UserRole.client,
          type: WorkItemType.booking,
          status: UnifiedWorkStatus.delivered,
        );
        final permissions = DashboardPermissionService.calculatePermissions(
          userRole: UserRole.client,
          type: WorkItemType.booking,
          status: UnifiedWorkStatus.delivered,
        );

        expect(action, PrimaryActionType.reviewDelivery);
        expect(permissions.canReview, isTrue);
      },
    );

    test(
      'T20 unified pendingPayment (client) gives payEscrow primary action',
      () {
        final action = DashboardPermissionService.getPrimaryAction(
          userRole: UserRole.client,
          type: WorkItemType.booking,
          status: UnifiedWorkStatus.pendingPayment,
        );
        final permissions = DashboardPermissionService.calculatePermissions(
          userRole: UserRole.client,
          type: WorkItemType.booking,
          status: UnifiedWorkStatus.pendingPayment,
        );

        expect(action, PrimaryActionType.payEscrow);
        expect(permissions.canPayEscrow, isTrue);
      },
    );
  });
}
