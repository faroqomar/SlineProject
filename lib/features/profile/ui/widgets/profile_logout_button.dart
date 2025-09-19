import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/controllers/profile_controller.dart';
/// A button that logs out the current user and redirects to the login screen.
class ProfileLogoutButton extends StatelessWidget {
  final ProfileController controller;
  const ProfileLogoutButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await controller.signOut(context);
      },
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
}