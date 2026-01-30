import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';
import '../viewmodels/order_management_view_model.dart';
import 'widgets/work_log_tile.dart';

class OrderManagementPanel extends StatefulWidget {
  final String entityId;
  final String entityType;
  final String currentUserId;

  const OrderManagementPanel({
    super.key,
    required this.entityId,
    required this.entityType,
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
      context.read<OrderManagementViewModel>().loadLogs(widget.entityId);
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
              // Timeline List
              Consumer<OrderManagementViewModel>(
                builder: (context, vm, _) {
                  if (vm.isLoading && vm.logs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppDimens.p24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (vm.logs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppDimens.p16),
                      child: Text(
                        'No activity yet.',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
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
                  );
                },
              ),
              const Divider(),
              // Input Area
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Add a note...',
                        hintStyle: TextStyle(color: colorScheme.textSecondary),
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
                    onPressed: () {
                      setState(() {
                        _isPrivate = !_isPrivate;
                      });
                    },
                    tooltip: _isPrivate
                        ? 'Private Note (Only you)'
                        : 'Public Note (Shared)',
                  ),
                  Consumer<OrderManagementViewModel>(
                    builder: (context, vm, _) {
                      return IconButton(
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
                            : () {
                                if (_controller.text.trim().isEmpty) return;
                                vm
                                    .postNote(
                                      entityId: widget.entityId,
                                      entityType: widget.entityType,
                                      content: _controller.text,
                                      isPrivate: _isPrivate,
                                    )
                                    .then((_) {
                                      _controller.clear();
                                      // Restore default public state or keep private if desired
                                      // setState(() => _isPrivate = false);
                                    });
                              },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
