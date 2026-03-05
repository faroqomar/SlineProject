// Widget test for proposal payment screen (proposals module entry).
// Implementation is TenderPaymentScreen; VM and coordinator same as tasks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/services/tender_payment_coordinator.dart';
import 'package:sline_app/features/proposals/view/proposal_payment_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/tender_payment_view_model.dart';

void main() {
  group('ProposalPaymentScreen (proposals entry)', () {
    testWidgets('renders order summary and pay button', (tester) async {
      final coordinator = TenderPaymentCoordinator(
        taskService: _StubTaskService(),
        paymentService: _StubPaymentService(),
      );
      final vm = TenderPaymentViewModel(
        coordinator: coordinator,
        requestId: 'req-1',
        taskTitle: 'Proposal Task',
        freelancerName: 'Freelancer',
        amount: 75.0,
        paymentDeadline: DateTime.now().add(const Duration(hours: 24)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TenderPaymentViewModel>.value(
            value: vm,
            child: const TenderPaymentScreen(),
          ),
        ),
      );

      expect(find.text('Complete Payment'), findsOneWidget);
      expect(find.text('Proposal Task'), findsOneWidget);
      expect(find.text('Freelancer'), findsAtLeastNWidgets(1));
      expect(find.text('Order Summary'), findsOneWidget);
    });
  });
}

class _StubTaskService implements TaskService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _StubPaymentService implements PaymentService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
