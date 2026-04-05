import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';

/// Displays the order summary card for the payment checkout screen,
/// including service name, optional package/delivery/due info, and total price.
class PaymentOrderSummaryCard extends StatelessWidget {
  const PaymentOrderSummaryCard({
    super.key,
    required this.taskTitle,
    required this.price,
    required this.cs,
    this.packageTier,
    this.deliveryDays,
    this.estimatedDueAt,
  });

  final String taskTitle;
  final double price;
  final AppColorScheme cs;
  final String? packageTier;
  final int? deliveryDays;
  final DateTime? estimatedDueAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: cs.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: cs.text.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: AppTypography.h4.copyWith(color: cs.text),
          ),
          const SizedBox(height: AppDimens.p12),
          _summaryRow('Service', taskTitle),
          if (packageTier != null) ...[
            const SizedBox(height: AppDimens.p8),
            _summaryRow('Package', packageTier!),
          ],
          if (deliveryDays != null) ...[
            const SizedBox(height: AppDimens.p8),
            _summaryRow('Delivery', '$deliveryDays days'),
          ],
          if (estimatedDueAt != null) ...[
            const SizedBox(height: AppDimens.p8),
            _summaryRow('Due', formatUtcToLocal(estimatedDueAt!)),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.h3.copyWith(color: cs.text),
              ),
              Text(
                PriceFormatter.formatPrice(price),
                style: AppTypography.h3.copyWith(
                  color: AppColors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: cs.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: cs.text,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
