import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// Orders dashboard screen with 4-tab filter matching the new design.
class OrdersDashboardScreen extends StatefulWidget {
  const OrdersDashboardScreen({super.key});

  @override
  State<OrdersDashboardScreen> createState() => _OrdersDashboardScreenState();
}

class _OrdersDashboardScreenState extends State<OrdersDashboardScreen> {
  String _activeTab = 'Active';
  final List<String> _tabs = ['Active', 'Revision', 'Completed', 'Cancelled'];

  // Mock order data
  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': 101,
      'title': 'Corporate Brand Identity Pack',
      'client': 'Nexus Corp',
      'initials': 'NC',
      'price': '\$1,200',
      'status': 'Active',
      'type': 'Tender',
      'timeLeft': '2d 14h 32m',
    },
    {
      'id': 102,
      'title': 'Mobile App UI Audit',
      'client': 'StartUp Inc',
      'initials': 'SI',
      'price': '\$350',
      'status': 'Revision',
      'type': 'Booking',
      'timeLeft': null,
    },
    {
      'id': 103,
      'title': 'React Dashboard Components',
      'client': 'DevStudio',
      'initials': 'DS',
      'price': '\$800',
      'status': 'Completed',
      'type': 'Booking',
      'timeLeft': null,
    },
    {
      'id': 104,
      'title': 'Blog Post Series (5x)',
      'client': 'TravelLife',
      'initials': 'TL',
      'price': '\$250',
      'status': 'Cancelled',
      'type': 'Tender',
      'timeLeft': null,
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders =>
      _mockOrders.where((o) => o['status'] == _activeTab).toList();

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
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Orders',
                          style: AppTypography.h2.copyWith(color: colorScheme.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track your active jobs',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p16),

                // Tab bar
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
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
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
                                  color: isActive
                                      ? AppColors.offWhite
                                      : colorScheme.textSecondary,
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

          // --- Content ---
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.p24,
                      0,
                      AppDimens.p24,
                      AppDimens.p100,
                    ),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _OrderCard(order: _filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline,
              size: 32,
              color: colorScheme.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            'No $_activeTab Orders',
            style: AppTypography.h5.copyWith(color: colorScheme.text),
          ),
          const SizedBox(height: 8),
          Text(
            "You don't have any jobs in this status.",
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual order card widget matching the new design.
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final AppColorScheme colorScheme = context.colorScheme;
    final String status = order['status'] as String;
    final bool isActive = status == 'Active';
    final bool isRevision = status == 'Revision';
    final String? timeLeft = order['timeLeft'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p16),
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(AppDimens.r20),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client info
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(AppDimens.r12),
                      ),
                      child: Center(
                        child: Text(
                          order['initials'] as String,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.almostBlack,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['title'] as String,
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.text,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Client: ${order['client']}',
                            style: AppTypography.micro.copyWith(
                              color: colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              _buildStatusBadge(status, colorScheme),
            ],
          ),

          // Metrics (Active orders only)
          if (isActive && timeLeft != null) ...[
            const SizedBox(height: AppDimens.p16),
            Row(
              children: [
                // Time left
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.p12),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimens.r14),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.schedule, size: 16, color: AppColors.teal),
                        const SizedBox(height: 4),
                        Text(
                          timeLeft,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TIME LEFT',
                          style: AppTypography.micro.copyWith(
                            color: colorScheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),

                // Budget
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.p12),
                    decoration: BoxDecoration(
                      color: colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimens.r14),
                      border: Border.all(color: colorScheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: colorScheme.text,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['price'] as String,
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'BUDGET',
                          style: AppTypography.micro.copyWith(
                            color: colorScheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Actions
          const SizedBox(height: AppDimens.p16),
          Container(
            padding: const EdgeInsets.only(top: AppDimens.p12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.divider),
              ),
            ),
            child: Row(
              children: [
                // Primary action
                Expanded(
                  child: (isActive || isRevision)
                      ? Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(AppDimens.r12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.upload, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Deliver Work',
                                style: AppTypography.captionBold.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.cardBackground,
                            borderRadius: BorderRadius.circular(AppDimens.r12),
                            border: Border.all(color: colorScheme.cardBorder),
                          ),
                          child: Center(
                            child: Text(
                              'View Details',
                              style: AppTypography.captionBold.copyWith(
                                color: colorScheme.text,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: AppDimens.p12),

                // Message button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.r12),
                    border: Border.all(color: colorScheme.cardBorder),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: colorScheme.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppColorScheme colorScheme) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case 'Active':
        bgColor = AppColors.teal.withValues(alpha: 0.2);
        textColor = AppColors.lightTeal;
        borderColor = AppColors.teal.withValues(alpha: 0.4);
        break;
      case 'Revision':
        bgColor = AppColors.gold.withValues(alpha: 0.2);
        textColor = AppColors.gold;
        borderColor = AppColors.gold.withValues(alpha: 0.4);
        break;
      case 'Completed':
        bgColor = AppColors.lightTeal.withValues(alpha: 0.2);
        textColor = AppColors.lightTeal;
        borderColor = AppColors.lightTeal.withValues(alpha: 0.4);
        break;
      case 'Cancelled':
      default:
        bgColor = colorScheme.cardBackground;
        textColor = colorScheme.textSecondary;
        borderColor = colorScheme.cardBorder;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.micro.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
