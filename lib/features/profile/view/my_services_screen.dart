import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/services/view/widgets/service_card.dart';
import 'package:sline_app/features/services/viewmodels/my_services_view_model.dart';

/// Shows the current provider's services without changing service ownership.
///
/// Loading, error, and service rows stay driven by [MyServicesViewModel].
class MyServicesScreen extends StatefulWidget {
  /// Creates the profile services management route.
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(context.read<MyServicesViewModel>().load());
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyServicesViewModel>();
    final services = vm.services;
    final amberColors = context.amberColors;

    return Scaffold(
      backgroundColor: context.colorScheme.phoneBackground,
      appBar: AppBar(
        title: Text('My Services', style: AppTypography.h3),
        centerTitle: true,
        backgroundColor: AmberDuskTokens.colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back, color: context.colorScheme.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: vm.isLoading && services.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null && services.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.p16),
                child: Text(
                  vm.error!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : services.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.design_services_outlined,
                    size: AppDimens.emptyStateIconSize,
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
              separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p16),
              itemBuilder: (context, index) {
                final service = services[index];
                return ServiceCard(
                  service: service,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit service coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create service coming soon'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: amberColors.primary,
        foregroundColor: amberColors.textInverse,
        child: const Icon(Icons.add),
      ),
    );
  }
}
