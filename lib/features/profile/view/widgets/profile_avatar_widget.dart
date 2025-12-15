import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';

/// Widget for displaying and editing user profile avatar
class ProfileAvatarWidget extends StatelessWidget {
  final double radius;
  final bool enableEdit;

  const ProfileAvatarWidget({
    super.key,
    this.radius = 60,
    this.enableEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, controller, child) {
        final hasImage =
            controller.avatarSignedUrl != null &&
            controller.avatarSignedUrl!.isNotEmpty;
        final diameter = radius * 2;

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 3,
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(controller.avatarSignedUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? null
                    : Icon(Icons.person, size: radius, color: Colors.grey),
              ),
              if (enableEdit)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => controller.pickAndUploadAvatar(context),
                    ),
                  ),
                ),
              if (controller.avatarUploading)
                Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
