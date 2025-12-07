import 'package:flutter/material.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/widgets/glass_container.dart';

class VideoCallModal extends StatefulWidget {
  final String name;
  final String? avatarUrl;

  const VideoCallModal({super.key, required this.name, this.avatarUrl});

  @override
  State<VideoCallModal> createState() => _VideoCallModalState();
}

class _VideoCallModalState extends State<VideoCallModal> with SingleTickerProviderStateMixin {
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isConnected = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.teal.withValues(alpha: 0.3),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Header
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: AppDimens.p24),
                child: Column(
                  children: [
                    Text(
                      _isConnected ? 'Connected' : 'Calling...',
                      style: AppTypography.captionBold.copyWith(
                        color: Colors.white60,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p8),
                    if (_isConnected)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '04:23',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Avatar Pulse
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_isConnected)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Container(
                            width: 150 + (_controller.value * 50),
                            height: 150 + (_controller.value * 50),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 1 - _controller.value),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          widget.name.isNotEmpty ? widget.name[0] : 'U',
                          style: AppTypography.h1.copyWith(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p24),
                Text(
                  widget.name,
                  style: AppTypography.h3.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),

          // Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p24, vertical: AppDimens.p16),
                borderRadius: BorderRadius.circular(AppDimens.r30),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      isActive: _isMuted,
                      onTap: () => setState(() => _isMuted = !_isMuted),
                    ),
                    const SizedBox(width: AppDimens.p24),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p24),
                    _buildControlButton(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      isActive: _isVideoOff,
                      onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                    ),
                  ],
                ),
              ),
            ),
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
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
