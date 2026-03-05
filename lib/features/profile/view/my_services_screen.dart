import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/features/services/view/widgets/service_card.dart';
import 'package:sline_app/features/services/viewmodels/my_services_view_model.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyServicesViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyServicesViewModel>();
    final services = vm.services;

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
        backgroundColor: context.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
