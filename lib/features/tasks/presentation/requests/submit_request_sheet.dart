import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/tasks/controllers/task_requests_controller.dart';

/// Shows a bottom sheet to submit a new offer for the given task.
Future<void> showSubmitRequestSheet(
  BuildContext context, {
  required String taskId,
  required TaskRequestController controller,
}) async {
  final priceCtrl = TextEditingController();
  final daysCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showModalBottomSheet(
    context: context,
    useRootNavigator: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final insets = MediaQuery.of(ctx).viewInsets;
      return Padding(
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            children: [
              const SizedBox(height: 8),
              const Text('Submit Offer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (IQD)'),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Days'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter days > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final price = double.parse(priceCtrl.text.trim());
                  final days = int.parse(daysCtrl.text.trim());
                  final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                  final ok = await controller.submitOfferUI(taskId: taskId, price: price, days: days, note: note);
                  if (ok && context.mounted) Navigator.of(ctx).pop();
                },
                icon: const Icon(Icons.send),
                label: const Text('Submit'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
