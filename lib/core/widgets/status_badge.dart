import 'package:flutter/material.dart';

import 'package:sline_app/core/app_enums.dart';
import 'package:sline_app/core/models/work_item.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// A status indicator badge with semantic colors, icons, and optional pulse.
///
/// ## Phase 1 Changes
/// - Replaced hardcoded Colors.green / AppColors.lightRed / AppColors.gold / AppColors.teal
///   with semantic colors from [AppColorScheme] (success, danger, warning, info)
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
    final t = widget.text.toLowerCase();
    return t == 'pending' || t == 'draft' || t == 'payment pending';
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
          _pulseController!.reverse();
        } else {
          _pulseController!.stop();
        }
      } else if (status == AnimationStatus.dismissed &&
          _pulseCount < _maxPulseCount) {
        _pulseController!.forward();
      }
    });
    _pulseController!.forward();
  }

  /// Maps status text to semantic color from the current theme.
  Color _resolveColor(BuildContext context) {
    if (widget.color != null) return widget.color!;

    final colorScheme = context.colorScheme;
    final t = widget.text.toLowerCase();

    // Completed / delivered → success
    if (t == 'completed' || t == 'delivered') return colorScheme.success;
    // Canceled / declined / rejected → danger
    if (t == 'canceled' ||
        t == 'cancelled' ||
        t == 'declined' ||
        t == 'rejected') {
      return colorScheme.danger;
    }
    // Pending / draft / payment pending → warning
    if (t == 'pending' || t == 'draft' || t == 'payment pending') {
      return colorScheme.warning;
    }
    // Active / confirmed / in progress / assigned / open → info
    if (t == 'active' ||
        t == 'confirmed' ||
        t == 'in progress' ||
        t == 'assigned' ||
        t == 'open' ||
        t == 'offers review') {
      return colorScheme.info;
    }

    return colorScheme.info;
  }

  /// Maps status to an icon for colorblind accessibility.
  IconData _resolveIcon() {
    final t = widget.text.toLowerCase();
    if (t == 'completed' || t == 'delivered') return Icons.check_circle;
    if (t == 'canceled' ||
        t == 'cancelled' ||
        t == 'declined' ||
        t == 'rejected') {
      return Icons.cancel;
    }
    if (t == 'pending' || t == 'draft' || t == 'payment pending') {
      return Icons.schedule;
    }
    if (t == 'in progress' || t == 'active') return Icons.play_circle;
    if (t == 'confirmed') return Icons.verified;
    if (t == 'open') return Icons.radio_button_unchecked;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _resolveColor(context);
    final iconData = _resolveIcon();
    final iconSize = widget.isSmall ? 10.0 : 14.0;
    final effectiveDuration = AppMotion.respectMotion(
      context,
      AppMotion.dramatic,
    );

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isSmall ? 6.0 : 10.0,
        vertical: widget.isSmall ? 2.0 : 4.0,
      ),
      decoration: ShapeDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        shape: StadiumBorder(
          side: BorderSide(color: effectiveColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: iconSize, color: effectiveColor),
          const SizedBox(width: AppLayout.spacingTight),
          Text(
            widget.text,
            style: widget.isSmall
                ? AppTypography.micro.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.bold,
                  )
                : AppTypography.captionBold.copyWith(color: effectiveColor),
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
