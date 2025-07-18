import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/features/profile/ui/controller/profile_controller.dart';
/// A button that triggers Supabase password reset email.
class ProfilePasswordReset extends StatelessWidget {
  final ProfileController controller;
  const ProfilePasswordReset({super.key, required this.controller});

  Future<void> _sendPasswordReset(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(user.email!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _sendPasswordReset(context),
      child: const Text('Reset Password'),
    );
  }
}