import 'package:flutter/material.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/features/tasks/services/task_requests_service.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/core/utils/format_price.dart' as price_utils;
/// Shows a bottom sheet to submit a new offer for the given task.
Future<void> showSubmitRequestSheet(
  BuildContext context, {
  required String taskId,
  required TaskRequestsViewModel controller,
}) async {
  final priceCtrl = TextEditingController();
  final daysCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Helper to load existing active offer for the current user
  Future<TaskRequest?> loadExistingActiveOffer(String taskId) async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final rows = await client
          .from('task_requests')
          .select()
          .eq('task_id', taskId)
          .eq('freelancer_id', uid)
          .is_('deleted_at', null)
          .eq('status', 'pending')
          .limit(1);
      if (rows == null || rows.isEmpty) return null;
      return TaskRequest.fromMap(rows.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Helper to show confirm replace dialog
  Future<bool> confirmReplaceDialog(BuildContext ctx, {required TaskRequest existing, required int newPriceCents, required int newDays, String? newNote}) async {
    return await showDialog<bool>(
      context: ctx,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text('Replace your existing offer?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You already have an active offer for this task.'),
              const SizedBox(height: 12),
              Text('Current: ${price_utils.PriceFormatter.formatPrice(existing.price as double)} / ${existing.days} days'),
              if ((existing.note ?? '').isNotEmpty) Text('Note: ${existing.note}'),
              const SizedBox(height: 12),
              Text('New: ${price_utils.PriceFormatter.formatPrice(newPriceCents as double)} / $newDays days'),
              if ((newNote ?? '').isNotEmpty) Text('Note: $newNote'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Replace')),
          ],
        );
      },
    ) ?? false;
  }

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
                  final messenger = ScaffoldMessenger.of(ctx);
                  final navigator = Navigator.of(ctx);
                  final tasksService = ctx.read<TaskRequestsService>();
                  if (!formKey.currentState!.validate()) return;
                  final priceDouble = double.parse(priceCtrl.text.trim());
                  final priceCents = (priceDouble).toInt(); // assuming cents/int in DB
                  final days = int.parse(daysCtrl.text.trim());
                  final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();

                  // Check if there is an existing active offer
                  final existing = await loadExistingActiveOffer(taskId);

                  if (existing != null) {
                    // Ask user to confirm replacement
                    if (!ctx.mounted) return;
                    final confirmed = await confirmReplaceDialog(
                      ctx,
                      existing: existing,
                      newPriceCents: priceCents,
                      newDays: days,
                      newNote: note,
                    );
                    if (!confirmed) return;

                    // Replace via service RPC
                    try {
                      final replaced = await tasksService.replaceOffer(
                        taskId: taskId,
                        price: priceDouble,
                        days: days,
                        note: note,
                      );
                      if (!ctx.mounted) return;
                      messenger.showSnackBar(const SnackBar(content: Text('Offer replaced successfully.')));
                      await controller.loadForTask(taskId);
                      if (!ctx.mounted) return;
                      navigator.pop(replaced);
                    } catch (e) {
                      if (!ctx.mounted) return;
                      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  } else {
                    // First time submit
                    final ok = await controller.submitOfferUI(taskId: taskId, price: priceDouble, days: days, note: note);
                    if (!ctx.mounted) return;
                    if (ok) {
                      navigator.pop();
                    }
                  }
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
