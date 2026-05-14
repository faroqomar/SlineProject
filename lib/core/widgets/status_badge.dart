import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/models/work_item.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';

/// A status indicator badge with semantic colors, icons, and optional pulse.
///
/// ## Phase 1 Changes
/// - Replaced legacy status colors with Amber Dusk semantic foregrounds and
///   adapter-owned overlays.
/// - Added status-specific icons (check_circle, schedule, cancel, etc.)
/// - Changed shape from [RoundedRectangleBorder] to pill (StadiumBorder)
/// - Added bounded pulse animation on pending statuses (3 reps, reduced motion safe)
/// - Added [Semantics] label
/// - All existing constructor params preserved (backward compatible)
class StatusBadge extends StatefulWidget {
  final String text;
  final Color? color;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.text,
    this.color,
    this.isSmall = false,
  });

  factory StatusBadge.fromWorkItem(WorkItem item, {bool isSmall = false}) {
    return StatusBadge(text: _formatStatus(item.statusRaw), isSmall: isSmall);
  }

  factory StatusBadge.fromStatus(
    dynamic status,
    // Work item type is accepted for call-site symmetry with unified status
    // helpers even though current formatting only needs the status value.
    // ignore: avoid_unused_constructor_parameters
    WorkItemType type, {
    bool isSmall = false,
  }) {
    var statusStr = '';
    if (status is BookingStatus) {
      statusStr = status.name;
    } else if (status is TaskStatus) {
      statusStr = status.name;
    } else {
      statusStr = status.toString();
    }

    return StatusBadge(text: _formatStatus(statusStr), isSmall: isSmall);
  }

  static String _formatStatus(String status) {
    if (status == 'paid_request_pending') return 'Payment Pending';
    if (status == 'inprogress') return 'In Progress';
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  int _pulseCount = 0;
  static const _maxPulseCount = 3;
  static const _setupStatuses = {'setup', 'timeout', 'timed out'};
  static const _pendingStatuses = {
    'waiting',
    'pending',
    'draft',
    'payment pending',
    'review',
    'offers review',
  };
  static const _activeStatuses = {
    'active',
    'confirmed',
    'in progress',
    'assigned',
    'open',
    'won',
  };
  static const _completedStatuses = {
    'completed',
    'delivered',
    'closed',
    'refunded',
  };
  static const _canceledStatuses = {
    'canceled',
    'cancelled',
    'declined',
    'rejected',
    'failed',
    'failure',
  };

  @override
  void initState() {
    super.initState();
    _maybeStartPulse();
  }

  @override
  void didUpdateWidget(covariant StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _pulseCount = 0;
      _maybeStartPulse();
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  bool get _isPendingStatus {
    return _pendingStatuses.contains(widget.text.toLowerCase());
  }

  void _maybeStartPulse() {
    if (!_isPendingStatus) {
      _pulseController?.stop();
      return;
    }
    _pulseController ??= AnimationController(
      vsync: this,
      duration: AppMotion.dramatic,
    );
    _pulseAnimation ??= Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: AppMotion.curveSymmetric,
      ),
    );
    _pulseController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseCount++;
        if (_pulseCount < _maxPulseCount) {
          unawaited(_pulseController!.reverse());
        } else {
          _pulseController!.stop();
        }
      } else if (status == AnimationStatus.dismissed &&
          _pulseCount < _maxPulseCount) {
        unawaited(_pulseController!.forward());
      }
    });
    unawaited(_pulseController!.forward());
  }

  /// Maps status text to Amber Dusk semantic foreground and overlay roles.
  _StatusBadgeTone _resolveTone() {
    final pills = AmberDuskTokens.widgetTheme.statusPills;
    if (widget.color != null) {
      return _StatusBadgeTone(
        foreground: widget.color!,
        background: widget.color!.withValues(alpha: 0.12),
      );
    }

    final t = widget.text.toLowerCase();
    const colors = AmberDuskTokens.colors;

    if (_setupStatuses.contains(t)) {
      return _StatusBadgeTone(
        foreground: pills.muted.foreground,
        background: pills.muted.background,
      );
    }

    if (_pendingStatuses.contains(t)) {
      return _StatusBadgeTone(
        foreground: pills.primary.foreground,
        background: pills.primary.background,
      );
    }

    if (_activeStatuses.contains(t)) {
      return _StatusBadgeTone(
        foreground: pills.active.foreground,
        background: pills.active.background,
      );
    }

    if (_completedStatuses.contains(t)) {
      return _StatusBadgeTone(
        foreground: pills.completed.foreground,
        background: pills.completed.background,
      );
    }

    if (_canceledStatuses.contains(t)) {
      return _StatusBadgeTone(
        foreground: colors.rust,
        background: pills.urgent.background,
      );
    }

    return _StatusBadgeTone(
      foreground: pills.primary.foreground,
      background: pills.primary.background,
    );
  }

  /// Maps status to an icon for colorblind accessibility.
  IconData _resolveIcon() {
    final t = widget.text.toLowerCase();
    if (_completedStatuses.contains(t)) {
      return Icons.check_circle;
    }
    if (_canceledStatuses.contains(t)) {
      return Icons.cancel;
    }
    if (_pendingStatuses.contains(t)) {
      return Icons.schedule;
    }
    if (_activeStatuses.contains(t) && t != 'confirmed' && t != 'open') {
      return Icons.play_circle;
    }
    if (t == 'confirmed') return Icons.verified;
    if (t == 'open') return Icons.radio_button_unchecked;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final pills = AmberDuskTokens.widgetTheme.statusPills;
    final tone = _resolveTone();
    final iconData = _resolveIcon();
    final iconSize = widget.isSmall ? pills.smallIconSize : pills.iconSize;
    final effectiveDuration = AppMotion.respectMotion(
      context,
      AppMotion.dramatic,
    );
    final displayText = pills.labelUppercase
        ? widget.text.toUpperCase()
        : widget.text;

    Widget badge = Container(
      padding: widget.isSmall ? pills.smallPadding : pills.padding,
      decoration: ShapeDecoration(
        color: tone.background,
        shape: const StadiumBorder(side: BorderSide.none),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: iconSize, color: tone.foreground),
          SizedBox(width: AmberDuskTokens.spacing.xs),
          Text(
            displayText,
            style: (widget.isSmall ? pills.smallTextStyle : pills.textStyle)
                .copyWith(color: tone.foreground),
          ),
        ],
      ),
    );

    // Bounded pulse animation for pending statuses
    if (_isPendingStatus &&
        _pulseAnimation != null &&
        effectiveDuration != Duration.zero) {
      badge = AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) {
          return Opacity(opacity: _pulseAnimation!.value, child: child);
        },
        child: badge,
      );
    }

    return Semantics(label: 'Status: ${widget.text}', child: badge);
  }
}

/// Holds the resolved Amber Dusk status colors for one badge render.
class _StatusBadgeTone {
  const _StatusBadgeTone({required this.foreground, required this.background});

  /// Status icon and label color.
  final Color foreground;

  /// Status pill overlay color.
  final Color background;
}
