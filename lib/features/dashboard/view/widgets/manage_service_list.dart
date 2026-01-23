import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/services/models/service_model.dart';
import '../../viewmodels/dashboard_view_model.dart';

class ManageServiceList extends StatelessWidget {
  final String status;
  const ManageServiceList({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Bind to real data
    final vm = context.watch<DashboardViewModel>();
    final services = vm.myServices.where((s) => s.status == status).toList();

    if (services.isEmpty) {
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

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;

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
            service.price != null ? '\$${service.price}' : 'No Price',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Row(
            children: [
              _Badge(
                text: '${service.activeOrdersCount} Active',
                color: colorScheme.accent,
              ),
              const SizedBox(width: AppDimens.p8),
              if (service.rating > 0)
                _Badge(
                  text: '${service.rating} ⭐',
                  color: colorScheme.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: AppDimens.p16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {}, // Todo: Edit
                  child: const Text("Edit"),
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: OutlinedButton(
                  onPressed: null, // Todo: Share/Pause
                  child: Text(
                    service.status == 'active' ? "Pause" : "Activate",
                  ),
                ),
              ),
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
