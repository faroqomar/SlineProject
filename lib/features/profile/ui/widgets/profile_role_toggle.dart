import 'package:flutter/material.dart';
import '../controller/profile_controller.dart';
/// A toggle switch to change between Client and Freelancer roles.
class ProfileRoleToggle extends StatelessWidget {
  final ProfileController controller;

  const ProfileRoleToggle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isFreelancer = controller.nameController.text.contains('Freelancer'); // Replace with real logic

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Role:"),
        Row(
          children: [
            const Text("Client"),
            Switch(
              value: isFreelancer,
              onChanged: (value) {
                final role = value ? 'freelancer' : 'client';
                controller.changeRole(role);
              },
            ),
            const Text("Freelancer"),
          ],
        ),
      ],
    );
  }
}