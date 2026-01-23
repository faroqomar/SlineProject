import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/app_enums.dart';
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
    this.packageTier,
    this.packagePrice,
    this.packageData,
  });

  final String slotId;
  final String providerId;
  final String taskId;
  final DateTime startUtc;
  final DateTime endUtc;
  final bool isBlocked;
  final VoidCallback? onSubmitted;

  final String? packageTier;
  final String? packagePrice;
  final Map<String, dynamic>? packageData;

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

      String? txnId;
      /*
      // Process Payment if involves a package
      if (widget.packagePrice != null &&
          (double.tryParse(
                    widget.packagePrice!.replaceAll(RegExp(r'[^0-9.]'), ''),
                  ) ??
                  0) >
              0) {
        
        // ... Payment logic commented out for testing ...
        
        // 1. SKIP PAYMENT SCREEN
        // 2. Set txnId to simulate success
        txnId = 'TEST_SKIPPED_PAYMENT';
      }
      */

      // Force TXN ID for testing if package exists
      if (widget.packagePrice != null) {
        txnId = 'TEST_SKIPPED_PAYMENT';
      }

      // Prepend package info to note
      final userNote = _noteCtrl.text.trim();
      final StringBuffer finalNote = StringBuffer();
      // ... (existing note logic remains same) ...
      if (widget.packageTier != null) {
        finalNote.writeln(
          'Package: ${widget.packageTier} (${widget.packagePrice})',
        );
        if (txnId != null) {
          finalNote.writeln('Payment TXN: $txnId (TEST VERIFIED)');
        }
        // Add other details if needed, e.g. delivery days
        if (widget.packageData != null) {
          final del = widget.packageData!['delivery'];
          if (del != null && del.toString().isNotEmpty) {
            finalNote.writeln('Delivery: $del days');
          }
        }
        finalNote.writeln('---');
      }
      if (userNote.isNotEmpty) {
        finalNote.write(userNote);
      }

      final res = await vm.bookSlot(
        taskId: widget.taskId,
        slotId: widget.slotId,
        providerId: widget.providerId,
        note: finalNote.isEmpty ? null : finalNote.toString(),
        // Force CONFIRMED status for testing
        status: BookingStatus.confirmed,
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
            backgroundColor: AppColors.lightRed,
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
          if (widget.packageTier != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.packageTier} Package',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Price: ${widget.packagePrice}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

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
