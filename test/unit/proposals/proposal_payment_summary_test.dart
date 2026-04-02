import 'package:flutter_test/flutter_test.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';

void main() {
  group('ProposalPaymentSummary', () {
    test('constructs with required fields', () {
      final deadline = DateTime.utc(2026, 3, 10, 12, 0);
      final s = ProposalPaymentSummary(
        requestId: 'req-1',
        taskId: 'task-1',
        taskTitle: 'Build app',
        freelancerName: 'Jane',
        amount: 150.0,
        paymentDeadline: deadline,
      );
      expect(s.requestId, 'req-1');
      expect(s.taskId, 'task-1');
      expect(s.taskTitle, 'Build app');
      expect(s.freelancerName, 'Jane');
      expect(s.amount, 150.0);
      expect(s.paymentDeadline, deadline);
    });

    test('paymentDeadline can be null', () {
      final s = const ProposalPaymentSummary(
        requestId: 'req-2',
        taskId: 'task-2',
        taskTitle: 'Task',
        freelancerName: 'Bob',
        amount: 99.0,
      );
      expect(s.paymentDeadline, isNull);
    });
  });
}
