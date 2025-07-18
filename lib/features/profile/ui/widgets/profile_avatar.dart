import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/ui/controller/profile_controller.dart';

/// ProfileAvatar widget displays the user's profile image and allows updating it.
class ProfileAvatar extends StatelessWidget {
  final ProfileController controller;
  const ProfileAvatar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/images/default_avatar.png'),
        ),
        Positioned(
          bottom: 0,
          right: 4,
          child: GestureDetector(
            onTap: () {
              // TODO: implement pickImage() in ProfileController
            },
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
      ],
    );
  }
}