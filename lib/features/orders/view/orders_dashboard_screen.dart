import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';

class OrdersDashboardScreen extends StatefulWidget {
  const OrdersDashboardScreen({super.key});

  @override
  State<OrdersDashboardScreen> createState() => _OrdersDashboardScreenState();
}

class _OrdersDashboardScreenState extends State<OrdersDashboardScreen> {
  String _activeTab = 'Active';
  final List<String> _tabs = ['Active', 'Revision', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // --- Header ---
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.p24,
              topPadding + AppDimens.p24,
              AppDimens.p24,
              AppDimens.p16,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Orders',
                          style: AppTypography.h3.copyWith(color: colorScheme.text),
                        ),
                        Text(
                          'Track your active jobs',
                          style: AppTypography.bodySmall.copyWith(color: colorScheme.textSecondary),
                        ),
                      ],
                    ),
                    GlassContainer(
                      borderRadius: BorderRadius.circular(AppDimens.r14),
                      padding: const EdgeInsets.all(AppDimens.p10),
                      child: Icon(Icons.work_outline, color: AppColors.teal, size: AppDimens.p24),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p16),
                // Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.inputBackground,
                    borderRadius: BorderRadius.circular(AppDimens.r14),
                    border: Border.all(color: colorScheme.inputBorder),
                  ),
                  child: Row(
                    children: _tabs.map((tab) {
                      final bool isActive = _activeTab == tab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = tab),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: AppDimens.p10),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.teal : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppDimens.r10),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.teal.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                tab,
                                style: AppTypography.micro.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? AppColors.offWhite : colorScheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // --- List ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppDimens.p24, 0, AppDimens.p24, AppDimens.p100),
              itemCount: _getOrderCount(_activeTab),
              itemBuilder: (context, index) {
                return _buildOrderCard(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getOrderCount(String tab) {
    // Mock counts
    if (tab == 'Active') return 2;
    if (tab == 'Revision') return 1;
    if (tab == 'Completed') return 5;
    return 0;
  }

  Widget _buildOrderCard(BuildContext context, int index) {
    final AppColorScheme colorScheme = context.colorScheme;
    // Mock Data
    final bool isActive = _activeTab == 'Active';
    final String title = isActive ? 'Corporate Brand Identity' : 'Mobile App UI Audit';
    final String client = isActive ? 'Nexus Corp' : 'StartUp Inc';
    final String price = isActive ? '\$1,200' : '\$350';
    final String time = isActive ? '2d 14h left' : 'Due Tomorrow';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: AppDecorations.glassBoxDecoration(colorScheme: colorScheme, borderRadius: BorderRadius.circular(AppDimens.r20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(AppDimens.r12)),
                    child: const Center(child: Text('NC', style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: AppDimens.p12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.bodySmall.copyWith(color: colorScheme.text, fontWeight: FontWeight.bold)),
                      Text('Client: $client', style: AppTypography.micro.copyWith(color: colorScheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _activeTab == 'Active' ? AppColors.teal.withValues(alpha: 0.1) : AppColors.lightRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _activeTab == 'Active' ? AppColors.teal.withValues(alpha: 0.2) : AppColors.lightRed.withValues(alpha: 0.2)),
                ),
                child: Text(_activeTab.toUpperCase(), style: AppTypography.micro.copyWith(color: _activeTab == 'Active' ? AppColors.teal : AppColors.lightRed, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: AppDimens.p16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.p12),
                    decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimens.r14)),
                    child: Column(
                      children: [
                        Icon(Icons.access_time, size: 16, color: AppColors.teal),
                        const SizedBox(height: 4),
                        Text(time, style: AppTypography.bodySmall.copyWith(color: AppColors.teal, fontWeight: FontWeight.bold)),
                        Text('TIME LEFT', style: AppTypography.micro.copyWith(color: colorScheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.p12),
                    decoration: BoxDecoration(color: colorScheme.cardBackground, borderRadius: BorderRadius.circular(AppDimens.r14), border: Border.all(color: colorScheme.cardBorder)),
                    child: Column(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: colorScheme.text),
                        const SizedBox(height: 4),
                        Text(price, style: AppTypography.bodySmall.copyWith(color: colorScheme.text, fontWeight: FontWeight.bold)),
                        Text('BUDGET', style: AppTypography.micro.copyWith(color: colorScheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppDimens.p16),
          const Divider(height: 1),
          const SizedBox(height: AppDimens.p12),
          Row(
            children: [
              if (isActive || _activeTab == 'Revision')
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(AppDimens.r12), boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 8)]),
                    child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload, color: Colors.white, size: 16), const SizedBox(width: 4), Text('Deliver Work', style: AppTypography.captionBold.copyWith(color: Colors.white))])),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(color: colorScheme.cardBackground, borderRadius: BorderRadius.circular(AppDimens.r12), border: Border.all(color: colorScheme.cardBorder)),
                    child: Center(child: Text('View Details', style: AppTypography.captionBold.copyWith(color: colorScheme.text))),
                  ),
                ),
              const SizedBox(width: AppDimens.p12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(border: Border.all(color: colorScheme.cardBorder), borderRadius: BorderRadius.circular(AppDimens.r12)),
                child: Icon(Icons.chat_bubble_outline, color: colorScheme.textSecondary, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
