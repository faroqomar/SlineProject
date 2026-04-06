import 'package:flutter/material.dart';

/// Filter options for expired bids in the requests list.
enum ExpiredBidFilter { hideExpired, showAll, showOnlyExpired }

extension ExpiredBidFilterExtension on ExpiredBidFilter {
  String get label {
    switch (this) {
      case ExpiredBidFilter.hideExpired:
        return 'Hide Expired';
      case ExpiredBidFilter.showAll:
        return 'Show All';
      case ExpiredBidFilter.showOnlyExpired:
        return 'Show Only Expired';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpiredBidFilter.hideExpired:
        return Icons.visibility_off;
      case ExpiredBidFilter.showAll:
        return Icons.visibility;
      case ExpiredBidFilter.showOnlyExpired:
        return Icons.timer_off;
    }
  }
}
