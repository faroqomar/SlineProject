import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/controllers/profile_controller.dart';

/// ProfileAvatar widget displays the user's profile image and allows updating it.
class ProfileAvatar extends StatelessWidget {
  final ProfileController controller;
  const ProfileAvatar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasImage = controller.avatarSignedUrl != null && controller.avatarSignedUrl!.isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: hasImage
              ? NetworkImage(controller.avatarSignedUrl!)
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 4,
          child: GestureDetector(
            onTap: () => controller.pickAndUploadAvatar(context),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ),
        if (controller.avatarUploading)
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
      ],
    );
  }
}