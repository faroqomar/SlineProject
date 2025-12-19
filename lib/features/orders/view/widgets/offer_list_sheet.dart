import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/utils/format_date.dart';
import 'package:sline_app/core/utils/format_price.dart';
import 'package:sline_app/core/widgets/signed_avatar.dart';
import 'package:sline_app/features/orders/viewmodels/orders_view_model.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';

class OfferListSheet extends StatefulWidget {
  final String taskId;

  const OfferListSheet({super.key, required this.taskId});

  @override
  State<OfferListSheet> createState() => _OfferListSheetState();
}

class _OfferListSheetState extends State<OfferListSheet> {
  late Future<List<TaskRequest>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = context.read<OrdersViewModel>().fetchOffers(widget.taskId);
  }

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.r24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: AppDimens.p12,
                bottom: AppDimens.p8,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.p24,
              vertical: AppDimens.p16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Offers',
                  style: AppTypography.h4.copyWith(color: colorScheme.text),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colorScheme.textSecondary),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          Flexible(
            child: FutureBuilder<List<TaskRequest>>(
              future: _offersFuture,
              builder: (context, snapshot) {
                if (context.watch<OrdersViewModel>().isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load offers',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  );
                }

                final offers = snapshot.data ?? [];

                if (offers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppDimens.p32),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: colorScheme.textSecondary,
                          ),
                          const SizedBox(height: AppDimens.p16),
                          Text(
                            'No offers yet',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimens.p24),
                  shrinkWrap: true,
                  itemCount: offers.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimens.p16),
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return _OfferItem(offer: offer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferItem extends StatelessWidget {
  final TaskRequest offer;

  const _OfferItem({required this.offer});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final vm = context.read<OrdersViewModel>();

    return Container(
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Price
          Row(
            children: [
              if (offer.bidderAvatar != null)
                SignedAvatar(storagePathOrUrl: offer.bidderAvatar!, radius: 20)
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.teal,
                  child: Text(
                    (offer.bidderName != null && offer.bidderName!.isNotEmpty)
                        ? offer.bidderName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.bidderName ?? 'Freelancer',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.text,
                      ),
                    ),
                    Text(
                      formatFriendlyTime(offer.createdAt),
                      style: AppTypography.micro.copyWith(
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    PriceFormatter.formatPrice(offer.price.toDouble()),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.teal,
                    ),
                  ),
                  Text(
                    '${offer.days} Days',
                    style: AppTypography.micro.copyWith(
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (offer.note != null && offer.note!.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p12),
            Text(
              offer.note!,
              style: AppTypography.bodySmall.copyWith(color: colorScheme.text),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppDimens.p16),

          // Actions
          if (offer.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      vm.rejectOffer(offer.id).then((_) {
                        if (context.mounted) {
                          Navigator.pop(context); // Close or refresh?
                        }
                        // Ideally refresh list but pop is safer for MVP
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.lightRed,
                      side: BorderSide(color: AppColors.lightRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      vm.acceptOffer(offer.taskId, offer.id).then((_) {
                        if (context.mounted) Navigator.pop(context);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: offer.isAccepted
                    ? AppColors.teal.withValues(alpha: 0.1)
                    : AppColors.lightRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  offer.status.name.toUpperCase(),
                  style: AppTypography.captionBold.copyWith(
                    color: offer.isAccepted
                        ? AppColors.teal
                        : AppColors.lightRed,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
