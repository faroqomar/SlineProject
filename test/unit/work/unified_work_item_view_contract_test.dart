import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';

/// Tests for vw_unified_work_items view contract: UnifiedWorkItemModel.fromJson
/// handles task, booking, and direct_offer source_type and conversation_id.
void main() {
  group('UnifiedWorkItemModel.fromJson (view contract)', () {
    test('parses task row with required fields', () {
      final json = <String, dynamic>{
        'id': 'task-uuid',
        'source_type': 'task',
        'source_status': 'in_progress',
        'unified_status': 'active',
        'title': 'Test Task',
        'price': 100,
        'client_id': 'client-1',
        'freelancer_id': 'freelancer-1',
        'work_item_id': 'task:task-uuid',
        'sort_rank': 4,
        'revisions_total': 3,
        'revisions_used': 0,
      };
      final u = UnifiedWorkItemModel.fromJson(json);
      expect(u.id, 'task-uuid');
      expect(u.sourceType, 'task');
      expect(u.unifiedStatus, UnifiedWorkStatus.active);
      expect(u.isTask, isTrue);
      expect(u.isDirectOffer, isFalse);
      expect(u.conversationId, isNull);
    });

    test('parses direct_offer row with conversation_id and disputed', () {
      final json = <String, dynamic>{
        'id': 'offer-uuid',
        'source_type': 'direct_offer',
        'source_status': 'active',
        'unified_status': 'disputed',
        'title': 'Direct Offer',
        'price': 50,
        'client_id': 'client-1',
        'freelancer_id': 'freelancer-1',
        'work_item_id': 'direct_offer:offer-uuid',
        'sort_rank': 4,
        'revisions_total': 0,
        'revisions_used': 0,
        'conversation_id': 'conv-uuid',
      };
      final u = UnifiedWorkItemModel.fromJson(json);
      expect(u.id, 'offer-uuid');
      expect(u.sourceType, 'direct_offer');
      expect(u.unifiedStatus, UnifiedWorkStatus.disputed);
      expect(u.isDirectOffer, isTrue);
      expect(u.conversationId, 'conv-uuid');
    });

    test('parses pending_payment unified_status', () {
      final json = <String, dynamic>{
        'id': 'task-2',
        'source_type': 'task',
        'source_status': 'assigned',
        'unified_status': 'pending_payment',
        'title': 'Awarded Task',
        'price': 75,
        'client_id': 'c',
        'freelancer_id': 'f',
        'work_item_id': 'task:task-2',
        'sort_rank': 2,
        'revisions_total': 3,
        'revisions_used': 0,
        'awarded_request_id': 'req-1',
        'payment_deadline': '2026-12-01T12:00:00Z',
      };
      final u = UnifiedWorkItemModel.fromJson(json);
      expect(u.unifiedStatus, UnifiedWorkStatus.pendingPayment);
      expect(u.awardedRequestId, 'req-1');
    });
  });
}
