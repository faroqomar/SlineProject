import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/services/tender_payment_coordinator.dart';
import 'package:sline_app/features/tasks/view/tender_payment_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/tender_payment_view_model.dart';

void main() {
  group('TenderPaymentScreen', () {
    testWidgets('renders order summary and pay button', (tester) async {
      final coordinator = TenderPaymentCoordinator(
        taskService: _StubTaskService(),
        paymentService: _StubPaymentService(),
      );
      final vm = TenderPaymentViewModel(
        coordinator: coordinator,
        requestId: 'req-1',
        taskTitle: 'Test Task',
        freelancerName: 'Test Freelancer',
        amount: 50.0,
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
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('Test Freelancer'), findsOneWidget);
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
