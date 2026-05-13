import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
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
    this.colors = AmberDuskTokens.colors,
    this.typography = AmberDuskTokens.typography,
    this.spacing = AmberDuskTokens.spacing,
  });

  final String taskTitle;
  final double price;
  final AppColorScheme cs;
  final String? packageTier;
  final int? deliveryDays;
  final DateTime? estimatedDueAt;

  /// Color tokens used by the summary card; defaults preserve existing callers.
  final AmberDuskColorTokens colors;

  /// Typography tokens used by the summary card; defaults preserve existing callers.
  final AmberDuskTypographyTokens typography;

  /// Spacing tokens used by the summary card; defaults preserve existing callers.
  final AmberDuskSpacingTokens spacing;

  @override
  Widget build(BuildContext context) {
    final amber = colors;
    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: amber.surface,
        borderRadius: BorderRadius.circular(spacing.moduleRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: typography.sectionTitle.copyWith(color: amber.text),
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
          Divider(height: AppDimens.p24, color: amber.heroDivider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: typography.body.copyWith(
                  color: amber.textSubtle,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Flexible(
                child: Text(
                  PriceFormatter.formatPrice(price),
                  style: typography.moneyMedium.copyWith(color: amber.primary),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    final amber = colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: typography.bodySmall.copyWith(color: amber.muted)),
        const SizedBox(width: AppDimens.p16),
        Flexible(
          child: Text(
            value,
            style: typography.bodySmall.copyWith(
              color: amber.text,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
