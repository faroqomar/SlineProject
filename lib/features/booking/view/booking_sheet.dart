import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// Data returned from BookingSheet when user taps "Request Booking".
/// The parent screen handles navigation to the payment checkout.
class BookingSheetResult {
  const BookingSheetResult({required this.note, required this.price});
  final String? note;
  final double price;
}

/// BookingSheet
///
/// Bottom sheet for requesting a booking on a given slot.
/// Returns a [BookingSheetResult] via Navigator.pop when the user confirms.
/// The PARENT screen is responsible for navigating to PaymentCheckoutScreen.
class BookingSheet extends StatefulWidget {
  const BookingSheet({
    super.key,
    required this.slotId,
    required this.providerId,
    required this.taskId,
    required this.startUtc,
    required this.endUtc,
    required this.isBlocked,
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

  final String? packageTier;
  final String? packagePrice;
  final Map<String, dynamic>? packageData;

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  final TextEditingController _noteCtrl = TextEditingController();

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

  void _submit() {
    if (widget.isBlocked) return;

    // Build note
    final userNote = _noteCtrl.text.trim();
    final StringBuffer finalNote = StringBuffer();
    if (widget.packageTier != null) {
      finalNote.writeln(
        'Package: ${widget.packageTier} (${widget.packagePrice})',
      );
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

    // Parse price
    double price = 100.0;
    if (widget.packagePrice != null) {
      final parsed = double.tryParse(
        widget.packagePrice!.replaceAll(RegExp(r'[^0-9.]'), ''),
      );
      if (parsed != null && parsed > 0) price = parsed;
    }

    // Return result to parent — parent handles navigation
    Navigator.of(context).pop(
      BookingSheetResult(
        note: finalNote.isEmpty ? null : finalNote.toString(),
        price: price,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.p16,
        right: AppDimens.p16,
        top: AppDimens.p12,
        bottom: AppDimens.p16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: cs.primary),
              const SizedBox(width: AppDimens.p8),
              Expanded(
                child: Text(
                  _fmtRange(widget.startUtc, widget.endUtc),
                  style: AppTypography.h4.copyWith(color: cs.text),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          if (widget.packageTier != null) ...[
            const SizedBox(height: AppDimens.p12),
            Container(
              padding: const EdgeInsets.all(AppDimens.p12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.r8),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: cs.primary),
                  const SizedBox(width: AppDimens.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.packageTier} Package',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.text,
                          ),
                        ),
                        Text(
                          'Price: ${widget.packagePrice}',
                          style: AppTypography.bodySmall.copyWith(
                            color: cs.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppDimens.p12),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            style: TextStyle(color: cs.text),
            decoration: InputDecoration(
              labelText: 'Note (optional)',
              labelStyle: TextStyle(color: cs.textSecondary),
              filled: true,
              fillColor: cs.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                borderSide: BorderSide(color: cs.text.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                borderSide: BorderSide(color: cs.text.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.r12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: widget.isBlocked ? null : _submit,
              icon: const Icon(Icons.payment),
              label: Text(
                widget.isBlocked ? 'Blocked' : 'Proceed to Payment',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                disabledBackgroundColor: cs.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.r12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
