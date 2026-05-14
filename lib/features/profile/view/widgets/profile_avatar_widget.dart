import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';

/// Displays and edits the signed profile avatar from [ProfileViewModel].
///
/// The widget stays view-only: image picking and upload remain owned by the
/// ViewModel while this surface applies Amber Dusk media tokens.
class ProfileAvatarWidget extends StatelessWidget {
  /// Avatar radius used to size the circular image surface.
  final double radius;

  /// Whether the camera affordance should be shown.
  final bool enableEdit;

  /// Creates an avatar control for profile edit and account screens.
  const ProfileAvatarWidget({
    super.key,
    this.radius = AppDimens.p60,
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
        final amberColors = context.amberColors;
        final mediaTheme = AmberDuskTokens.widgetTheme.media;

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mediaTheme.avatarFallback,
                  border: Border.all(
                    color: amberColors.primary,
                    width: AppDimens.p2,
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
                    : Icon(
                        Icons.person,
                        size: radius,
                        color: mediaTheme.foreground,
                      ),
              ),
              if (enableEdit)
                Positioned(
                  bottom: AppDimens.p0,
                  right: AppDimens.p0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: amberColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colorScheme.phoneBackground,
                        width: AppDimens.p2,
                      ),
                    ),
                    child: IconButton(
                      tooltip: 'Change profile photo',
                      icon: Icon(
                        Icons.camera_alt,
                        color: amberColors.textInverse,
                        size: AppDimens.iconSmall,
                      ),
                      onPressed: () async {
                        AppLogger.d(
                          'Profile avatar upload requested',
                          tag: 'Profile',
                        );
                        await controller.pickAndUploadAvatar();
                        if (controller.avatarUploadError != null &&
                            context.mounted) {
                          AppLogger.w(
                            'Profile avatar upload failed',
                            tag: 'Profile',
                            json: <String, dynamic>{
                              'reason': controller.avatarUploadError,
                            },
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(controller.avatarUploadError!),
                            ),
                          );
                        } else {
                          AppLogger.d(
                            'Profile avatar upload completed',
                            tag: 'Profile',
                          );
                        }
                      },
                    ),
                  ),
                ),
              if (controller.avatarUploading)
                Semantics(
                  label: 'Uploading profile photo',
                  liveRegion: true,
                  child: Container(
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      color: amberColors.scrim,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: AppDimens.p24,
                        height: AppDimens.p24,
                        child: CircularProgressIndicator(
                          color: amberColors.primary,
                          strokeWidth: AppDimens.p2,
                        ),
                      ),
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
