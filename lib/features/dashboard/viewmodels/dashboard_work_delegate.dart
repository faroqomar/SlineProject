import 'package:flutter/foundation.dart';
import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/services/logger_service.dart';
import '../data/dashboard_repository.dart';
import '../models/work_item.dart';
import '../../tasks/services/task_service.dart';
import '../../booking/services/booking_service.dart';
import '../../direct_offers/services/direct_offers_service.dart';

/// Generates a short trace ID for correlating multi-step operations.
String _traceId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return now.toRadixString(36).padLeft(8, '0').substring(0, 8);
}

/// Delegate that owns work-item state, cached computed lists,
/// and work-related actions for [DashboardViewModel].
class DashboardWorkDelegate {
  static const _kTag = 'dashboard.work';

  final DashboardRepository _repository;
  final TaskService _taskService;
  final BookingService _bookingService;
  final DirectOffersService _directOffersService;
  final VoidCallback _onChanged;
  final bool Function() _isDisposed;

  DashboardWorkDelegate({
    required DashboardRepository repository,
    required TaskService taskService,
    required BookingService bookingService,
    required DirectOffersService directOffersService,
    required VoidCallback onChanged,
    required bool Function() isDisposed,
  }) : _repository = repository,
       _taskService = taskService,
       _bookingService = bookingService,
       _directOffersService = directOffersService,
       _onChanged = onChanged,
       _isDisposed = isDisposed;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<WorkItem> _workItems = [];
  List<WorkItem> get workItems => _workItems;

  List<WorkItem>? _nextActionsCache;
  List<WorkItem>? _activeWorkCache;
  List<WorkItem>? _deliveredWorkCache;
  List<WorkItem>? _completedWorkCache;
  List<WorkItem>? _cancelledWorkCache;

  // ---------------------------------------------------------------------------
  // Computed getters (cached, invalidated on _workItems change)
  // ---------------------------------------------------------------------------

  List<WorkItem> get nextActions {
    _nextActionsCache ??= _calculateNextActions();
    return _nextActionsCache!;
  }

  List<WorkItem> get activeWork {
    _activeWorkCache ??=
        _workItems.where((i) {
          return i.statusUiBucket == 'Active' || i.statusUiBucket == 'Pending';
        }).toList()..sort((a, b) {
          final rankCmp = a.sortRank.compareTo(b.sortRank);
          if (rankCmp != 0) return rankCmp;
          final aTime = a.lastActivityAt ?? a.lastUpdate;
          final bTime = b.lastActivityAt ?? b.lastUpdate;
          return bTime.compareTo(aTime);
        });
    return _activeWorkCache!;
  }

  List<WorkItem> get deliveredWork {
    _deliveredWorkCache ??= _workItems.where((i) {
      final isBucketValid =
          i.statusUiBucket == 'Active' || i.statusUiBucket == 'Pending';
      return i.actionableNeedsReview && isBucketValid;
    }).toList();
    return _deliveredWorkCache!;
  }

  List<WorkItem> get completedWork {
    _completedWorkCache ??=
        _workItems.where((i) {
          return i.statusUiBucket == 'Done';
        }).toList()..sort((a, b) {
          final timeA = a.completedAt ?? a.lastUpdate;
          final timeB = b.completedAt ?? b.lastUpdate;
          return timeB.compareTo(timeA);
        });
    return _completedWorkCache!;
  }

  List<WorkItem> get cancelledWork {
    _cancelledWorkCache ??= _workItems.where((i) {
      return i.statusUiBucket == 'Cancelled';
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    return _cancelledWorkCache!;
  }

  List<WorkItem> get activeUpNext => _calculateActiveUpNext();
  List<WorkItem> get activeInProgress => _calculateActiveInProgress();
  List<WorkItem> get activeInReview => _calculateActiveInReview();
  List<WorkItem> get activeItems => _workItems;

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  void invalidateCaches() {
    _nextActionsCache = null;
    _activeWorkCache = null;
    _deliveredWorkCache = null;
    _completedWorkCache = null;
    _cancelledWorkCache = null;
  }

  void clear() {
    _workItems = [];
    invalidateCaches();
  }

  /// Assigns work items from an external source (e.g. parent VM's _loadData).
  void setWorkItems(List<WorkItem> items) {
    _workItems = items;
    invalidateCaches();
  }

  /// Fetches work items from repository and updates caches.
  Future<void> fetchWorkItems(UserRole currentRole) async {
    try {
      _workItems = await _repository.fetchWorkItems(currentRole);
      if (_isDisposed()) return;
      invalidateCaches();
      _onChanged();
    } on Exception catch (e) {
      AppLogger.e('Failed to fetch work items', error: e, tag: _kTag);
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> performPrimaryAction(WorkItem item) async {
    switch (item.primaryActionType) {
      case PrimaryActionType.approveClose:
        AppLogger.i('Action: approveClose item=${item.id}', tag: _kTag);
        return;
      case PrimaryActionType.reviewDelivery:
        AppLogger.i('Action: reviewDelivery item=${item.id}', tag: _kTag);
        return;
      case PrimaryActionType.payEscrow:
        AppLogger.i('Action: payEscrow item=${item.id}', tag: _kTag);
        break; // Don't return — direct offer payEscrow path is below the switch
      case PrimaryActionType.submitEvidence:
        AppLogger.i('Action: submitEvidence item=${item.id}', tag: _kTag);
        return;
      case PrimaryActionType.viewDetails:
        AppLogger.i('Action: viewDetails item=${item.id}', tag: _kTag);
        return;
      case PrimaryActionType.startWork:
      case PrimaryActionType.markCompleted:
        break;
    }

    if (item.type == WorkItemType.directOffer &&
        item.primaryActionType == PrimaryActionType.payEscrow) {
      try {
        await _directOffersService.payNow(item.id);
      } on Exception catch (e) {
        AppLogger.e(
          'Failed payNow for direct offer item=${item.id}',
          error: e,
          tag: _kTag,
        );
        rethrow;
      }
      return;
    }

    if (item.type == WorkItemType.directOffer) return;

    try {
      if (item.type == WorkItemType.booking) {
        BookingStatus? newStatus;
        if (item.primaryActionType == PrimaryActionType.startWork) {
          newStatus = BookingStatus.inProgress;
        } else if (item.primaryActionType == PrimaryActionType.markCompleted) {
          newStatus = BookingStatus.completed;
        }
        if (newStatus != null) {
          await _bookingService.updateBookingStatus(
            bookingId: item.id,
            newStatus: newStatus,
          );
        }
      } else {
        TaskStatus? newStatus;
        if (item.primaryActionType == PrimaryActionType.startWork) {
          newStatus = TaskStatus.inProgress;
        } else if (item.primaryActionType == PrimaryActionType.markCompleted) {
          newStatus = TaskStatus.completed;
        }
        if (newStatus != null) {
          await _taskService.updateTaskStatus(item.id, newStatus);
        }
      }
      AppLogger.i(
        'Action: ${item.primaryActionType.name} completed item=${item.id}',
        tag: _kTag,
      );
    } on Exception catch (e) {
      AppLogger.e(
        'Failed primary action=${item.primaryActionType.name} item=${item.id}',
        error: e,
        tag: _kTag,
      );
    }
  }

  Future<void> withdrawOffer(String offerId) async {
    final tid = _traceId();
    try {
      await _taskService.withdrawOffer(offerId);
      AppLogger.i('Offer withdrawn: $offerId [trace:$tid]', tag: _kTag);
    } on Exception catch (e) {
      AppLogger.e(
        'Failed to withdraw offer=$offerId [trace:$tid]',
        error: e,
        tag: _kTag,
      );
      rethrow;
    }
  }

  Future<void> releaseOfferWithFee(String offerId) async {
    final tid = _traceId();
    try {
      await _taskService.releaseOfferWithFee(offerId);
      AppLogger.i(
        'Released funds for offer=$offerId [trace:$tid]',
        tag: '$_kTag.ledger',
      );
    } on Exception catch (e) {
      AppLogger.e(
        'Failed to release funds for offer=$offerId [trace:$tid]',
        error: e,
        tag: '$_kTag.ledger',
      );
      rethrow;
    }
  }

  Future<void> refundOffer(String offerId) async {
    final tid = _traceId();
    try {
      await _taskService.refundOffer(offerId);
      AppLogger.i('Refunded offer=$offerId [trace:$tid]', tag: '$_kTag.ledger');
    } on Exception catch (e) {
      AppLogger.e(
        'Failed to refund offer=$offerId [trace:$tid]',
        error: e,
        tag: '$_kTag.ledger',
      );
      rethrow;
    }
  }

  Future<void> cancelAwardedOffer(String requestId) async {
    final tid = _traceId();
    try {
      await _taskService.cancelAwardedOffer(requestId);
      if (_isDisposed()) return;
      AppLogger.i(
        'Cancelled awarded offer=$requestId [trace:$tid]',
        tag: _kTag,
      );
    } on Exception catch (e) {
      AppLogger.e(
        'Failed to cancel awarded offer=$requestId [trace:$tid]',
        error: e,
        tag: _kTag,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Private computation helpers
  // ---------------------------------------------------------------------------

  List<WorkItem> _calculateNextActions() {
    final tier1 = _workItems.where((i) => i.actionableNeedsReview).toList()
      ..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    final seen = tier1.map((i) => i.id).toSet();

    final tier2 = _workItems.where((i) {
      if (seen.contains(i.id)) return false;
      final s = i.statusRaw.toLowerCase();
      return s == 'paid_request_pending' || s == 'awarded';
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    seen.addAll(tier2.map((i) => i.id));

    final tier3 = _workItems.where((i) {
      if (seen.contains(i.id)) return false;
      return i.statusUiBucket == 'Active' &&
          i.statusRaw.toLowerCase() == 'disputed';
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
    seen.addAll(tier3.map((i) => i.id));

    final tier4 = _workItems.where((i) {
      if (seen.contains(i.id)) return false;
      if (i.statusUiBucket != 'Active') return false;
      if (i.scheduledAt == null) return false;
      final hoursUntil = i.scheduledAt!.difference(DateTime.now()).inHours;
      return hoursUntil < 48;
    }).toList()..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

    final combined = [
      ...tier1.take(3),
      ...tier2.take(3),
      ...tier3.take(3),
      ...tier4.take(3),
    ];
    return combined.take(3).toList();
  }

  List<WorkItem> _calculateActiveUpNext() {
    return _workItems.where((i) {
      final s = i.statusRaw.toLowerCase();
      return s == 'open' ||
          s == 'assigned' ||
          s == 'pending' ||
          s == 'confirmed';
    }).toList()..sort((a, b) {
      if (a.scheduledAt != null && b.scheduledAt != null) {
        return a.scheduledAt!.compareTo(b.scheduledAt!);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  List<WorkItem> _calculateActiveInProgress() {
    return _workItems.where((i) {
      return i.statusRaw.toLowerCase() == 'inprogress';
    }).toList()..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
  }

  List<WorkItem> _calculateActiveInReview() {
    return _workItems.where((i) {
      return i.statusRaw.toLowerCase() == 'completed';
    }).toList()..sort((a, b) {
      final timeA = a.completedAt ?? a.lastUpdate;
      final timeB = b.completedAt ?? b.lastUpdate;
      return timeB.compareTo(timeA);
    });
  }
}
