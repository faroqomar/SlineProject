import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';

/// Bottom sheet to create a new availability slot (provider only).
class AddSlotSheet extends StatefulWidget {
  const AddSlotSheet({super.key, this.onCreated});
  final void Function(bool created)? onCreated;

  @override
  State<AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<AddSlotSheet> {
  DateTime? _startLocal;
  DateTime? _endLocal;
  bool _blocked = false;
  bool _sending = false;

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _startLocal = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickEnd() async {
    final base = _startLocal ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: base,
      lastDate: base.add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour + 1, minute: base.minute),
    );
    if (time == null) return;
    setState(() {
      _endLocal = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_startLocal == null || _endLocal == null) return;
    if (!_endLocal!.isAfter(_startLocal!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End must be after start')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final ctrl = context.read<BookingController>();
      final created = await ctrl.createSlot(
        startsAtUtc: _startLocal!.toUtc(),
        endsAtUtc: _endLocal!.toUtc(),
        isBlocked: _blocked,
      );
      if (!mounted) return;
      setState(() => _sending = false);
      if (created != null) {
        widget.onCreated?.call(true);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot created')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ctrl.slotsError ?? 'Failed to create slot')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Availability Slot', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStart,
                  icon: const Icon(Icons.schedule),
                  label: Text(_startLocal == null
                      ? 'Pick start'
                      : _startLocal.toString()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEnd,
                  icon: const Icon(Icons.schedule),
                  label: Text(_endLocal == null
                      ? 'Pick end'
                      : _endLocal.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _blocked,
            onChanged: (v) => setState(() => _blocked = v ?? false),
            title: const Text('Blocked (hold this time)'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Create Slot'),
            ),
          ),
        ],
      ),
    );
  }
}
