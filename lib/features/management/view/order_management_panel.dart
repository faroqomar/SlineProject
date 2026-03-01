import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';

import '../models/work_log_scope.dart';
import '../viewmodels/order_management_view_model.dart';
import 'widgets/work_log_tile.dart';

class OrderManagementPanel extends StatefulWidget {
  static const noteFieldKey = ValueKey('order_management_note_field');
  static const sendButtonKey = ValueKey('order_management_send_button');
  static const retryButtonKey = ValueKey('order_management_retry_button');
  static const timelineErrorKey = ValueKey('order_management_timeline_error');
  static const timelineEmptyKey = ValueKey('order_management_timeline_empty');
  static const actionErrorKey = ValueKey('order_management_action_error');

  final WorkLogScope scope;
  final String currentUserId;

  const OrderManagementPanel({
    super.key,
    required this.scope,
    required this.currentUserId,
  });

  @override
  State<OrderManagementPanel> createState() => _OrderManagementPanelState();
}

class _OrderManagementPanelState extends State<OrderManagementPanel> {
  final TextEditingController _controller = TextEditingController();
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderManagementViewModel>().loadLogs(widget.scope);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Timeline & Notes',
          style: AppTypography.h5.copyWith(color: colorScheme.text),
        ),
        const SizedBox(height: AppDimens.p12),
        GlassContainer(
          padding: const EdgeInsets.all(AppDimens.p16),
          child: Column(
            children: [
              Consumer<OrderManagementViewModel>(
                builder: (context, vm, _) {
                  if (vm.isLoading && vm.logs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppDimens.p24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (vm.loadError != null && vm.logs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppDimens.p16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vm.loadError!,
                            key: OrderManagementPanel.timelineErrorKey,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.lightRed,
                            ),
                          ),
                          const SizedBox(height: AppDimens.p12),
                          TextButton(
                            key: OrderManagementPanel.retryButtonKey,
                            onPressed: vm.isLoading
                                ? null
                                : () => vm.loadLogs(widget.scope),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (vm.logs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppDimens.p16),
                      child: Text(
                        'No activity yet.',
                        key: OrderManagementPanel.timelineEmptyKey,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      if (vm.loadError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppDimens.p12),
                          child: Text(
                            vm.loadError!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.lightRed,
                            ),
                          ),
                        ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vm.logs.length,
                        itemBuilder: (context, index) {
                          final log = vm.logs[index];
                          return WorkLogTile(
                            log: log,
                            isMe: log.authorId == widget.currentUserId,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
              Consumer<OrderManagementViewModel>(
                builder: (context, vm, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: OrderManagementPanel.noteFieldKey,
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'Add a note...',
                                hintStyle: TextStyle(
                                  color: colorScheme.textSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(color: colorScheme.text),
                              minLines: 1,
                              maxLines: 3,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isPrivate ? Icons.lock : Icons.lock_open,
                              color: _isPrivate
                                  ? AppColors.gold
                                  : colorScheme.textSecondary,
                            ),
                            onPressed: vm.isSending
                                ? null
                                : () {
                                    setState(() {
                                      _isPrivate = !_isPrivate;
                                    });
                                  },
                            tooltip: _isPrivate
                                ? 'Private Note (Only you)'
                                : 'Public Note (Shared)',
                          ),
                          IconButton(
                            key: OrderManagementPanel.sendButtonKey,
                            icon: vm.isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.send, color: AppColors.teal),
                            onPressed: vm.isSending
                                ? null
                                : () async {
                                    final success = await vm.postNote(
                                      scope: widget.scope,
                                      content: _controller.text,
                                      isPrivate: _isPrivate,
                                    );
                                    if (!success || !mounted) return;
                                    _controller.clear();
                                  },
                          ),
                        ],
                      ),
                      if (vm.actionError != null) ...[
                        const SizedBox(height: AppDimens.p8),
                        Text(
                          vm.actionError!,
                          key: OrderManagementPanel.actionErrorKey,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lightRed,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
