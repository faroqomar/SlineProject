import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/dashboard_cache_service.dart';
import 'package:sline_app/features/dashboard/models/activity_log.dart';
import 'package:sline_app/features/dashboard/models/work_item.dart';

WorkItem _workItem({required String id, required String title}) {
  return WorkItem(
    id: id,
    type: WorkItemType.booking,
    title: title,
    counterpartyId: 'counterparty-$id',
    counterpartyName: 'Name $id',
    counterpartyAvatar: 'avatar-$id.png',
    counterpartyRole: 'Freelancer',
    sourceId: 'source-$id',
    statusRaw: 'active',
    statusUiBucket: 'Active',
    createdAt: DateTime.utc(2026, 2, 24, 10),
    lastUpdate: DateTime.utc(2026, 2, 24, 11),
    primaryActionType: PrimaryActionType.viewDetails,
    permissions: WorkItemPermissions(),
  );
}

ActivityLog _activityLog() {
  return ActivityLog(
    id: 'activity-1',
    userId: 'user-1',
    actorId: 'actor-1',
    entityType: 'task',
    entityId: 'task-1',
    eventType: 'created',
    createdAt: DateTime.utc(2026, 2, 24, 10),
  );
}

void main() {
  const dashboardTimestampKey = 'dashboard_timestamp';

  group('DashboardCacheService T42-T44', () {
    test('T42 caches and restores role-specific work items', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = DashboardCacheService(prefs);

      final clientItems = [_workItem(id: 'client-1', title: 'Client Item')];
      final freelancerItems = [
        _workItem(id: 'freelancer-1', title: 'Freelancer Item'),
      ];

      await service.cacheWorkItems(clientItems, UserRole.client);
      await service.cacheWorkItems(freelancerItems, UserRole.freelancer);

      final restoredClient = await service.getCachedWorkItems(UserRole.client);
      final restoredFreelancer = await service.getCachedWorkItems(
        UserRole.freelancer,
      );

      expect(restoredClient?.map((e) => e.id).toList(), ['client-1']);
      expect(restoredFreelancer?.map((e) => e.id).toList(), ['freelancer-1']);
      expect(
        restoredClient?.first.title,
        isNot(restoredFreelancer?.first.title),
      );
    });

    test('T43 isCacheValid false after expiry window', () async {
      final oldTimestamp = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        dashboardTimestampKey: oldTimestamp,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = DashboardCacheService(prefs);

      expect(service.isCacheValid(), isFalse);
    });

    test('T44 clearCache removes all keys', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = DashboardCacheService(prefs);

      await service.cacheWorkItems([
        _workItem(id: 'client-1', title: 'Client Item'),
      ], UserRole.client);
      await service.cacheWorkItems([
        _workItem(id: 'freelancer-1', title: 'Freelancer Item'),
      ], UserRole.freelancer);
      await service.cacheActivityFeed([_activityLog()]);
      await service.cacheCounters({'active': 2});
      await service.cacheUserRole(UserRole.client);

      await service.clearCache();

      final stats = service.getCacheStats();
      expect(stats['has_client_items'], isFalse);
      expect(stats['has_freelancer_items'], isFalse);
      expect(stats['has_activity'], isFalse);
      expect(stats['has_counters'], isFalse);
      expect(stats['timestamp'], isNull);
      expect(stats['valid'], isFalse);
      expect(await service.getCachedUserRole(), UserRole.client);
    });
  });
}
