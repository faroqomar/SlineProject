import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

class ManageTaskList extends StatelessWidget {
  final String status;
  const ManageTaskList({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final tasks = [
      _MockTask("Mobile App MVP", "25 Proposals", "Open"),
      _MockTask("Website Redesign", "8 Proposals", "Open"),
    ];

    if (status != "Open") {
      return Center(
        child: Text(
          "No $status tasks",
          style: AppTypography.bodyMedium.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.p16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
    );
  }
}

class _MockTask {
  final String title;
  final String proposals;
  final String status;
  _MockTask(this.title, this.proposals, this.status);
}

class _TaskCard extends StatelessWidget {
  final _MockTask task;

  const _TaskCard({required this.task});

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
                task.title,
                style: AppTypography.h5.copyWith(color: colorScheme.text),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  task.status.toUpperCase(),
                  style: AppTypography.captionBold.copyWith(
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            task.proposals,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text("View Offers"),
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text("Edit"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
