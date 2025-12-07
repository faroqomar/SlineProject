enum NotificationType { order, proposal, system, payment }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime time;
  final bool isRead;
  final String group; // 'Today', 'Yesterday', etc.

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    this.isRead = false,
    required this.group,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      time: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      group: _calculateGroup(DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now()),
    );
  }

  static String _calculateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);

    if (check == today) return 'Today';
    if (check == yesterday) return 'Yesterday';
    return 'Earlier';
  }
}
