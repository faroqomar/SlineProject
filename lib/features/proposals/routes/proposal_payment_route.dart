// Single entry point for opening the proposal payment screen from any launcher.
// Use [openProposalPayment] from Requests, Inbox, Work, Next Actions, Work Details.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/proposals/models/proposal_payment_summary.dart';
import 'package:sline_app/features/tasks/services/task_service.dart';
import 'package:sline_app/features/tasks/services/tender_payment_coordinator.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/tasks/view/tender_payment_screen.dart';
import 'package:sline_app/features/tasks/viewmodels/tender_payment_view_model.dart';

/// Opens the tender/proposal payment screen with the given summary.
/// Ensures one place for coordinator + ViewModel + screen construction.
/// [launcherSource] optional label for telemetry (e.g. 'inbox_tab', 'work_tab', 'requests_list').
Future<void> openProposalPayment(
  BuildContext context, {
  required ProposalPaymentSummary summary,
  String? launcherSource,
}) async {
  AppLogger.d(
    'Proposals: payment screen opened${launcherSource != null ? ' (from $launcherSource)' : ''}',
    tag: 'Proposals',
  );
  final taskService = context.read<TaskService>();
  final paymentService = context.read<PaymentService>();
  final coordinator = TenderPaymentCoordinator(
    taskService: taskService,
    paymentService: paymentService,
  );
  final deadline =
      summary.paymentDeadline ?? DateTime.now().add(const Duration(hours: 24));
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<TenderPaymentViewModel>(
        create: (_) => TenderPaymentViewModel(
          coordinator: coordinator,
          requestId: summary.requestId,
          taskTitle: summary.taskTitle,
          freelancerName: summary.freelancerName,
          amount: summary.amount,
          paymentDeadline: deadline,
        ),
        child: const TenderPaymentScreen(),
      ),
    ),
  );
}
