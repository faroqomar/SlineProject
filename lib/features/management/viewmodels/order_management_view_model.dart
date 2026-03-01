import 'package:flutter/foundation.dart';
import '../models/work_log_model.dart';
import '../models/work_log_scope.dart';
import '../services/work_log_service.dart';

class OrderManagementViewModel extends ChangeNotifier {
  final WorkLogService _service;

  List<WorkLog> _logs = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _loadError;
  String? _actionError;
  WorkLogScope? _lastScope;

  List<WorkLog> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _loadError ?? _actionError;
  String? get loadError => _loadError;
  String? get actionError => _actionError;

  OrderManagementViewModel([WorkLogService? service])
    : _service = service ?? WorkLogService();

  /// Load logs for a given entity (Task/Booking)
  Future<void> loadLogs(WorkLogScope scope) async {
    _lastScope = scope;
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      _logs = await _service.getLogs(scope);
    } catch (e) {
      _loadError = _normalizeError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Post a note (Private or Shared)
  Future<bool> postNote({
    required WorkLogScope scope,
    required String content,
    bool isPrivate = false,
  }) async {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) return false;

    _isSending = true;
    _actionError = null;
    notifyListeners();

    try {
      await _service.addLog(
        scope: scope,
        content: normalizedContent,
        isPrivate: isPrivate,
      );
      await loadLogs(scope);
      return true;
    } catch (e) {
      _actionError = _normalizeError(e);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Propose a price change
  Future<bool> proposePriceChange(WorkLogScope scope, double newPrice) async {
    _isSending = true;
    _actionError = null;
    notifyListeners();
    try {
      await _service.logEvent(
        scope: scope,
        eventType: 'price_change_proposal',
        description:
            'Proposed price change to \$${newPrice.toStringAsFixed(2)}',
        additionalMetadata: {'amount': newPrice, 'status': 'pending'},
      );
      await loadLogs(scope);
      return true;
    } catch (e) {
      _actionError = _normalizeError(e);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Request an Extension
  Future<bool> requestExtension(WorkLogScope scope, int days) async {
    _isSending = true;
    _actionError = null;
    notifyListeners();
    try {
      await _service.logEvent(
        scope: scope,
        eventType: 'extension_request',
        description: 'Requested extension of $days days',
        additionalMetadata: {'days': days, 'status': 'pending'},
      );
      await loadLogs(scope);
      return true;
    } catch (e) {
      _actionError = _normalizeError(e);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> retryLastLoad() async {
    final scope = _lastScope;
    if (scope == null) return;
    await loadLogs(scope);
  }

  String _normalizeError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
