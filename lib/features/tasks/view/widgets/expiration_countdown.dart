// Expiration countdown widget for pending task request bids.
// Shows time remaining with color transitions (green → yellow → red).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';

/// Countdown state determining color and urgency level.
enum CountdownState {
  /// More than 4 hours remaining - calm state
  safe,

  /// 1-4 hours remaining - warning state
  warning,

  /// Less than 1 hour remaining - urgent state
  urgent,

  /// Expired - deadline passed
  expired,
}

/// A widget that displays a countdown timer for bid expiration.
/// Automatically updates every minute and provides accessibility labels.
class ExpirationCountdown extends StatefulWidget {
  /// The absolute expiration time.
  final DateTime expirationTime;

  /// Called when the countdown reaches zero.
  final VoidCallback? onExpired;

  /// Size variant for the countdown display.
  final CountdownSize size;

  /// Whether to show the icon.
  final bool showIcon;

  /// Custom label prefix (e.g., "Expires in ").
  final String? labelPrefix;

  const ExpirationCountdown({
    super.key,
    required this.expirationTime,
    this.onExpired,
    this.size = CountdownSize.medium,
    this.showIcon = true,
    this.labelPrefix,
  });

  @override
  State<ExpirationCountdown> createState() => _ExpirationCountdownState();
}

/// Size variants for the countdown widget.
enum CountdownSize {
  /// Small badge size for compact layouts
  small,

  /// Medium size for list tiles
  medium,

  /// Large size for detail views
  large,
}

class _ExpirationCountdownState extends State<ExpirationCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    // Update every minute for smooth countdown
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void didUpdateWidget(ExpirationCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expirationTime != widget.expirationTime) {
      _updateRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    if (!mounted) return;

    setState(() {
      _remaining = widget.expirationTime.difference(DateTime.now());
    });

    // Check if just expired
    if (_remaining.isNegative && !oldRemaining.isNegative) {
      AppLogger.i('Bid expired', tag: 'ExpirationCountdown');
      widget.onExpired?.call();
    }
  }

  Duration get oldRemaining =>
      widget.expirationTime.difference(DateTime.now()) -
      const Duration(minutes: 1);

  CountdownState get _state {
    if (_remaining.isNegative) return CountdownState.expired;
    if (_remaining.inHours < 1) return CountdownState.urgent;
    if (_remaining.inHours < 4) return CountdownState.warning;
    return CountdownState.safe;
  }

  Color get _stateColor {
    switch (_state) {
      case CountdownState.safe:
        return Colors.green;
      case CountdownState.warning:
        return AppColors.gold;
      case CountdownState.urgent:
        return AppColors.lightRed;
      case CountdownState.expired:
        return Colors.grey;
    }
  }

  String get _timeText {
    if (_remaining.isNegative) return 'Expired';

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _accessibilityLabel {
    if (_remaining.isNegative) {
      return 'Bid has expired';
    }

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '${widget.labelPrefix ?? 'Expires in'} $hours hours and $minutes minutes';
    }
    return '${widget.labelPrefix ?? 'Expires in'} $minutes minutes';
  }

  double get _fontSize {
    switch (widget.size) {
      case CountdownSize.small:
        return 12;
      case CountdownSize.medium:
        return 14;
      case CountdownSize.large:
        return 18;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case CountdownSize.small:
        return 14;
      case CountdownSize.medium:
        return 16;
      case CountdownSize.large:
        return 20;
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case CountdownSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case CountdownSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case CountdownSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _accessibilityLabel,
      child: Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: _stateColor.withValues(alpha: 0.1),
          border: Border.all(color: _stateColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showIcon) ...[
              Icon(
                _remaining.isNegative ? Icons.timer_off : Icons.timer,
                size: _iconSize,
                color: _stateColor,
              ),
              SizedBox(width: widget.size == CountdownSize.small ? 2 : 4),
            ],
            Text(
              _timeText,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                color: _stateColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact badge version for list tiles.
/// Shows just the time remaining without the container decoration.
class ExpirationBadge extends StatelessWidget {
  final DateTime expirationTime;
  final CountdownSize size;

  const ExpirationBadge({
    super.key,
    required this.expirationTime,
    this.size = CountdownSize.small,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = expirationTime.difference(DateTime.now());
    final isExpired = remaining.isNegative;

    Color color;
    if (isExpired) {
      color = Colors.grey;
    } else if (remaining.inHours < 1) {
      color = AppColors.lightRed;
    } else if (remaining.inHours < 4) {
      color = AppColors.gold;
    } else {
      color = Colors.green;
    }

    if (isExpired) {
      return Chip(
        label: const Text('Expired', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.grey.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: Colors.grey),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatDuration(remaining),
        style: TextStyle(
          fontSize: size == CountdownSize.small ? 11 : 12,
          fontWeight: FontWeight.w500,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Expired';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
