import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/features/booking/viewmodels/booking_view_model.dart';

class PaymentMethodScreen extends StatefulWidget {
  final double amount;
  final String packageTier;
  final String taskId;

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

    // Call the payment process
    final txnId = await viewModel.processPayment(
      amount: widget.amount,
      currency: 'USD',
      description: 'Task: ${widget.taskId} - Tier: ${widget.packageTier}',
    );

    if (txnId != null && mounted) {
      Navigator.pop(context, txnId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Payment Method', style: AppTypography.h3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.teal.withValues(alpha: 0.1),
              AppColors.lightTeal.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.p20),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTotalAmountCard(context),
                  const SizedBox(height: AppDimens.p24),
                  Text('Card Details', style: AppTypography.h3),
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
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimens.p20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total to Pay',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.mediumGrey,
                ),
              ),
              const SizedBox(height: AppDimens.p4),
              Text(
                PriceFormatter.formatPrice(widget.amount),
                style: AppTypography.h1.copyWith(color: AppColors.teal),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p12,
              vertical: AppDimens.p6,
            ),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimens.r20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Text(
              widget.packageTier,
              style: AppTypography.captionBold.copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardForm(BuildContext context) {
    return GlassContainer(
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
              if (value.replaceAll(' ', '').length < 16) {
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
    return Text(
      text,
      style: AppTypography.captionBold.copyWith(color: AppColors.mediumGrey),
    );
  }
}
