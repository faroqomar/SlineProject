import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/config/payment_runtime_config.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/services/payment_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/utils/error_mapper.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/core/widgets/circle_icon_button.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';
import 'package:sline_app/features/booking/models/payment_return_args.dart';
import 'package:sline_app/features/booking/view/payment_webview_screen.dart';
import 'package:sline_app/features/direct_offers/models/direct_offer_model.dart';
import 'package:sline_app/features/direct_offers/services/direct_offers_service.dart';
import 'package:sline_app/features/direct_offers/viewmodels/direct_offer_details_view_model.dart';
import 'package:sline_app/features/safety/viewmodels/safety_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

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
          create: (_) {
            final viewModel = DirectOfferDetailsViewModel(
              offerId: offerId,
              conversationId: conversationId,
              currentUserId: context.read<AuthSessionViewModel>().currentUserId,
              directOffersService: context.read<DirectOffersService>(),
              paymentService: context.read<PaymentService>(),
            );
            unawaited(viewModel.loadOffer());
            return viewModel;
          },
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
        } on Exception catch (_) {
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
          return _DirectOfferLoadingScaffold(
            onBack: () => Navigator.pop(context),
          );
        }

        if (vm.error != null || vm.offer == null) {
          return _DirectOfferErrorScaffold(
            message: vm.error ?? 'Offer not found.',
            onRetry: () => unawaited(vm.loadOffer()),
          );
        }

        final offer = vm.offer!;
        final title = offer.title?.trim().isNotEmpty ?? false
            ? offer.title!
            : 'Custom offer';
        final statusColor = _statusColor(context, offer);
        final topInset = MediaQuery.paddingOf(context).top;

        return Scaffold(
          backgroundColor: AmberDuskColors.background,
          body: AmberDuskBackground(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AmberDuskSpacing.contentHorizontalPadding,
                      topInset + AppDimens.p64,
                      AmberDuskSpacing.contentHorizontalPadding,
                      AppDimens.p32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DirectOfferHeroCard(
                          title: title,
                          offer: offer,
                          statusColor: statusColor,
                        ),
                        const SizedBox(height: AppDimens.p16),
                        _DirectOfferLifecycleCard(
                          offer: offer,
                          currentUserId: vm.currentUserId,
                          statusColor: statusColor,
                        ),
                        if (offer.description?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: AppDimens.p16),
                          _DirectOfferDescriptionCard(
                            description: offer.description!,
                          ),
                        ],
                        _DirectOfferDisputeBanner(offerId: widget.offerId),
                      ],
                    ),
                  ),
                ),
                _DirectOfferFloatingBackButton(
                  onTap: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _DirectOfferActionPanel(
            offer: offer,
            vm: vm,
            onPayWithCard: () => _onPayWithCard(vm),
            onOpenChat: () => _openChat(vm),
            onCancelOffer: () => _confirmCancelOffer(vm),
            onMarkDelivered: () => _markDelivered(vm),
            onApprove: () => _approveAndRelease(vm),
          ),
        );
      },
    );
  }

  /// Opens the linked conversation without letting navigation logic leak into
  /// the offer ViewModel, which only exposes the effective conversation id.
  Future<void> _openChat(DirectOfferDetailsViewModel vm) async {
    final convId = vm.effectiveConversationId;
    if (convId == null) return;
    await context.read<DeepLinkService>().openConversation(context, convId);
  }

  /// Confirms destructive cancellation before delegating to the ViewModel.
  Future<void> _confirmCancelOffer(DirectOfferDetailsViewModel vm) async {
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
              backgroundColor: context.colorScheme.danger,
            ),
            child: const Text('Cancel offer'),
          ),
        ],
      ),
    );
    if ((confirm ?? false) && mounted) {
      try {
        await vm.cancelOffer();
        if (!mounted) return;
        navigator.pop(true);
      } on Exception catch (_) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    }
  }

  /// Marks freelancer delivery complete and returns to the caller for refresh.
  Future<void> _markDelivered(DirectOfferDetailsViewModel vm) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vm.markDelivered();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Work marked as delivered.')),
      );
      navigator.pop(true);
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(ErrorMapper.map(e))));
    }
  }

  /// Releases held payment after the dispute guard has allowed approval.
  Future<void> _approveAndRelease(DirectOfferDetailsViewModel vm) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vm.completeOffer();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment released.')),
      );
      navigator.pop(true);
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(ErrorMapper.map(e))));
    }
  }

  /// Map offer status to semantic color for the header band.
  Color _statusColor(BuildContext context, DirectOffer offer) {
    final colors = context.amberColors;
    if (offer.isAcceptedPendingPayment) return colors.warning;
    final status = offer.status.toLowerCase();
    switch (status) {
      case 'active':
      case 'in_progress':
        return colors.primary;
      case 'delivered':
        return colors.info;
      case 'completed':
        return colors.success;
      case 'canceled':
      case 'declined':
      case 'rejected':
      case 'refunded':
        return colors.danger;
      default:
        return colors.warning;
    }
  }
}

/// Full-screen loading state that keeps direct-offer deep links on the same
/// Amber Dusk surface as the loaded route.
class _DirectOfferLoadingScaffold extends StatelessWidget {
  const _DirectOfferLoadingScaffold({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmberDuskColors.background,
      body: AmberDuskBackground(
        child: Stack(
          children: [
            const Center(
              child: CircularProgressIndicator(color: AmberDuskColors.primary),
            ),
            _DirectOfferFloatingBackButton(onTap: onBack),
          ],
        ),
      ),
    );
  }
}

/// Floating route escape used instead of a standard app bar so the offer hero
/// remains the only title/status surface competing for attention.
class _DirectOfferFloatingBackButton extends StatelessWidget {
  const _DirectOfferFloatingBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppDimens.p8,
      left: AppDimens.p16,
      child: CircleIconButton(
        icon: Icons.arrow_back,
        tooltip: 'Back',
        size: AppDimens.p40,
        onTap: onTap,
      ),
    );
  }
}

/// Error state with a retry action so transient payment or deep-link failures
/// do not strand the user on static copy.
class _DirectOfferErrorScaffold extends StatelessWidget {
  const _DirectOfferErrorScaffold({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmberDuskColors.background,
      body: AmberDuskBackground(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.p24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.cardMaxWidth,
                  ),
                  child: AppCardContainer(
                    padding: const EdgeInsets.all(AppDimens.p20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AmberDuskColors.rust,
                          size: AppDimens.iconSizeLarge,
                        ),
                        const SizedBox(height: AppDimens.p12),
                        Text(
                          'Offer unavailable',
                          style: AmberDuskTokens.typography.sectionTitle
                              .copyWith(color: AmberDuskColors.text),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.p8),
                        Text(
                          message,
                          style: AmberDuskTokens.typography.body.copyWith(
                            color: AmberDuskColors.textSubtle,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimens.p16),
                        AppButton(
                          onPressed: onRetry,
                          text: 'Retry',
                          icon: Icons.refresh,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _DirectOfferFloatingBackButton(onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

/// Hero summary for price, status, and delivery duration, keeping the most
/// decision-critical offer facts visible before secondary contract metadata.
class _DirectOfferHeroCard extends StatelessWidget {
  const _DirectOfferHeroCard({
    required this.title,
    required this.offer,
    required this.statusColor,
  });

  final String title;
  final DirectOffer offer;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    const typography = AmberDuskTokens.typography;
    final statusLabel = _offerStatusLabel(offer);

    return Semantics(
      label: 'Custom offer, $title, $statusLabel',
      child: DecoratedBox(
        decoration: AmberDuskMaterial.bookingCardDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: AppLayout.iconStandard,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppDimens.p8),
                        Text(
                          'CUSTOM OFFER',
                          style: typography.chip.copyWith(color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  _OfferStatusPill(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: AppDimens.p20),
              Text(
                title,
                style: typography.bookingName.copyWith(
                  color: AmberDuskColors.heroText,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.p20),
              Text(
                'OFFER PRICE',
                style: typography.chip.copyWith(
                  color: AmberDuskColors.heroMuted,
                ),
              ),
              const SizedBox(height: AppDimens.p4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      PriceFormatter.formatPrice(offer.price.toDouble()),
                      style: typography.moneyMedium.copyWith(
                        color: AmberDuskColors.heroText,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppDimens.p12),
                  _OfferMetricPill(
                    icon: Icons.event_available_outlined,
                    label: 'DAYS',
                    value: '${offer.days}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Structured contract metadata that turns raw status and timestamp fields
/// into scan-friendly rows without adding new data dependencies.
class _DirectOfferLifecycleCard extends StatelessWidget {
  const _DirectOfferLifecycleCard({
    required this.offer,
    required this.currentUserId,
    required this.statusColor,
  });

  final DirectOffer offer;
  final String? currentUserId;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    const typography = AmberDuskTokens.typography;
    final nextStep = _offerNextStep(offer);

    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppDimens.p40,
                height: AppDimens.p40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(offer),
                  color: statusColor,
                  size: AppLayout.iconStandard,
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current stage',
                      style: typography.chip.copyWith(
                        color: AmberDuskColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p4),
                    Text(
                      _offerStageTitle(offer),
                      style: typography.sectionTitle.copyWith(
                        color: AmberDuskColors.text,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p6),
                    Text(
                      nextStep,
                      style: typography.bodySmall.copyWith(
                        color: AmberDuskColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(
            height: AppDimens.p32,
            thickness: AppDimens.hairlineDivider,
            color: AmberDuskMaterial.rowSeparator,
          ),
          _OfferDetailRow(
            label: 'Your role',
            value: _roleLabel(offer, currentUserId),
            icon: Icons.person_outline,
          ),
          _OfferDetailRow(
            label: 'Payment',
            value: _paymentStatusLabel(offer.paymentStatus),
            icon: Icons.account_balance_wallet_outlined,
          ),
          _OfferDetailRow(
            label: 'Created',
            value: formatUtcToLocal(offer.createdAt),
            icon: Icons.calendar_today_outlined,
          ),
          _OfferDetailRow(
            label: 'Updated',
            value: formatUtcToLocal(offer.updatedAt),
            icon: Icons.update,
          ),
          if (offer.paymentExpiresAt != null)
            _OfferDetailRow(
              label: 'Payment deadline',
              value: formatUtcToLocal(offer.paymentExpiresAt!),
              icon: Icons.timer_outlined,
            ),
          if (offer.deliveredAt != null)
            _OfferDetailRow(
              label: 'Delivered',
              value: formatUtcToLocal(offer.deliveredAt!),
              icon: Icons.outbox_outlined,
            ),
          if (offer.reviewExpiresAt != null)
            _OfferDetailRow(
              label: 'Review by',
              value: formatUtcToLocal(offer.reviewExpiresAt!),
              icon: Icons.rate_review_outlined,
            ),
        ],
      ),
    );
  }
}

/// Scope card shown only when the offer includes a written description.
class _DirectOfferDescriptionCard extends StatelessWidget {
  const _DirectOfferDescriptionCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    const typography = AmberDuskTokens.typography;

    return AppCardContainer(
      padding: const EdgeInsets.all(AppDimens.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notes_outlined,
                size: AppLayout.iconStandard,
                color: AmberDuskColors.primary,
              ),
              const SizedBox(width: AppDimens.p8),
              Text(
                'Scope',
                style: typography.sectionTitle.copyWith(
                  color: AmberDuskColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p12),
          Text(
            description,
            style: typography.body.copyWith(color: AmberDuskColors.textSubtle),
          ),
        ],
      ),
    );
  }
}

/// Minimal sticky dock that keeps the main next step reachable without adding
/// a heavy navigation band under the direct-offer content.
class _DirectOfferActionPanel extends StatelessWidget {
  const _DirectOfferActionPanel({
    required this.offer,
    required this.vm,
    required this.onPayWithCard,
    required this.onOpenChat,
    required this.onCancelOffer,
    required this.onMarkDelivered,
    required this.onApprove,
  });

  final DirectOffer offer;
  final DirectOfferDetailsViewModel vm;
  final VoidCallback onPayWithCard;
  final VoidCallback onOpenChat;
  final VoidCallback onCancelOffer;
  final VoidCallback onMarkDelivered;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final canReport = _canReportIssue(offer, vm.currentUserId);
    final primaryAction = _buildPrimaryAction();
    final secondaryActions = <Widget>[
      if (vm.canOpenChat)
        CircleIconButton(
          icon: Icons.chat_bubble_outline,
          tooltip: 'Open chat',
          size: AppDimens.p40,
          onTap: onOpenChat,
        ),
      if (vm.canCancel)
        CircleIconButton(
          icon: Icons.cancel_outlined,
          tooltip: 'Cancel offer',
          iconColor: AmberDuskColors.rust,
          size: AppDimens.p40,
          onTap: vm.cancelInProgress ? () {} : onCancelOffer,
        ),
      if (canReport)
        SizedBox(
          width: AppLayout.minTouchTarget,
          height: AppLayout.minTouchTarget,
          child: Center(
            child: _ReportIssueGuardDirectOffer(
              offerId: offer.id,
              defendantId: _defendantId(offer, vm.currentUserId),
              onSubmitted: () => unawaited(vm.loadOffer()),
              reserveSpace: true,
              builder: (context, onPressed) => CircleIconButton(
                icon: Icons.warning_amber_rounded,
                tooltip: 'Report issue',
                iconColor: AmberDuskColors.rust,
                size: AppDimens.p40,
                onTap: onPressed,
              ),
            ),
          ),
        ),
    ];

    if (primaryAction == null && secondaryActions.isEmpty) {
      return const SizedBox.shrink();
    }

    final spacedSecondaryActions = <Widget>[];
    for (final action in secondaryActions) {
      if (spacedSecondaryActions.isNotEmpty) {
        spacedSecondaryActions.add(const SizedBox(width: AppDimens.p6));
      }
      spacedSecondaryActions.add(action);
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AmberDuskSpacing.contentHorizontalPadding,
          AppDimens.p6,
          AmberDuskSpacing.contentHorizontalPadding,
          AppDimens.p10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (primaryAction != null) Expanded(child: primaryAction),
            if (primaryAction != null && spacedSecondaryActions.isNotEmpty)
              const SizedBox(width: AppDimens.p8),
            ...spacedSecondaryActions,
          ],
        ),
      ),
    );
  }

  /// Builds only the highest-priority primary action so the dock stays small
  /// and the user always sees one clear next step.
  Widget? _buildPrimaryAction() {
    if (vm.canPay) {
      return AppButton(
        onPressed: vm.cardPaymentInProgress ? null : onPayWithCard,
        text: vm.cardPaymentInProgress ? 'Opening…' : 'Pay (QiCard)',
        isLoading: vm.cardPaymentInProgress,
        icon: Icons.payment,
        height: AppDimens.publicProfileActionButtonHeight,
      );
    }

    if (vm.canMarkDelivered) {
      return AppButton(
        onPressed: vm.markDeliveredInProgress ? null : onMarkDelivered,
        text: vm.markDeliveredInProgress ? 'Submitting…' : 'Submit work',
        isLoading: vm.markDeliveredInProgress,
        icon: Icons.outbox_outlined,
        height: AppDimens.publicProfileActionButtonHeight,
      );
    }

    if (vm.canComplete) {
      return _ApproveWithDisputeGuard(
        offerId: offer.id,
        completeInProgress: vm.completeInProgress,
        onApprove: onApprove,
        height: AppDimens.publicProfileActionButtonHeight,
      );
    }

    return null;
  }
}

/// Compact semantic status pill used in the hero card.
class _OfferStatusPill extends StatelessWidget {
  const _OfferStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p10,
        vertical: AppDimens.p6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AmberDuskSpacing.pillRadius),
      ),
      child: Text(
        label,
        style: AmberDuskTokens.typography.chip.copyWith(color: color),
      ),
    );
  }
}

/// Hero-side metric chip for short facts such as delivery duration.
class _OfferMetricPill extends StatelessWidget {
  const _OfferMetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const typography = AmberDuskTokens.typography;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p12,
        vertical: AppDimens.p10,
      ),
      decoration: BoxDecoration(
        color: AmberDuskColors.heroChip,
        borderRadius: BorderRadius.circular(AmberDuskSpacing.moduleRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AmberDuskColors.heroMuted,
            size: AppLayout.iconTiny,
          ),
          const SizedBox(width: AppDimens.p6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: typography.chip.copyWith(
                  color: AmberDuskColors.heroText,
                ),
              ),
              Text(
                label,
                style: typography.chip.copyWith(
                  color: AmberDuskColors.heroMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One row of secondary direct-offer metadata.
class _OfferDetailRow extends StatelessWidget {
  const _OfferDetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const typography = AmberDuskTokens.typography;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AmberDuskColors.muted,
            size: AppLayout.iconStandard,
          ),
          const SizedBox(width: AppDimens.p12),
          Expanded(
            child: Text(
              label,
              style: typography.bodySmall.copyWith(
                color: AmberDuskColors.muted,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.p12),
          Flexible(
            child: Text(
              value,
              style: typography.bodySmall.copyWith(
                color: AmberDuskColors.text,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Display label for direct-offer status, including the accepted/unpaid state
/// that users understand as pending payment.
String _offerStatusLabel(DirectOffer offer) {
  if (offer.isAcceptedPendingPayment) return 'PENDING PAYMENT';
  return offer.status.toUpperCase().replaceAll('_', ' ');
}

/// Title-case lifecycle label for descriptive sections that already have a
/// separate uppercase status badge.
String _offerStageTitle(DirectOffer offer) {
  return _titleCaseWords(_offerStatusLabel(offer));
}

/// User-facing guidance for what the current direct-offer state means next.
String _offerNextStep(DirectOffer offer) {
  if (offer.isAcceptedPendingPayment) {
    return 'Payment is waiting. Secure the offer with QiCard to start work.';
  }
  if (offer.isActive) {
    return 'Work is active. The freelancer can submit delivery when finished.';
  }
  if (offer.isDelivered) {
    return 'Delivery is ready for client review and payment release.';
  }
  if (offer.isCompleted) {
    return 'Payment has been released and this offer is complete.';
  }
  if (offer.isRejectedOrCanceled || offer.status == 'declined') {
    return 'This offer is closed. Use chat if a new offer is needed.';
  }
  return 'The custom offer is awaiting the next client or freelancer action.';
}

/// Icon mapping keeps lifecycle recognition fast without changing ViewModel data.
IconData _statusIcon(DirectOffer offer) {
  if (offer.isAcceptedPendingPayment) return Icons.payments_outlined;
  if (offer.isActive) return Icons.work_outline;
  if (offer.isDelivered) return Icons.rate_review_outlined;
  if (offer.isCompleted) return Icons.verified_outlined;
  if (offer.isRejectedOrCanceled || offer.status == 'declined') {
    return Icons.block_outlined;
  }
  return Icons.hourglass_top_outlined;
}

/// Maps the current user id into a plain role label without exposing ids.
String _roleLabel(DirectOffer offer, String? currentUserId) {
  if (currentUserId == offer.clientId) return 'Client';
  if (currentUserId == offer.freelancerId) return 'Freelancer';
  return 'Viewer';
}

/// Converts raw payment status into title case copy for detail rows.
String _paymentStatusLabel(String value) {
  return _titleCaseWords(value.replaceAll('_', ' '));
}

/// Small formatting helper for raw enum-like labels surfaced by Supabase.
String _titleCaseWords(String value) {
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

/// Safety action visibility remains a view concern because the ViewModel
/// already exposes the current user id and immutable offer ids.
bool _canReportIssue(DirectOffer offer, String? currentUserId) {
  final allowedStatus = offer.isActive || offer.isDelivered;
  final isParticipant =
      currentUserId == offer.clientId || currentUserId == offer.freelancerId;
  return allowedStatus && isParticipant;
}

/// Chooses the opposite participant for dispute submission.
String _defendantId(DirectOffer offer, String? currentUserId) {
  return currentUserId == offer.clientId ? offer.freelancerId : offer.clientId;
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
              child: AppCardContainer(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.p12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: AppLayout.iconStandard,
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
    this.builder,
    this.reserveSpace = false,
  });

  final String offerId;
  final String defendantId;
  final VoidCallback onSubmitted;
  final Widget Function(BuildContext context, VoidCallback onPressed)? builder;
  final bool reserveSpace;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForDirectOffer(
        offerId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _reservedGuardSpace();
        }
        final hasOpenDispute = snapshot.data ?? true;
        if (hasOpenDispute) return _reservedGuardSpace();
        void onPressed() => _showDisputeDialog(context);
        if (builder case final buildAction?) {
          return buildAction(context, onPressed);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.p12),
          child: Center(
            child: TextButton(
              onPressed: onPressed,
              child: Text(
                'Report Issue',
                style: AppTypography.bodySmall.copyWith(
                  color: context.colorScheme.danger,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _reservedGuardSpace() {
    if (!reserveSpace) return const SizedBox.shrink();
    return const SizedBox(
      width: AppLayout.minTouchTarget,
      height: AppLayout.minTouchTarget,
    );
  }

  Future<void> _showDisputeDialog(BuildContext context) async {
    var draftReason = '';
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
    this.height,
  });

  final String offerId;
  final bool completeInProgress;
  final VoidCallback onApprove;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (completeInProgress) {
      return AppButton(
        text: 'Releasing…',
        onPressed: null,
        isLoading: true,
        height: height,
      );
    }
    return FutureBuilder<bool>(
      future: context.read<SafetyViewModel>().hasOpenDisputeForDirectOffer(
        offerId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppButton(
            text: 'Checking…',
            onPressed: null,
            height: height,
          );
        }
        final hasOpenDispute = snapshot.data ?? true;
        return AppButton(
          text: 'Approve & release payment',
          onPressed: hasOpenDispute ? null : onApprove,
          icon: Icons.verified_outlined,
          height: height,
        );
      },
    );
  }
}
