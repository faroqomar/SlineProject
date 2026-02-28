import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/tasks/view/tender_payment_screen.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../widgets/offer_card.dart';

class InboxTab extends StatefulWidget {
  const InboxTab({super.key});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  bool _isAwarding = false;

  Future<void> _handleAwardOffer(
    BuildContext context,
    DashboardViewModel vm,
    dynamic offer,
  ) async {
    setState(() => _isAwarding = true);

    try {
      // Step 1: Award the offer
      final result = await vm.awardOffer(offer);

      setState(() => _isAwarding = false);

      if (result != null && result['success'] == true) {
        // Navigate to payment screen
        if (context.mounted) {
          final paymentDeadline = DateTime.parse(
            result['payment_deadline'] as String,
          );
          final clientId = vm.currentUserId ?? '';

          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TenderPaymentScreen(
                requestId: offer.id,
                taskId: offer.taskId,
                taskTitle: offer.taskTitle ?? 'Task',
                freelancerName: offer.bidderName ?? 'Freelancer',
                amount: offer.price.toDouble(),
                paymentDeadline: paymentDeadline,
                clientId: clientId,
              ),
            ),
          );

          // After returning from payment screen, refresh
          if (context.mounted) {
            await vm.refresh();
          }
        }
      } else {
        // Show error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['error'] ?? 'Failed to award offer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isAwarding = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Handle "Pay Now" for awarded but unpaid offers (Pay Later flow)
  Future<void> _handlePayAwardedOffer(
    BuildContext context,
    dynamic offer,
  ) async {
    final vm = context.read<DashboardViewModel>();

    // For awarded offers, use a 24-hour deadline from now as fallback
    final paymentDeadline = DateTime.now().add(const Duration(hours: 24));
    final clientId = vm.currentUserId ?? '';

    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TenderPaymentScreen(
            requestId: offer.id,
            taskId: offer.taskId,
            taskTitle: offer.taskTitle ?? 'Task',
            freelancerName: offer.bidderName ?? 'Freelancer',
            amount: offer.price.toDouble(),
            paymentDeadline: paymentDeadline,
            clientId: clientId,
          ),
        ),
      );

      // After returning from payment screen, refresh
      if (context.mounted) {
        await vm.refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.inboxOffers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final isClient = vm.currentRole == UserRole.client;
        final label = isClient ? 'Proposals' : 'Offers';

        if (vm.inboxOffers.isEmpty) {
          return _EmptyInboxState(label: label);
        }

        return RefreshIndicator(
          onRefresh: () => vm.refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimens.p16),
            itemCount: vm.inboxOffers.length,
            itemBuilder: (context, index) {
              final offer = vm.inboxOffers[index];

              // Determine the correct handler based on offer state
              VoidCallback acceptHandler;
              if (isClient && !_isAwarding) {
                if (offer.status == OfferStatus.pending) {
                  // Pending offer: Show Award dialog then navigate to payment
                  acceptHandler = () => _handleAwardOffer(context, vm, offer);
                } else if (offer.status == OfferStatus.accepted &&
                    offer.paymentStatus == PaymentStatus.unpaid) {
                  // Awarded but unpaid: Navigate directly to payment screen (Pay Later flow)
                  acceptHandler = () => _handlePayAwardedOffer(context, offer);
                } else {
                  // No-op for other states to prevent null callback crashes
                  acceptHandler = () {};
                }
              } else {
                // Provider view or during awarding: no-op to prevent null callback crashes
                acceptHandler = () {};
              }

              return OfferCard(
                offer: offer,
                isClientView: isClient,
                onAccept: acceptHandler,
                onReject: () => vm.rejectOffer(offer),
                onWithdraw: () => vm.withdrawOffer(offer.id),
                onRelease: () => vm.releaseOfferWithFee(offer.id),
                onRefund: () => vm.refundOffer(offer.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyInboxState extends StatelessWidget {
  final String label;
  const _EmptyInboxState({required this.label});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = context.colorScheme.textSecondary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: secondaryColor),
          const SizedBox(height: AppDimens.p16),
          Text(
            'No $label Yet',
            style: AppTypography.h3.copyWith(color: secondaryColor),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            '$label you receive or send will appear here.',
            style: AppTypography.bodyMedium.copyWith(color: secondaryColor),
          ),
        ],
      ),
    );
  }
}
