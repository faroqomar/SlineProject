import 'package:flutter/material.dart';
import '../../../models/task_request_model.dart';
import '../../../../../core/utils/format_price.dart';

/// One row/tile for a TaskRequest in the offers list.
class RequestTile extends StatelessWidget {
  final TaskRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const RequestTile({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = PriceFormatter.formatPrice(request.price);
    final subtitle = '${request.days} days • ${request.status.dbValue}';
    final canAct = request.isPending && onAccept != null && onReject != null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(priceText, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: canAct
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Accept',
                    icon: const Icon(Icons.check_circle),
                    onPressed: onAccept,
                  ),
                  IconButton(
                    tooltip: 'Reject',
                    icon: const Icon(Icons.cancel),
                    onPressed: onReject,
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
