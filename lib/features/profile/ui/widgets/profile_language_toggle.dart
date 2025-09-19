

import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/controllers/profile_controller.dart';

/// A simple language toggle dropdown.
class ProfileLanguageToggle extends StatelessWidget {
  final ProfileController controller;
  const ProfileLanguageToggle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text("Language: "),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: 'en', // Default value, should ideally be dynamic
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
          ],
          onChanged: (value) {
            // Future: Save language preference and trigger locale change
          },
        )
      ],
    );
  }
}