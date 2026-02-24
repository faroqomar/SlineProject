import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/features/work/models/unified_work_item_model.dart';

Map<String, dynamic> _unifiedWorkItemJson({Map<String, dynamic>? overrides}) {
  final data = <String, dynamic>{
    'id': 'uwi-1',
    'source_type': 'booking',
    'source_status': 'source_status_kept_raw',
    'unified_status': 'paid_request_pending',
    'title': 'Booking Work Item',
    'price': 100,
    'client_id': 'client-1',
    'freelancer_id': 'freelancer-1',
    'revisions_total': 3,
    'revisions_used': 1,
  };
  if (overrides != null) {
    data.addAll(overrides);
  }
  return data;
}

void main() {
  group('UnifiedWorkItemModel T34', () {
    test(
      'T34 UnifiedWorkItemModel.fromJson maps paid_request_pending to requestPending',
      () {
        final item = UnifiedWorkItemModel.fromJson(_unifiedWorkItemJson());

        expect(item.unifiedStatus, UnifiedWorkStatus.requestPending);
        expect(item.sourceStatus, 'source_status_kept_raw');
      },
    );
  });
}
