import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';

/// Legacy demo payment-method form used by booking package flows.
class PaymentMethodScreen extends StatefulWidget {
  /// Amount to pay.
  final double amount;

  /// Selected package tier label.
  final String packageTier;

  /// Task identifier forwarded to the existing payment delegate.
  final String taskId;

  /// Creates the payment method route.
  const PaymentMethodScreen({
    super.key,
    required this.amount,
    required this.packageTier,
    required this.taskId,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<BookingViewModel>();
    AppLogger.i(
      'Payment method submit requested',
      tag: 'Payment',
      json: <String, dynamic>{
        'has_package': widget.packageTier.isNotEmpty,
        'package_tier': widget.packageTier,
      },
    );

    final txnId = await viewModel.processPayment(
      amount: widget.amount,
      currency: 'USD',
      description: 'Booking package payment - Tier: ${widget.packageTier}',
    );

    if (txnId != null && mounted) {
      Navigator.pop(context, txnId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingViewModel>();
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;

    return Scaffold(
      backgroundColor: amber.page,
      appBar: AppBar(
        title: Text(
          'Payment Method',
          style: typography.sectionTitle.copyWith(color: amber.text),
        ),
        centerTitle: true,
        backgroundColor: amber.page,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: amber.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.p20),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTotalAmountCard(context),
                const SizedBox(height: AppDimens.p24),
                Text(
                  'Card Details',
                  style: typography.sectionTitle.copyWith(color: amber.text),
                ),
                const SizedBox(height: AppDimens.p16),
                _buildCreditCardForm(context),
                const SizedBox(height: AppDimens.p32),
                AppButton(
                  text: 'Pay ${PriceFormatter.formatPrice(widget.amount)}',
                  isLoading: viewModel.isProcessingPayment,
                  onPressed: _processPayment,
                ),
                const SizedBox(height: AppDimens.p16),
                Center(
                  child: Text(
                    'This is a demo secure environment',
                    style: typography.bodySmall.copyWith(color: amber.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard(BuildContext context) {
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total to Pay',
                style: typography.bodySmall.copyWith(color: amber.muted),
              ),
              const SizedBox(height: AppDimens.p4),
              Text(
                PriceFormatter.formatPrice(widget.amount),
                style: typography.moneyMedium.copyWith(color: amber.primary),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p12,
              vertical: AppDimens.p6,
            ),
            decoration: BoxDecoration(
              color: amber.warningMuted,
              borderRadius: BorderRadius.circular(AppDimens.r20),
              border: Border.all(color: amber.warning.withValues(alpha: 0.5)),
            ),
            child: Text(
              widget.packageTier,
              style: typography.chip.copyWith(color: amber.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardForm(BuildContext context) {
    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Card Number'),
          const SizedBox(height: AppDimens.p8),
          AppTextField(
            controller: _cardNumberController,
            hintText: '0000 0000 0000 0000',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final cleaned = value.replaceAll(' ', '');
              if (cleaned.length < 13 ||
                  cleaned.length > 19 ||
                  !_isValidLuhn(cleaned)) {
                return 'Invalid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimens.p16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Expiry Date'),
                    const SizedBox(height: AppDimens.p8),
                    AppTextField(
                      controller: _expiryController,
                      hintText: 'MM/YY',
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final expiryPattern = RegExp(
                          r'^(\d{2})/(\d{2}|\d{4})$',
                        );
                        final match = expiryPattern.firstMatch(value.trim());
                        if (match == null) return 'Invalid format (MM/YY)';

                        final month = int.tryParse(match.group(1)!);
                        final rawYear = int.tryParse(match.group(2)!);
                        if (month == null ||
                            rawYear == null ||
                            month < 1 ||
                            month > 12) {
                          return 'Invalid format (MM/YY)';
                        }

                        final year = rawYear < 100 ? 2000 + rawYear : rawYear;
                        final expiryEnd = DateTime(
                          year,
                          month + 1,
                          0,
                          23,
                          59,
                          59,
                        );
                        if (expiryEnd.isBefore(DateTime.now())) {
                          return 'Card expired';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('CVV'),
                    const SizedBox(height: AppDimens.p8),
                    AppTextField(
                      controller: _cvvController,
                      hintText: '123',
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (value.length < 3) return 'Invalid CVV';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p16),
          _buildLabel('Cardholder Name'),
          const SizedBox(height: AppDimens.p8),
          AppTextField(
            controller: _nameController,
            hintText: 'John Doe',
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    const amber = AmberDuskTokens.colors;
    const typography = AmberDuskTokens.typography;
    return Text(text, style: typography.chip.copyWith(color: amber.muted));
  }

  bool _isValidLuhn(String digits) {
    if (!RegExp(r'^\d+$').hasMatch(digits)) return false;
    var sum = 0;
    var doubleDigit = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var digit = int.parse(digits[i]);
      if (doubleDigit) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleDigit = !doubleDigit;
    }
    return sum % 10 == 0;
  }
}
