import 'package:sline_app/features/dashboard/models/dashboard_counters.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';
import 'package:sline_app/features/dashboard/models/activity_item.dart';

import 'package:sline_app/features/dashboard/services/dashboard_permission_service.dart';

class MockDashboardRepository {
  Future<DashboardCounters> getCounters(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (role == UserRole.freelancer) {
      return const DashboardCounters(
        pendingRequests: 3,
        activeWork: 2,
        newMessages: 5,
        newOffers: 0,
      );
    } else {
      return const DashboardCounters(
        activeWork: 1,
        pendingRequests: 2,
        newOffers: 4,
        newMessages: 1,
      );
    }
  }

  Future<List<WorkItem>> getActiveWork(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final now = DateTime.now();

    if (role == UserRole.freelancer) {
      return [
        WorkItem(
          id: '1',
          type: WorkItemType.booking,
          title: 'Logo Design Session',
          counterpartyId: 'client_1',
          counterpartyName: 'Alice Client',
          counterpartyAvatar: 'https://i.pravatar.cc/150?u=1',
          counterpartyRole: 'Client',
          statusRaw: BookingStatus.confirmed.name,
          statusUiBucket: 'Active',
          createdAt: now.subtract(const Duration(days: 1)),
          scheduledAt: now.add(const Duration(hours: 2)),
          lastUpdate: now.subtract(const Duration(hours: 1)),
          primaryActionType: DashboardPermissionService.getPrimaryAction(
            userRole: role,
            type: WorkItemType.booking,
            status: BookingStatus.confirmed,
          ),
          permissions: DashboardPermissionService.calculatePermissions(
            userRole: role,
            type: WorkItemType.booking,
            status: BookingStatus.confirmed,
          ),
        ),
        WorkItem(
          id: '2',
          type: WorkItemType.task,
          title: 'Mobile App MVP',
          counterpartyId: 'client_2',
          counterpartyName: 'Bob Startup',
          counterpartyAvatar: 'https://i.pravatar.cc/150?u=2',
          counterpartyRole: 'Client',
          statusRaw: TaskStatus.inProgress.name,
          statusUiBucket: 'Active',
          createdAt: now.subtract(const Duration(days: 5)),
          lastUpdate: now.subtract(const Duration(days: 1)),
          primaryActionType: DashboardPermissionService.getPrimaryAction(
            userRole: role,
            type: WorkItemType.task,
            status: TaskStatus.inProgress,
          ),
          permissions: DashboardPermissionService.calculatePermissions(
            userRole: role,
            type: WorkItemType.task,
            status: TaskStatus.inProgress,
          ),
        ),
      ];
    } else {
      // Client View
      return [
        WorkItem(
          id: '3',
          type: WorkItemType.booking,
          title: 'Consultation Call',
          counterpartyId: 'freelancer_1',
          counterpartyName: 'John Expert',
          counterpartyAvatar: 'https://i.pravatar.cc/150?u=3',
          counterpartyRole: 'Freelancer',
          statusRaw: BookingStatus.completed.name,
          statusUiBucket: 'Done',
          createdAt: now.subtract(const Duration(days: 2)),
          completedAt: now.subtract(const Duration(hours: 4)),
          lastUpdate: now,
          primaryActionType: DashboardPermissionService.getPrimaryAction(
            userRole: role,
            type: WorkItemType.booking,
            status: BookingStatus.completed,
          ),
          permissions: DashboardPermissionService.calculatePermissions(
            userRole: role,
            type: WorkItemType.booking,
            status: BookingStatus.completed,
          ),
        ),
      ];
    }
  }

  Future<List<ActivityItem>> getActivityFeed() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    return [
      ActivityItem(
        id: 'a1',
        actorId: 'u2',
        actorRole: 'Client',
        targetType: 'booking',
        targetId: 'b1',
        eventType: 'confirmed',
        description: 'Alice confirmed your booking',
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      ActivityItem(
        id: 'a2',
        actorId: 'u3',
        actorRole: 'Freelancer',
        targetType: 'offer',
        targetId: 'o1',
        eventType: 'submitted',
        description: 'New offer received on "Mobile App"',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }
}
