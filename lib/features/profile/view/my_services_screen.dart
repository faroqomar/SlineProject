import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/dashboard/viewmodels/dashboard_view_model.dart';
import 'package:sline_app/features/services/view/widgets/service_card.dart';

class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We can reuse DashboardViewModel or create a ServicesViewModel
    // For now, let's reuse DashboardViewModel as it has myServices
    final vm = context.watch<DashboardViewModel>();
    final services = vm.myServices;

    return Scaffold(
      backgroundColor: context.colorScheme.background,
      appBar: AppBar(
        title: Text('My Services', style: AppTypography.h3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colorScheme.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: services.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.design_services_outlined,
                    size: 64,
                    color: context.colorScheme.textSecondary,
                  ),
                  const SizedBox(height: AppDimens.p16),
                  Text(
                    'No services found.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppDimens.p16),
              itemCount: services.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimens.p16),
              itemBuilder: (context, index) {
                final service = services[index];
                return ServiceCard(
                  service: service,
                  onTap: () {
                    // Navigate to service details or edit
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create service
        },
        backgroundColor: context.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
