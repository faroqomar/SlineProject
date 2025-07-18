import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/profile_controller.dart';
import 'profile_avatar.dart';
import 'profile_form.dart';
import 'profile_password_reset.dart';
import 'profile_language_toggle.dart';
import 'profile_role_toggle.dart';
import 'profile_logout_button.dart';

/// Displays the user's profile content in a scrollable layout.
/// 
/// Includes avatar, editable form, password reset, language toggle,
/// role toggle, and logout functionality.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileAvatar(controller: controller),
              const SizedBox(height: 24),
              ProfileForm(controller: controller),
              const SizedBox(height: 24),
              ProfilePasswordReset(controller: controller),
              const SizedBox(height: 24),
              ProfileLanguageToggle(controller: controller),
              const SizedBox(height: 24),
              ProfileRoleToggle(controller: controller),
              const SizedBox(height: 24),
              ProfileLogoutButton(controller: controller),
            ],
          ),
        );
      },
    );
  }
}