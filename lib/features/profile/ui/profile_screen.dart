import 'package:flutter/material.dart';
import 'package:sline_app/features/profile/ui/widgets/profile_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const ProfileView(),
    );
  }
}