import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/booking_view_model.dart';

/// BookingSheet
///
/// Bottom sheet for requesting a booking on a given slot (A2 prototype).
/// In A3, will call BookingService.bookSlot(...).
class BookingSheet extends StatefulWidget {
  const BookingSheet({
    super.key,
    required this.slotId,
    required this.providerId,
    required this.taskId,
    required this.startUtc,
    required this.endUtc,
    required this.isBlocked,
    this.onSubmitted,
  });

  final String slotId;
  final String providerId;
  final String taskId;
  final DateTime startUtc;
  final DateTime endUtc;
  final bool isBlocked;
  final VoidCallback? onSubmitted;

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  final TextEditingController _noteCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  String _fmtRange(DateTime startUtc, DateTime endUtc) {
    final s = startUtc.toLocal();
    final e = endUtc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    String ymd(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
    String hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
    return '${ymd(s)}  ${hm(s)} → ${hm(e)}';
  }

  Future<void> _submit() async {
    if (widget.isBlocked) return;
    setState(() => _sending = true);
    try {
      final vm = context.read<BookingViewModel>();
      final note = _noteCtrl.text.trim();
      final res = await vm.bookSlot(
        taskId: widget.taskId,
        slotId: widget.slotId,
        providerId: widget.providerId,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      setState(() => _sending = false);
      if (res != null) {
        widget.onSubmitted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to request booking: ${vm.bookingsError ?? 'Unknown error'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          Row(
            children: [
              const Icon(Icons.event),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fmtRange(widget.startUtc, widget.endUtc),
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (widget.isBlocked || _sending) ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(widget.isBlocked ? 'Blocked' : 'Request Booking'),
            ),
          ),
        ],
      ),
    );
  }
}
