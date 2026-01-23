import '../../tasks/models/task_request_model.dart';

/// Groups offers by task for inbox display
class InboxTaskGroup {
  final String taskId;
  final String taskTitle;
  final List<TaskRequest> offers; // Already sorted newest first

  const InboxTaskGroup({
    required this.taskId,
    required this.taskTitle,
    required this.offers,
  });

  int get offerCount => offers.length;
  DateTime get latestOfferTime => offers.first.createdAt;
}
