import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

class ManageServiceList extends StatelessWidget {
  final String status;
  const ManageServiceList({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final services = [
      _MockService("Logo Design Standard", "\$500", "5 Active Orders", "4.9 ⭐"),
      _MockService("Brand Identity Pack", "\$1200", "1 Active Order", "5.0 ⭐"),
    ];

    if (status != "Active") {
      return Center(
        child: Text(
          "No $status services",
          style: AppTypography.bodyMedium.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.p16),
      itemCount: services.length,
      itemBuilder: (context, index) => _ServiceCard(service: services[index]),
    );
  }
}

class _MockService {
  final String title;
  final String price;
  final String activeOrders;
  final String rating;
  _MockService(this.title, this.price, this.activeOrders, this.rating);
}

class _ServiceCard extends StatelessWidget {
  final _MockService service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r16),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                service.title,
                style: AppTypography.h5.copyWith(color: colorScheme.text),
              ),
              Icon(Icons.more_horiz, color: colorScheme.textSecondary),
            ],
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            service.price,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Row(
            children: [
              _Badge(text: service.activeOrders, color: colorScheme.accent),
              const SizedBox(width: AppDimens.p8),
              _Badge(text: service.rating, color: colorScheme.textSecondary),
            ],
          ),
          const SizedBox(height: AppDimens.p16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text("Edit"),
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  child: const Text("Share"),
                ),
              ), // Demo disabled
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTypography.captionBold.copyWith(color: color),
      ),
    );
  }
}
