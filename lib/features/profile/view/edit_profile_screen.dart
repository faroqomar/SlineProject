import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_card_container.dart';
import 'package:sline_app/features/profile/view/widgets/profile_avatar_widget.dart';
import 'package:sline_app/features/profile/viewmodels/profile_view_model.dart';

/// Lets the current user edit basic profile fields and local skill chips.
///
/// Profile persistence remains owned by [ProfileViewModel]; this screen only
/// validates form input and maps ViewModel state into Amber Dusk surfaces.
class EditProfileScreen extends StatefulWidget {
  /// Creates the edit profile route.
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _skillController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seeded) {
      final vm = context.read<ProfileViewModel>();
      _nameController.text = vm.loadedName ?? '';
      _emailController.text = vm.loadedEmail ?? '';
      _bioController.text = vm.loadedBio ?? '';
      _seeded = true;
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amberColors = context.amberColors;
    final statusPills = AmberDuskTokens.widgetTheme.statusPills;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colorScheme.phoneBackground,
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, child) {
          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.p24,
                    topPadding + AppDimens.p24,
                    AppDimens.p24,
                    AppDimens.p16,
                  ),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: AppDimens.touchTarget,
                        child: IconButton(
                          tooltip: 'Back',
                          style: IconButton.styleFrom(
                            backgroundColor: amberColors.surface,
                            foregroundColor: amberColors.text,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.r12,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                      const SizedBox(width: AppDimens.p16),
                      Text(
                        'Edit Profile',
                        style: AppTypography.h3.copyWith(
                          color: colorScheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.p24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Avatar
                        const Center(
                          // ProfileAvatarWidget handles tap and edit icon internally now
                          child: ProfileAvatarWidget(
                            radius: AppDimens.p50,
                            enableEdit: true,
                          ),
                        ),
                        const SizedBox(height: AppDimens.p24),

                        // Basic Info
                        AppCardContainer(
                          padding: const EdgeInsets.all(AppDimens.p16),
                          borderRadius: BorderRadius.circular(AppDimens.r20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Basic Info',
                                style: AppTypography.h5.copyWith(
                                  color: colorScheme.text,
                                ),
                              ),
                              const SizedBox(height: AppDimens.p16),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                colorScheme: colorScheme,
                                validator: (v) =>
                                    v!.isEmpty ? 'Name is required' : null,
                              ),
                              const SizedBox(height: AppDimens.p16),
                              _buildTextField(
                                controller: _bioController,
                                label: 'Bio',
                                icon: Icons.info_outline,
                                colorScheme: colorScheme,
                                maxLines: 3,
                              ),
                              const SizedBox(height: AppDimens.p16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                colorScheme: colorScheme,
                                keyboardType: TextInputType.emailAddress,
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.p24),

                        // Skills
                        AppCardContainer(
                          padding: const EdgeInsets.all(AppDimens.p16),
                          borderRadius: BorderRadius.circular(AppDimens.r20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Skills',
                                style: AppTypography.h5.copyWith(
                                  color: colorScheme.text,
                                ),
                              ),
                              const SizedBox(height: AppDimens.p16),
                              Wrap(
                                spacing: AppDimens.p8,
                                runSpacing: AppDimens.p8,
                                children: [
                                  ...vm.skills.map(
                                    (skill) => Chip(
                                      label: Text(skill),
                                      backgroundColor:
                                          statusPills.primary.background,
                                      labelStyle: AppTypography.bodySmall
                                          .copyWith(
                                            color:
                                                statusPills.primary.foreground,
                                          ),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: AppDimens.p14,
                                      ),
                                      onDeleted: () => vm.removeSkill(skill),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          statusPills.radius,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ActionChip(
                                    label: const Text('Add +'),
                                    backgroundColor: colorScheme.cardBackground,
                                    onPressed: () =>
                                        _showAddSkillDialog(context, vm),
                                    side: BorderSide(
                                      color: colorScheme.textSecondary
                                          .withValues(alpha: 0.3),
                                    ),
                                    labelStyle: AppTypography.bodySmall
                                        .copyWith(
                                          color: colorScheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.p32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: AmberDuskTokens.widgetTheme.buttons.minHeight,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: amberColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimens.r16,
                                ),
                              ),
                            ),
                            onPressed: vm.isLoadingUpdate
                                ? null
                                : () async {
                                    if (!(_formKey.currentState?.validate() ??
                                        false)) {
                                      return;
                                    }
                                    try {
                                      await vm.updateProfile(
                                        name: _nameController.text.trim(),
                                        bio: _bioController.text.trim(),
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } on Exception catch (e, st) {
                                      AppLogger.e(
                                        'EditProfileScreen: save failed',
                                        tag: 'Profile',
                                        error: e,
                                        stackTrace: st,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to save profile. Please try again.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: vm.isLoadingUpdate
                                ? const SizedBox(
                                    width: AppDimens.p24,
                                    height: AppDimens.p24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: AppDimens.p2,
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: AppTypography.bodyLarge.copyWith(
                                      color: amberColors.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.p48),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppColorScheme colorScheme,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: AppTypography.bodyMedium.copyWith(color: colorScheme.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall.copyWith(
          color: colorScheme.textSecondary,
        ),
        prefixIcon: Icon(
          icon,
          color: colorScheme.textSecondary,
          size: AppDimens.iconSmall,
        ),
        filled: true,
        fillColor: colorScheme.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide(color: context.amberColors.primary),
        ),
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context, ProfileViewModel vm) {
    _skillController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colorScheme.cardBackground,
        title: Text(
          'Add Skill',
          style: AppTypography.h5.copyWith(color: context.colorScheme.text),
        ),
        content: TextField(
          controller: _skillController,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(
            color: context.colorScheme.text,
          ),
          decoration: const InputDecoration(hintText: 'e.g. Flutter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              vm.addSkill(_skillController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
