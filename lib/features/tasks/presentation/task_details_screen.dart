import 'package:flutter/material.dart';
import '../../tasks/models/task_model.dart';
import '../../../core/utils/format_price.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader('🗂️ Category', task.category),
                  Divider(height: 32, thickness: 1.2),
                  _buildHeader('💰 Budget', PriceFormatter.formatPrice(task.budget)),
                  Divider(height: 32, thickness: 1.2),
                  _buildHeader('📅 Posted', DateFormatter.timeAgo(task.createdAt)),
                  Divider(height: 32, thickness: 1.2),
                  _buildHeader('📝 Description', task.description),
                  Divider(height: 32, thickness: 1.2),
                  _buildHeader('🛠️ Skills', task.skills.join(', ')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}