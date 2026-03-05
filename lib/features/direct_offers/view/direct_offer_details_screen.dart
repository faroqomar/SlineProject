import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/features/direct_offers/viewmodels/direct_offer_details_view_model.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/features/booking/view/payment_webview_screen.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';

/// Details screen for a direct offer: view info, Pay (wallet/card), Cancel, Open chat.
class DirectOfferDetailsScreen extends StatelessWidget {
  const DirectOfferDetailsScreen({
    super.key,
    required this.offerId,
    this.conversationId,
  });

  final String offerId;
  final String? conversationId;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return ChangeNotifierProvider<DirectOfferDetailsViewModel>(
          create: (_) => DirectOfferDetailsViewModel(
            offerId: offerId,
            conversationId: conversationId,
            currentUserId: context.read<AuthSessionViewModel>().currentUserId,
            directOffersService: context.read<DirectOffersService>(),
            paymentService: context.read<PaymentService>(),
          )..loadOffer(),
          child: _DirectOfferDetailsContent(offerId: offerId),
        );
      },
    );
  }
}

class _DirectOfferDetailsContent extends StatefulWidget {
  const _DirectOfferDetailsContent({required this.offerId});

  final String offerId;

  @override
  State<_DirectOfferDetailsContent> createState() =>
      _DirectOfferDetailsContentState();
}

class _DirectOfferDetailsContentState
    extends State<_DirectOfferDetailsContent> {
  Future<void> _onPayWithCard(DirectOfferDetailsViewModel vm) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await vm.createPaymentForCard();
    if (!mounted) return;
    if (!result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not start payment')),
      );
      return;
    }
    final formUrl = result.formUrl!;
    final finishUrl = buildQiCardFinishUrlForRuntime();
    final callbackHosts = buildQiCardCallbackHosts(finishUrl: finishUrl);

    // Web: in-app WebView is not fully supported (NavigationDelegate etc. unimplemented).
    // Open payment in browser; user returns and can refresh the offer.
    if (kIsWeb) {
      final launched = await launchUrl(
        Uri.parse(formUrl),
        webOnlyWindowName: '_self',
      );
      if (!mounted) return;
      if (launched) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Complete payment in the browser. Return here and refresh the offer.',
            ),
          ),
        );
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open payment page.')),
        );
      }
      return;
    }

    final returnArgs = await navigator.push<PaymentReturnArgs?>(
      MaterialPageRoute<PaymentReturnArgs?>(
        builder: (_) => PaymentWebViewScreen(
          initialUrl: formUrl,
          callbackHosts: callbackHosts,
          expectedOfferId: widget.offerId,
          expectedCorrelationId: result.correlationId,
        ),
      ),
    );
    if (!mounted) return;
    if (returnArgs != null && returnArgs.isSuccess) {
      final vmAfter = context.read<DirectOfferDetailsViewModel>();
      final paymentRequestId =
          returnArgs.rawUri.queryParameters['payment_request_id'] ??
          result.paymentRequestId;
      if (paymentRequestId != null && paymentRequestId.isNotEmpty) {
        try {
          await vmAfter.recoverPaymentAfterCallback(paymentRequestId);
        } catch (e) {
          await vmAfter.loadOffer();
        }
      } else {
        await vmAfter.loadOffer();
      }
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment completed.')),
      );
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DirectOfferDetailsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.error != null || vm.offer == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Custom offer'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.p24),
                child: Text(
                  vm.error ?? 'Offer not found.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final offer = vm.offer!;
        final title = offer.title?.trim().isNotEmpty == true
            ? offer.title!
            : 'Custom offer';

        return Scaffold(
          backgroundColor: context.colorScheme.phoneBackground,
          appBar: AppBar(
            title: Text(title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, true),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.p16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.h3.copyWith(
                            color: context.colorScheme.text,
                          ),
                        ),
                        if (offer.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: AppDimens.p12),
                          Text(
                            offer.description!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: context.colorScheme.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppDimens.p16),
                        _row(
                          'Price',
                          PriceFormatter.formatPrice(offer.price.toDouble()),
                        ),
                        _row('Delivery (days)', '${offer.days}'),
                        _row(
                          'Status',
                          offer.isAcceptedPendingPayment
                              ? 'PENDING PAYMENT'
                              : offer.status.toUpperCase().replaceAll('_', ' '),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.p24),
                if (vm.canOpenChat)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.p16),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final convId = vm.effectiveConversationId;
                        if (convId != null) {
                          await context
                              .read<DeepLinkService>()
                              .openConversation(context, convId);
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text('Open chat'),
                    ),
                  ),
                if (vm.canCancel) ...[
                  AppButton(
                    onPressed: vm.cancelInProgress
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Cancel offer?'),
                                content: const Text(
                                  'This will cancel the accepted offer. You can still open the chat to request a new offer.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Keep'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.lightRed,
                                    ),
                                    child: const Text('Cancel offer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              try {
                                await vm.cancelOffer();
                                if (!mounted) return;
                                navigator.pop(true);
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e is Exception
                                          ? e.toString()
                                          : 'Failed to cancel',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    text: vm.cancelInProgress ? 'Canceling…' : 'Cancel offer',
                    isPrimary: false,
                    isLoading: vm.cancelInProgress,
                  ),
                  const SizedBox(height: AppDimens.p12),
                ],
                if (vm.canPay) ...[
                  AppButton(
                    onPressed: vm.cardPaymentInProgress
                        ? null
                        : () => _onPayWithCard(vm),
                    text: vm.cardPaymentInProgress
                        ? 'Opening…'
                        : 'Pay (QiCard)',
                    isPrimary: true,
                    isLoading: vm.cardPaymentInProgress,
                  ),
                ],
                if (vm.canMarkDelivered) ...[
                  const SizedBox(height: AppDimens.p12),
                  AppButton(
                    onPressed: vm.markDeliveredInProgress
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await vm.markDelivered();
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Work marked as delivered.'),
                                ),
                              );
                              navigator.pop(true);
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e is Exception
                                        ? e.toString()
                                        : 'Failed to submit work',
                                  ),
                                ),
                              );
                            }
                          },
                    text: vm.markDeliveredInProgress
                        ? 'Submitting…'
                        : 'Submit work',
                    isPrimary: true,
                    isLoading: vm.markDeliveredInProgress,
                  ),
                ],
                if (vm.canComplete) ...[
                  const SizedBox(height: AppDimens.p12),
                  AppButton(
                    onPressed: vm.completeInProgress
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await vm.completeOffer();
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Payment released.'),
                                ),
                              );
                              navigator.pop(true);
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e is Exception
                                        ? e.toString()
                                        : 'Failed to complete',
                                  ),
                                ),
                              );
                            }
                          },
                    text: vm.completeInProgress
                        ? 'Releasing…'
                        : 'Approve & release payment',
                    isPrimary: true,
                    isLoading: vm.completeInProgress,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: context.colorScheme.text,
            ),
          ),
        ],
      ),
    );
  }
}
