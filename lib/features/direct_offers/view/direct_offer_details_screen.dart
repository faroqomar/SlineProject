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
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';

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
          paymentIntentId: result.intentId,
          paymentIntentStatusStream: result.intentId != null
              ? vm.streamPaymentIntentStatus(result.intentId!)
              : null,
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
                _DirectOfferDisputeBanner(offerId: widget.offerId),
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
                if ((offer.isActive || offer.isDelivered) &&
                    (offer.clientId == vm.currentUserId ||
                        offer.freelancerId == vm.currentUserId))
                  _ReportIssueGuardDirectOffer(
                    offerId: widget.offerId,
                    defendantId: offer.clientId == vm.currentUserId
                        ? offer.freelancerId
                        : offer.clientId,
                    onSubmitted: () => vm.loadOffer(),
                  ),
                if (vm.canComplete) ...[
                  const SizedBox(height: AppDimens.p12),
                  _ApproveWithDisputeGuard(
                    offerId: widget.offerId,
                    completeInProgress: vm.completeInProgress,
                    onApprove: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await vm.completeOffer();
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Payment released.')),
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

/// Shows "Dispute under review" or "Work frozen — in dispute" when direct offer has an open/active dispute.
class _DirectOfferDisputeBanner extends StatelessWidget {
  const _DirectOfferDisputeBanner({required this.offerId});

  final String offerId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForDirectOffer(
        offerId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<String?>(
          future: context
              .read<SafetyViewModel>()
              .getDisputeStatusForDirectOffer(offerId),
          builder: (context, statusSnapshot) {
            final status = statusSnapshot.data;
            final text = status == 'active'
                ? 'Work frozen — in dispute.'
                : 'Dispute under review. Approve and release disabled.';
            return Padding(
              padding: const EdgeInsets.only(top: AppDimens.p24),
              child: GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: AppDimens.p8),
                      Expanded(
                        child: Text(
                          text,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.colorScheme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Shows Report Issue button when no open dispute; on tap shows reason dialog and submits via SafetyViewModel.
class _ReportIssueGuardDirectOffer extends StatelessWidget {
  const _ReportIssueGuardDirectOffer({
    required this.offerId,
    required this.defendantId,
    required this.onSubmitted,
  });

  final String offerId;
  final String defendantId;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForDirectOffer(
        offerId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final hasOpenDispute = snapshot.data ?? true;
        if (hasOpenDispute) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.p12),
          child: Center(
            child: TextButton(
              onPressed: () => _showDisputeDialog(context),
              child: Text(
                'Report Issue',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.lightRed,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDisputeDialog(BuildContext context) async {
    String draftReason = '';
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Issue'),
        content: TextField(
          maxLines: 4,
          onChanged: (value) => draftReason = value,
          decoration: const InputDecoration(
            hintText: 'Describe the problem with this offer',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, draftReason.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (!context.mounted || reason == null || reason.isEmpty) return;
    final safetyVm = context.read<SafetyViewModel>();
    final ok = await safetyVm.submitDispute(
      directOfferId: offerId,
      reason: reason,
      defendantId: defendantId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Dispute submitted.' : (safetyVm.error ?? 'Dispute failed.'),
        ),
      ),
    );
    if (ok) onSubmitted();
  }
}

/// Disables Approve & release when an open dispute exists for this direct offer.
class _ApproveWithDisputeGuard extends StatelessWidget {
  const _ApproveWithDisputeGuard({
    required this.offerId,
    required this.completeInProgress,
    required this.onApprove,
  });

  final String offerId;
  final bool completeInProgress;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    if (completeInProgress) {
      return AppButton(
        text: 'Releasing…',
        onPressed: null,
        isPrimary: true,
        isLoading: true,
      );
    }
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForDirectOffer(
        offerId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppButton(text: 'Checking…', onPressed: null, isPrimary: true);
        }
        final hasOpenDispute = snapshot.data ?? true;
        return AppButton(
          text: 'Approve & release payment',
          onPressed: hasOpenDispute ? null : onApprove,
          isPrimary: true,
        );
      },
    );
  }
}
