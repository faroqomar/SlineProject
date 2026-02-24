import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../widgets/offer_card.dart';

class InboxTab extends StatelessWidget {
  const InboxTab({super.key});

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
              return OfferCard(
                offer: offer,
                isClientView: isClient,
                onAccept: () => vm.acceptOffer(offer),
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
