import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/ui/controller/profile_controller.dart';
import 'profile_password_reset.dart';

/// This widget contains the form fields used to update the user's profile info
class ProfileForm extends StatefulWidget {
  final ProfileController controller;
  const ProfileForm({super.key, required this.controller});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      widget.controller.loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Full Name"),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller.nameController,
            decoration: const InputDecoration(
              hintText: "Enter your name",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? "Name is required" : null,
          ),
          const SizedBox(height: 16),

          const Text("Email"),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller.emailController,
            decoration: const InputDecoration(
              hintText: "Enter your email",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || !value.contains('@') ? "Invalid email" : null,
          ),
          const SizedBox(height: 16),

          const Text("Bio"),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller.bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Write something about yourself...",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          ProfilePasswordReset(controller: widget.controller),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.controller.updateProfile();
              },
              child: const Text("Update Profile"),
            ),
          ),
        ],
      ),
    );
  }
}