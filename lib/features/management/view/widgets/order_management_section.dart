import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/management/models/work_log_scope.dart';
import 'package:sline_app/features/management/view/order_management_panel.dart';
import 'package:sline_app/features/management/viewmodels/order_management_view_model.dart';

class OrderManagementSection extends StatelessWidget {
  final WorkLogScope scope;
  final String currentUserId;
  final EdgeInsetsGeometry padding;

  const OrderManagementSection({
    super.key,
    required this.scope,
    required this.currentUserId,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ChangeNotifierProvider(
        create: (_) => OrderManagementViewModel(),
        child: OrderManagementPanel(scope: scope, currentUserId: currentUserId),
      ),
    );
  }
}
