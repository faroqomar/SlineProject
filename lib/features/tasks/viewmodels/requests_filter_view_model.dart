import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/features/tasks/models/expired_bid_filter.dart';
import 'package:sline_app/features/tasks/models/task_request_model.dart';
import 'package:sline_app/features/tasks/viewmodels/task_requests_view_model.dart';

/// ViewModel for filter/sort/award logic extracted from `RequestsListScreen`.
///
/// Manages the expired-bid filter state and provides filtered views of the
/// underlying [TaskRequestsViewModel]'s items. Also holds award-in-progress
/// state to prevent double-tap.
///
/// Subscribes to [TaskRequestsViewModel] changes so [filteredItems] stays
/// in sync when the underlying list updates.
class RequestsFilterViewModel extends ChangeNotifier {
  static const _kTag = 'TaskRequests.filter';

  final TaskRequestsViewModel _requestsVm;

  RequestsFilterViewModel({required TaskRequestsViewModel requestsVm})
    : _requestsVm = requestsVm {
    _requestsVm.addListener(_onRequestsVmChanged);
  }

  void _onRequestsVmChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _requestsVm.removeListener(_onRequestsVmChanged);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Filter state
  // ---------------------------------------------------------------------------

  ExpiredBidFilter _filter = ExpiredBidFilter.hideExpired;
  ExpiredBidFilter get filter => _filter;

  /// Whether an award operation is in progress (prevents double-tap).
  bool _isAwarding = false;
  bool get isAwarding => _isAwarding;
  set isAwarding(bool value) {
    if (_isAwarding != value) {
      _isAwarding = value;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Filter operations
  // ---------------------------------------------------------------------------

  /// Changes the active filter. Logs the transition.
  void setFilter(ExpiredBidFilter newFilter) {
    if (_filter == newFilter) return;
    AppLogger.d(
      'Bid filter changed: ${_filter.label} → ${newFilter.label}',
      tag: _kTag,
    );
    _filter = newFilter;
    notifyListeners();
  }

  /// Applies the current filter to a list of items.
  List<TaskRequest> applyFilter(List<TaskRequest> items) {
    switch (_filter) {
      case ExpiredBidFilter.hideExpired:
        return items.where((r) => !r.isExpired).toList();
      case ExpiredBidFilter.showAll:
        return items;
      case ExpiredBidFilter.showOnlyExpired:
        return items.where((r) => r.isExpired).toList();
    }
  }

  /// Returns filtered items from the underlying requests VM.
  List<TaskRequest> get filteredItems => applyFilter(_requestsVm.items);

  /// Returns a human-readable count string for the app bar subtitle.
  String getCountString(int total, int filtered) {
    final noun = total == 1 ? 'offer' : 'offers';
    if (_filter == ExpiredBidFilter.showAll || total == filtered) {
      return '$total $noun';
    }
    return '$filtered of $total $noun';
  }

  /// Convenience: whether pagination has more pages.
  bool get hasMore => _requestsVm.hasMore;

  /// Convenience: whether more items are being loaded.
  bool get isLoadingMore => _requestsVm.isLoadingMore;

  /// Triggers the next page load.
  void loadMore() {
    if (_requestsVm.hasMore && !_requestsVm.isLoadingMore) {
      unawaited(_requestsVm.loadMore());
    }
  }
}
