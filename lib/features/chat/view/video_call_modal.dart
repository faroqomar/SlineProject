import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';

/// Status of the video call.
enum CallStatus { calling, connected, ended }

/// A full-screen video call modal matching the new design system.
/// Features: calling animation, controls, timer display.
class VideoCallModal extends StatefulWidget {
  final String userName;
  final String? userAvatar;
  final VoidCallback? onCallEnded;

  const VideoCallModal({
    super.key,
    required this.userName,
    this.userAvatar,
    this.onCallEnded,
  });

  @override
  State<VideoCallModal> createState() => _VideoCallModalState();
}

class _VideoCallModalState extends State<VideoCallModal>
    with TickerProviderStateMixin {
  CallStatus _status = CallStatus.calling;
  bool _isMuted = false;
  bool _isVideoOn = true;
  int _callDuration = 0;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for calling state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate connection after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _status == CallStatus.calling) {
        setState(() {
          _status = CallStatus.connected;
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  String _formatDuration() {
    final minutes = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_callDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _endCall() {
    _timer?.cancel();
    widget.onCallEnded?.call();
    Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOn = !_isVideoOn;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.almostBlack,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.teal.withValues(alpha: 0.3),
                  AppColors.almostBlack,
                ],
              ),
            ),
          ),

          // Noise texture overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Container(
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Main area with avatar
                Expanded(
                  child: _buildMainContent(),
                ),

                // Controls
                _buildControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        children: [
          Text(
            _status == CallStatus.calling ? 'CALLING...' : 'CONNECTED',
            style: AppTypography.caption.copyWith(
              color: Colors.white60,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          if (_status == CallStatus.connected)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.lightRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(),
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse rings (only when calling)
                  if (_status == CallStatus.calling) ...[
                    Transform.scale(
                      scale: _pulseAnimation.value * 1.2,
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.teal.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.teal.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],

                  // Avatar
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade800,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isVideoOn
                          ? Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white54,
                            )
                          : Icon(
                              Icons.videocam_off,
                              size: 48,
                              color: Colors.white54,
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimens.p24),

          // User name
          Text(
            widget.userName,
            style: AppTypography.h3.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      margin: const EdgeInsets.all(AppDimens.p32),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.r30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            isActive: _isMuted,
            onTap: _toggleMute,
          ),

          // End call button
          GestureDetector(
            onTap: _endCall,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.lightRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightRed.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // Video toggle button
          _buildControlButton(
            icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
            isActive: !_isVideoOn,
            onTap: _toggleVideo,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.almostBlack : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

