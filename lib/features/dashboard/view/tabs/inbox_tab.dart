import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';

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

        if (vm.inboxOffers.isEmpty) {
          return _EmptyInboxState();
        }

        final isClient = vm.currentRole == UserRole.client;

        return RefreshIndicator(
          onRefresh: () async {
            // Trigger a full reload which includes inbox
            vm.setRole(vm.currentRole);
          },
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
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyInboxState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Correct usage of extension from app_theme.dart
    // final colorScheme = context.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.mediumGrey),
          const SizedBox(height: AppDimens.p16),
          Text(
            'No Offers Yet',
            style: AppTypography.h3.copyWith(color: AppColors.mediumGrey),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'Offers you receive or send will appear here.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.mediumGrey,
            ),
          ),
        ],
      ),
    );
  }
}
