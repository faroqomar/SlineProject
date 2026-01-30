import 'package:flutter/foundation.dart';
import '../models/work_log_model.dart';
import '../services/work_log_service.dart';

class OrderManagementViewModel extends ChangeNotifier {
  final WorkLogService _service;

  List<WorkLog> _logs = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  List<WorkLog> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  OrderManagementViewModel([WorkLogService? service])
    : _service = service ?? WorkLogService();

  /// Load logs for a given entity (Task/Booking)
  Future<void> loadLogs(String entityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logs = await _service.getLogs(entityId);
    } catch (e) {
      // Error is logged in Service with AppLogger
      // We map it here or just expose it.
      // Assuming e.toString() is user friendly from ErrorMapper
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Post a note (Private or Shared)
  Future<void> postNote({
    required String entityId,
    required String entityType,
    required String content,
    bool isPrivate = false,
  }) async {
    if (content.trim().isEmpty) return;

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await _service.addLog(
        entityId: entityId,
        entityType: entityType,
        content: content,
        isPrivate: isPrivate,
      );
      // Refresh logs
      await loadLogs(entityId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Propose a price change
  Future<void> proposePriceChange(
    String entityId,
    String entityType,
    double newPrice,
  ) async {
    // Logic for Price Change Proposal
    // 1. Log event
    // 2. Potentially update other tables if needed (TaskRequests?)
    _isSending = true;
    notifyListeners();
    try {
      await _service.logEvent(
        entityId: entityId,
        entityType: entityType,
        eventType: 'price_change_proposal',
        description:
            'Proposed price change to \$${newPrice.toStringAsFixed(2)}',
        additionalMetadata: {'amount': newPrice, 'status': 'pending'},
      );
      await loadLogs(entityId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Request an Extension
  Future<void> requestExtension(
    String entityId,
    String entityType,
    int days,
  ) async {
    _isSending = true;
    notifyListeners();
    try {
      await _service.logEvent(
        entityId: entityId,
        entityType: entityType,
        eventType: 'extension_request',
        description: 'Requested extension of $days days',
        additionalMetadata: {'days': days, 'status': 'pending'},
      );
      await loadLogs(entityId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
