import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/deep_link_service.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/notifications/view/notifications_modal.dart';
import 'package:sline_app/features/notifications/viewmodels/notification_view_model.dart';

/// Notification bell button with animated badge entrance and pulse.
///
/// Phase 5 redesign: converted from StatelessWidget to StatefulWidget with
/// TickerProviderStateMixin to host AnimationController for badge entrance
/// (scale 0→1 with spring curve) and pulse on count change (1.0→1.1→1.0).
/// Phase 10 keeps the badge on scheme-aware Amber Dusk danger/text tokens while
/// preserving modal opening and deep-link routing behavior. View-layer only.
class NotificationBadgeButton extends StatefulWidget {
  const NotificationBadgeButton({super.key});

  static const Key buttonKey = ValueKey<String>('notification_badge_button');

  @override
  State<NotificationBadgeButton> createState() =>
      _NotificationBadgeButtonState();
}

class _NotificationBadgeButtonState extends State<NotificationBadgeButton>
    with TickerProviderStateMixin {
  // ── Badge entrance animation ───────────────────────────────
  late final AnimationController _badgeController;
  late final Animation<double> _badgeScale;

  // ── Pulse animation — separate controller so the badge stays
  // visible (entrance at full scale) while the pulse plays ────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  /// Track previous count to detect changes and trigger pulse.
  int _previousCount = 0;

  /// Prevents rapid taps from stacking multiple notification sheets.
  bool _isOpeningModal = false;

  @override
  void initState() {
    super.initState();

    // Badge entrance: scale 0→1 with spring, fast duration.
    _badgeController = AnimationController(
      duration: AppMotion.fast,
      vsync: this,
    );
    _badgeScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _badgeController, curve: AppMotion.curveSpring),
    );

    // Pulse: 1.0 → 1.15 → 1.0 via TweenSequence for a real pop feel.
    // Uses a short duration so it feels snappy rather than sluggish.
    _pulseController = AnimationController(
      duration: AppMotion.fast,
      vsync: this,
    );
    _pulseScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.15),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.15, end: 1.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _pulseController,
            curve: AppMotion.curveSymmetric,
          ),
        );
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Trigger badge entrance or pulse when count changes.
  void _handleCountChange(int newCount) {
    if (newCount > 0 && _previousCount == 0) {
      // Badge appearing — entrance animation from zero.
      unawaited(_badgeController.forward(from: 0));
    } else if (newCount == 0 && _previousCount > 0) {
      // Badge disappearing — reverse the entrance animation.
      unawaited(_badgeController.reverse());
    } else if (newCount != _previousCount && newCount > 0) {
      // Count changed while badge stays visible — play real pulse.
      unawaited(_pulseController.forward(from: 0));
    }
    _previousCount = newCount;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, vm, child) {
        final count = vm.unreadCount;
        final amberColors = context.amberColors;
        final badgeBackground = amberColors.dangerMuted;
        final badgeForeground = amberColors.text;

        // Only schedule the post-frame callback when the count has actually
        // changed — avoids spurious animation calls on unrelated rebuilds.
        if (count != _previousCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _handleCountChange(count);
          });
        }

        return Semantics(
          label:
              'Notifications'
              '${count > 0 ? ", $count unread" : ""}',
          button: true,
          excludeSemantics: true,
          child: GestureDetector(
            key: NotificationBadgeButton.buttonKey,
            onTap: () async {
              if (_isOpeningModal) {
                AppLogger.d(
                  'Notification badge tap ignored while modal is opening',
                  tag: 'Notifications',
                );
                return;
              }
              setState(() => _isOpeningModal = true);
              AppInteractionStates.hapticTap();
              AppLogger.d(
                'Notification badge tapped, opening modal',
                tag: 'Notifications',
              );
              try {
                final selected = await NotificationsModal.show(context);
                if (selected != null && context.mounted) {
                  AppLogger.i(
                    'NotificationBadgeButton: notification selected',
                    tag: 'Notifications',
                  );
                  await context.read<DeepLinkService>().handleNotification(
                    context,
                    entityType: selected.relatedEntityType,
                    entityId: selected.relatedEntityId,
                    metadata: selected.metadata,
                  );
                }
              } finally {
                if (mounted) setState(() => _isOpeningModal = false);
              }
            },
            child: AppCardContainer(
              borderRadius: BorderRadius.circular(AppDimens.r16),
              padding: const EdgeInsets.all(AppDimens.p12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: amberColors.text,
                    size: AppLayout.iconStandard,
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      // Outer ScaleTransition drives the pulse (1.0→1.15→1.0).
                      // Inner ScaleTransition drives the entrance (0→1).
                      // Multiplying both lets the badge pop in on appearance
                      // and pulse on count change independently.
                      child: ScaleTransition(
                        scale: _pulseScale,
                        child: ScaleTransition(
                          scale: _badgeScale,
                          child: Container(
                            padding: const EdgeInsets.all(AppDimens.p4),
                            decoration: BoxDecoration(
                              // Dark rust wash keeps unread counts urgent while
                              // preserving AA contrast for the small badge text.
                              color: badgeBackground,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: AppDimens.p16,
                              minHeight: AppDimens.p16,
                            ),
                            child: Text(
                              count > 9 ? '9+' : count.toString(),
                              style: AppTypography.micro.copyWith(
                                color: badgeForeground,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
