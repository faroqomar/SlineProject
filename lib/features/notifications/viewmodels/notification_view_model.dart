import 'package:flutter/foundation.dart';
import 'package:sline_app/features/notifications/data/notification_service.dart';
import 'package:sline_app/features/notifications/models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;

  List<String> get groups => _notifications.map((e) => e.group).toSet().toList();

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications();
    } catch (e) {
      // Handle error
      if (kDebugMode) print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
