import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/core/navigation/main_nav_destinations.dart';
import 'package:sline_app/core/providers/navigation_provider.dart';
import 'package:sline_app/core/providers/system_config_view_model.dart';
import 'package:sline_app/core/services/logger_service.dart';
import 'package:sline_app/core/theme/app_colors.dart';
import 'package:sline_app/core/theme/app_decorations.dart';
import 'package:sline_app/core/theme/app_dimens.dart';
import 'package:sline_app/core/theme/app_layout.dart';
import 'package:sline_app/core/theme/app_motion.dart';
import 'package:sline_app/core/theme/app_states.dart';
import 'package:sline_app/core/theme/app_theme.dart';
import 'package:sline_app/core/theme/app_typography.dart';
import 'package:sline_app/core/theme/designs/amber_dusk/amber_dusk_tokens.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/auth/viewmodels/auth_form_view_model.dart';

/// Signup screen (MVVM) with stagger entrance animations, inline error
/// handling, password strength indicator, and form shake on invalid submit.
///
/// Architecture: Uses a local AuthFormViewModel provider for scoped state.
/// The View handles navigation and inline error display based on ViewModel
/// state, keeping the ViewModel framework-agnostic.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.authViewModel});

  /// Optional test seam for exercising success navigation without real auth IO.
  final AuthFormViewModel? authViewModel;

  static const Key nameFieldKey = ValueKey<String>('signup_name_field');
  static const Key emailFieldKey = ValueKey<String>('signup_email_field');
  static const Key passwordFieldKey = ValueKey<String>('signup_password_field');
  static const Key confirmPasswordFieldKey = ValueKey<String>(
    'signup_confirm_password_field',
  );
  static const Key signUpButtonKey = ValueKey<String>('signup_button');
  static const Key signInLinkKey = ValueKey<String>('signup_signin_link');

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- Animation controllers ---
  late AnimationController _staggerController;
  late AnimationController _shakeController;

  // --- Stagger entrance animations ---
  late Animation<Offset> _logoSlide;
  late Animation<double> _logoFade;
  late Animation<Offset> _nameSlide;
  late Animation<double> _nameFade;
  late Animation<Offset> _emailSlide;
  late Animation<double> _emailFade;
  late Animation<Offset> _passwordSlide;
  late Animation<double> _passwordFade;
  late Animation<Offset> _confirmSlide;
  late Animation<double> _confirmFade;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonFade;

  // --- Inline error state ---
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;

  // --- Password strength ---
  double _passwordStrength = 0.0;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp('[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp('[0-9]'));
  bool get _hasSpecialChar =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _confirmMatches =>
      _confirmPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text == _passwordController.text;

  @override
  void initState() {
    super.initState();

    // Stagger controller (500ms total for entrance)
    _staggerController = AnimationController(
      vsync: this,
      duration: AppMotion.emphasis,
    );

    // Shake controller (300ms for error shake)
    _shakeController = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );

    // Build stagger intervals: each element slides + fades in sequence
    _logoSlide = _buildSlide(0.0, 0.25);
    _logoFade = _buildFade(0.0, 0.25);
    _nameSlide = _buildSlide(0.10, 0.35);
    _nameFade = _buildFade(0.10, 0.35);
    _emailSlide = _buildSlide(0.20, 0.45);
    _emailFade = _buildFade(0.20, 0.45);
    _passwordSlide = _buildSlide(0.30, 0.55);
    _passwordFade = _buildFade(0.30, 0.55);
    _confirmSlide = _buildSlide(0.40, 0.65);
    _confirmFade = _buildFade(0.40, 0.65);
    _buttonSlide = _buildSlide(0.50, 0.75);
    _buttonFade = _buildFade(0.50, 0.75);

    // Listen for password changes to compute strength
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);

    // Trigger entrance animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppLogger.d('Signup stagger animation started', tag: 'Auth');
      unawaited(_staggerController.forward());
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _shakeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Animation helpers ---

  Animation<Offset> _buildSlide(double begin, double end) {
    return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: AppMotion.curveDecel),
      ),
    );
  }

  Animation<double> _buildFade(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: AppMotion.curveDecel),
      ),
    );
  }

  // --- Password strength calculation ---

  void _onPasswordChanged() {
    final password = _passwordController.text;
    var strength = 0.0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp('[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp('[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    if (strength != _passwordStrength) {
      setState(() => _passwordStrength = strength);
    }

    // Clear password error when user types
    if (_passwordError != null) {
      setState(() => _passwordError = null);
    }
  }

  void _onConfirmPasswordChanged() {
    setState(() {
      // Rebuild the confirm suffix and the required password checklist row.
      _confirmError = null;
    });
  }

  String _strengthLabel(double strength) {
    if (strength <= 0.25) return 'Weak';
    if (strength <= 0.5) return 'Fair';
    if (strength <= 0.75) return 'Good';
    return 'Strong';
  }

  Color _strengthColor(AppColorScheme colorScheme, double strength) {
    if (strength <= 0.5) {
      // Danger (red) to warning (orange/gold)
      return Color.lerp(
        colorScheme.danger,
        colorScheme.warning,
        strength / 0.5,
      )!;
    }
    // Warning (orange/gold) to success (green)
    return Color.lerp(
      colorScheme.warning,
      colorScheme.success,
      (strength - 0.5) / 0.5,
    )!;
  }

  // --- Shake animation ---

  void _triggerShake() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_shakeController.forward(from: 0));
  }

  double _shakeOffset(double animationValue) {
    // Produce a sinusoidal shake using AppInteractionStates constants
    return sin(animationValue * pi * AppInteractionStates.shakeCycles * 2) *
        AppInteractionStates.shakeAmplitude;
  }

  // --- Clear inline errors ---

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _generalError = null;
    });
  }

  // --- Handle registration ---

  Future<void> _handleRegister(AuthFormViewModel authVM) async {
    AppLogger.i('Signup form submitted', tag: 'Auth');
    _clearErrors();

    if (context.read<SystemConfigViewModel?>()?.config.disableSignups ??
        false) {
      if (!mounted) return;
      setState(() {
        _generalError = 'Signups are temporarily disabled.';
      });
      _triggerShake();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _triggerShake();
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // Client-side validation
    if (password != confirm) {
      if (!mounted) return;
      setState(() {
        _confirmError = 'Passwords do not match';
      });
      _triggerShake();
      return;
    }

    final success = await authVM.register(
      email: email,
      password: password,
      fullName: name,
    );

    if (!mounted) return;

    if (success) {
      AppLogger.i('Signup successful, navigating to main', tag: 'Auth');
      context.read<NavigationProvider?>()?.setCurrentIndex(
        MainNavDestinations.home,
      );
      unawaited(
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/main', (route) => false),
      );
    } else {
      final error = authVM.error ?? 'Registration failed';
      AppLogger.e('Signup failed', tag: 'Auth', error: error);
      setState(() {
        _generalError = error;
      });
      _triggerShake();
    }
  }

  // --- Build inline error widget ---

  Widget _buildInlineError(String? errorText) {
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.curveStandard,
      alignment: Alignment.topLeft,
      child: AnimatedOpacity(
        opacity: errorText != null ? 1.0 : 0.0,
        duration: AppMotion.fast,
        child: errorText != null
            ? Padding(
                padding: const EdgeInsets.only(
                  top: AppDimens.p4,
                  left: AppDimens.p4,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    errorText,
                    style: AppTypography.caption.copyWith(
                      color: context.colorScheme.danger,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  // --- Build password strength indicator ---

  Widget _buildPasswordStrength(AppColorScheme colorScheme) {
    final label = _strengthLabel(_passwordStrength);
    final color = _strengthColor(colorScheme, _passwordStrength);
    final amber = context.amberColors;

    return Semantics(
      label: 'Password strength: $label',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimens.p8),
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              return Stack(
                children: [
                  // Background track
                  Container(
                    height: AppDimens.p4,
                    width: totalWidth,
                    decoration: BoxDecoration(
                      color: colorScheme.divider,
                      borderRadius: BorderRadius.circular(AppDimens.r4),
                    ),
                  ),
                  // Filled bar
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.curveStandard,
                    height: AppDimens.p4,
                    width: _passwordStrength * totalWidth,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppDimens.r4),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimens.p4),
          AnimatedOpacity(
            opacity: _passwordController.text.isNotEmpty ? 1.0 : 0.0,
            duration: AppMotion.fast,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: color),
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            'Required',
            style: AppTypography.micro.copyWith(
              color: amber.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.p4),
          _PasswordRequirementRow(
            label: 'At least 8 characters',
            isMet: _hasMinLength,
            textColor: amber.muted,
            successColor: amber.forest,
          ),
          _PasswordRequirementRow(
            label: 'Passwords match',
            isMet: _confirmMatches,
            textColor: amber.muted,
            successColor: amber.forest,
          ),
          const SizedBox(height: AppDimens.p4),
          Text(
            'Strength hints',
            style: AppTypography.micro.copyWith(
              color: amber.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.p4),
          _PasswordRequirementRow(
            label: 'Add an uppercase letter',
            isMet: _hasUppercase,
            textColor: amber.muted,
            successColor: amber.forest,
          ),
          _PasswordRequirementRow(
            label: 'Add a number',
            isMet: _hasNumber,
            textColor: amber.muted,
            successColor: amber.forest,
          ),
          _PasswordRequirementRow(
            label: 'Add a special character',
            isMet: _hasSpecialChar,
            textColor: amber.muted,
            successColor: amber.forest,
          ),
        ],
      ),
    );
  }

  // --- Build confirm password suffix icon ---

  Widget? _buildConfirmSuffix(AppColorScheme colorScheme) {
    if (_confirmPasswordController.text.isEmpty) return null;

    final matches = _confirmPasswordController.text == _passwordController.text;
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.p12),
      child: Icon(
        matches ? Icons.check_circle : Icons.cancel,
        color: matches ? colorScheme.success : colorScheme.danger,
        size: AppLayout.iconStandard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amber = context.amberColors;
    final panelRecipe = AmberDuskTokens.surfaces.raised;
    final signupsDisabled =
        context.watch<SystemConfigViewModel?>()?.config.disableSignups ?? false;

    final authProvider = widget.authViewModel;
    final signupScaffold = Scaffold(
      backgroundColor: amber.page,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [amber.background, amber.page],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p20,
                vertical: AppDimens.p24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.formMaxWidth,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: panelRecipe.fill,
                    borderRadius: BorderRadius.circular(panelRecipe.radius),
                    border: Border.all(
                      color: panelRecipe.border,
                      width: AmberDuskTokens.spacing.borderWidth,
                    ),
                    boxShadow: AppDecorations.elevation(
                      panelRecipe.elevationLevel,
                      isDark: colorScheme.isDark,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.p24),
                    child: Form(
                      key: _formKey,
                      child: Consumer<AuthFormViewModel>(
                        builder: (context, authVM, _) {
                          return AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  _shakeOffset(_shakeController.value),
                                  0,
                                ),
                                child: child,
                              );
                            },
                            child: _SignupFormContents(
                              logoSlide: _logoSlide,
                              logoFade: _logoFade,
                              nameSlide: _nameSlide,
                              nameFade: _nameFade,
                              emailSlide: _emailSlide,
                              emailFade: _emailFade,
                              passwordSlide: _passwordSlide,
                              passwordFade: _passwordFade,
                              confirmSlide: _confirmSlide,
                              confirmFade: _confirmFade,
                              buttonSlide: _buttonSlide,
                              buttonFade: _buttonFade,
                              nameController: _nameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              generalError: _generalError,
                              nameError: _nameError,
                              emailError: _emailError,
                              passwordError: _passwordError,
                              confirmError: _confirmError,
                              signupsDisabled: signupsDisabled,
                              buildInlineError: _buildInlineError,
                              buildPasswordStrength: _buildPasswordStrength,
                              buildConfirmSuffix: _buildConfirmSuffix,
                              onNameChanged: () {
                                if (_nameError != null) {
                                  setState(() => _nameError = null);
                                }
                              },
                              onEmailChanged: () {
                                if (_emailError != null) {
                                  setState(() => _emailError = null);
                                }
                              },
                              onRegister: () => _handleRegister(authVM),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (authProvider != null) {
      return ChangeNotifierProvider<AuthFormViewModel>.value(
        value: authProvider,
        child: signupScaffold,
      );
    }

    return ChangeNotifierProvider<AuthFormViewModel>(
      create: (_) => AuthFormViewModel(),
      child: signupScaffold,
    );
  }
}

class _SignupFormContents extends StatelessWidget {
  const _SignupFormContents({
    required this.logoSlide,
    required this.logoFade,
    required this.nameSlide,
    required this.nameFade,
    required this.emailSlide,
    required this.emailFade,
    required this.passwordSlide,
    required this.passwordFade,
    required this.confirmSlide,
    required this.confirmFade,
    required this.buttonSlide,
    required this.buttonFade,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.generalError,
    required this.nameError,
    required this.emailError,
    required this.passwordError,
    required this.confirmError,
    required this.signupsDisabled,
    required this.buildInlineError,
    required this.buildPasswordStrength,
    required this.buildConfirmSuffix,
    required this.onNameChanged,
    required this.onEmailChanged,
    required this.onRegister,
  });

  final Animation<Offset> logoSlide;
  final Animation<double> logoFade;
  final Animation<Offset> nameSlide;
  final Animation<double> nameFade;
  final Animation<Offset> emailSlide;
  final Animation<double> emailFade;
  final Animation<Offset> passwordSlide;
  final Animation<double> passwordFade;
  final Animation<Offset> confirmSlide;
  final Animation<double> confirmFade;
  final Animation<Offset> buttonSlide;
  final Animation<double> buttonFade;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? generalError;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmError;
  final bool signupsDisabled;
  final Widget Function(String? errorText) buildInlineError;
  final Widget Function(AppColorScheme colorScheme) buildPasswordStrength;
  final Widget? Function(AppColorScheme colorScheme) buildConfirmSuffix;
  final VoidCallback onNameChanged;
  final VoidCallback onEmailChanged;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final amber = context.amberColors;
    final colorScheme = context.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // --- Header (Logo + Title + Subtitle) ---
        SlideTransition(
          position: logoSlide,
          child: FadeTransition(
            opacity: logoFade,
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: amber.primary,
                    borderRadius: BorderRadius.circular(
                      AmberDuskTokens.spacing.moduleRadius,
                    ),
                    boxShadow: AppDecorations.elevation(
                      AmberDuskTokens.surfaces.cta.elevationLevel,
                      isDark: colorScheme.isDark,
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: AppLayout.avatarHero,
                    child: Center(
                      child: Text(
                        'S',
                        style: AppTypography.logo.copyWith(
                          color: amber.textInverse,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.p24),
                Text(
                  'Create Account',
                  style: AmberDuskTokens.typography.screenTitle.copyWith(
                    color: amber.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.p8),
                Text(
                  'Create a secure workspace for bids, bookings, and messages.',
                  style: AmberDuskTokens.typography.body.copyWith(
                    color: amber.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (signupsDisabled) ...[
                  const SizedBox(height: AppDimens.p12),
                  _AuthNotice(
                    text: 'New account registration is temporarily paused.',
                    background: amber.dangerMuted,
                    foreground: amber.rust,
                  ),
                ],
                if (generalError != null) ...[
                  const SizedBox(height: AppDimens.p12),
                  AnimatedSize(
                    duration: AppMotion.fast,
                    curve: AppMotion.curveStandard,
                    child: _AuthNotice(
                      text: generalError!,
                      background: amber.dangerMuted,
                      foreground: amber.rust,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.p32),

        // --- Name Field ---
        SlideTransition(
          position: nameSlide,
          child: FadeTransition(
            opacity: nameFade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Full Name'),
                const SizedBox(height: AppDimens.p8),
                AppTextField(
                  fieldKey: SignupScreen.nameFieldKey,
                  controller: nameController,
                  hintText: 'Your full name',
                  showClearButton: true,
                  onChanged: (_) => onNameChanged(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                buildInlineError(nameError),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.p16),

        // --- Email Field ---
        SlideTransition(
          position: emailSlide,
          child: FadeTransition(
            opacity: emailFade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Email'),
                const SizedBox(height: AppDimens.p8),
                AppTextField(
                  fieldKey: SignupScreen.emailFieldKey,
                  controller: emailController,
                  hintText: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                  showClearButton: true,
                  onChanged: (_) => onEmailChanged(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                buildInlineError(emailError),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.p16),

        // --- Password Field ---
        SlideTransition(
          position: passwordSlide,
          child: FadeTransition(
            opacity: passwordFade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Password'),
                const SizedBox(height: AppDimens.p8),
                AppTextField(
                  fieldKey: SignupScreen.passwordFieldKey,
                  controller: passwordController,
                  hintText: 'Create a password',
                  obscureText: true,
                  showPasswordToggle: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                buildInlineError(passwordError),
                if (passwordController.text.isNotEmpty)
                  buildPasswordStrength(colorScheme),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.p16),

        // --- Confirm Password Field ---
        SlideTransition(
          position: confirmSlide,
          child: FadeTransition(
            opacity: confirmFade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Confirm Password'),
                const SizedBox(height: AppDimens.p8),
                AppTextField(
                  fieldKey: SignupScreen.confirmPasswordFieldKey,
                  controller: confirmPasswordController,
                  hintText: 'Confirm password',
                  obscureText: true,
                  showPasswordToggle: true,
                  suffixIcon: buildConfirmSuffix(colorScheme),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    return null;
                  },
                ),
                buildInlineError(confirmError),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.p16),
        Text(
          'By continuing, you agree to use SLine for real work, safe payments, '
          'and respectful messages.',
          style: AmberDuskTokens.typography.bodySmall.copyWith(
            color: amber.muted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.p24),

        // --- Actions ---
        SlideTransition(
          position: buttonSlide,
          child: FadeTransition(
            opacity: buttonFade,
            child: Consumer<AuthFormViewModel>(
              builder: (context, authVM, _) {
                return Column(
                  children: [
                    AppButton(
                      tapTargetKey: SignupScreen.signUpButtonKey,
                      text: 'Create Account',
                      isLoading: authVM.isLoading,
                      width: double.infinity,
                      onPressed: signupsDisabled ? null : onRegister,
                    ),
                    const SizedBox(height: AppDimens.p24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AmberDuskTokens.typography.bodySmall.copyWith(
                            color: amber.muted,
                          ),
                        ),
                        GestureDetector(
                          key: SignupScreen.signInLinkKey,
                          onTap: () {
                            AppLogger.i(
                              'Signin link tapped from signup',
                              tag: 'Auth',
                            );
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Sign In',
                            style: AmberDuskTokens.typography.control.copyWith(
                              color: amber.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/*
    return ChangeNotifierProvider(
      create: (_) => AuthFormViewModel(),
      child: Scaffold(
        backgroundColor: amber.page,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [amber.background, amber.page],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.p20,
                  vertical: AppDimens.p24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.formMaxWidth,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: panelRecipe.fill,
                      borderRadius: BorderRadius.circular(panelRecipe.radius),
                      border: Border.all(
                        color: panelRecipe.border,
                        width: AmberDuskTokens.spacing.borderWidth,
                      ),
                      boxShadow: AppDecorations.elevation(
                        panelRecipe.elevationLevel,
                        isDark: colorScheme.isDark,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.p24),
                      child: Form(
                        key: _formKey,
                        child: Consumer<AuthFormViewModel>(
                          builder: (context, authVM, _) {
                            return AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    _shakeOffset(_shakeController.value),
                                    0,
                                  ),
                                  child: child,
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // --- Header (Logo + Title + Subtitle) ---
                                  SlideTransition(
                                    position: _logoSlide,
                                    child: FadeTransition(
                                      opacity: _logoFade,
                                      child: Column(
                                        children: [
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: amber.primary,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AmberDuskTokens
                                                        .spacing
                                                        .moduleRadius,
                                                  ),
                                              boxShadow:
                                                  AppDecorations.elevation(
                                                    AmberDuskTokens
                                                        .surfaces
                                                        .cta
                                                        .elevationLevel,
                                                    isDark: colorScheme.isDark,
                                                  ),
                                            ),
                                            child: SizedBox.square(
                                              dimension: AppLayout.avatarHero,
                                              child: Center(
                                                child: Text(
                                                  'S',
                                                  style: AppTypography.logo
                                                      .copyWith(
                                                        color:
                                                            amber.textInverse,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: AppDimens.p24),
                                          Text(
                                            'Create Account',
                                            style: AmberDuskTokens
                                                .typography
                                                .screenTitle
                                                .copyWith(color: amber.text),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: AppDimens.p8),
                                          Text(
                                            'Create a secure workspace for '
                                            'bids, bookings, and messages.',
                                            style: AmberDuskTokens
                                                .typography
                                                .body
                                                .copyWith(color: amber.muted),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (signupsDisabled) ...[
                                            const SizedBox(
                                              height: AppDimens.p12,
                                            ),
                                            _AuthNotice(
                                              text:
                                                  'New account registration is '
                                                  'temporarily paused.',
                                              background: amber.dangerMuted,
                                              foreground: amber.rust,
                                            ),
                                          ],
                                          if (_generalError != null) ...[
                                            const SizedBox(
                                              height: AppDimens.p12,
                                            ),
                                            AnimatedSize(
                                              duration: AppMotion.fast,
                                              curve: AppMotion.curveStandard,
                                              child: _AuthNotice(
                                                text: _generalError!,
                                                background: amber.dangerMuted,
                                                foreground: amber.rust,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.p32),

                                  // --- Name Field ---
                                  SlideTransition(
                                    position: _nameSlide,
                                    child: FadeTransition(
                                      opacity: _nameFade,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const _FieldLabel('Full Name'),
                                          const SizedBox(height: AppDimens.p8),
                                          AppTextField(
                                            fieldKey: SignupScreen.nameFieldKey,
                                            controller: _nameController,
                                            hintText: 'Your full name',
                                            showClearButton: true,
                                            onChanged: (_) {
                                              if (_nameError != null) {
                                                setState(
                                                  () => _nameError = null,
                                                );
                                              }
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter your name';
                                              }
                                              return null;
                                            },
                                          ),
                                          _buildInlineError(_nameError),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.p16),

                                  // --- Email Field ---
                                  SlideTransition(
                                    position: _emailSlide,
                                    child: FadeTransition(
                                      opacity: _emailFade,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const _FieldLabel('Email'),
                                          const SizedBox(height: AppDimens.p8),
                                          AppTextField(
                                            fieldKey:
                                                SignupScreen.emailFieldKey,
                                            controller: _emailController,
                                            hintText: 'your@email.com',
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            showClearButton: true,
                                            onChanged: (_) {
                                              if (_emailError != null) {
                                                setState(
                                                  () => _emailError = null,
                                                );
                                              }
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter your '
                                                    'email';
                                              }
                                              if (!value.contains('@')) {
                                                return 'Please enter a valid '
                                                    'email';
                                              }
                                              return null;
                                            },
                                          ),
                                          _buildInlineError(_emailError),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.p16),

                                  // --- Password Field ---
                                  SlideTransition(
                                    position: _passwordSlide,
                                    child: FadeTransition(
                                      opacity: _passwordFade,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const _FieldLabel('Password'),
                                          const SizedBox(height: AppDimens.p8),
                                          AppTextField(
                                            fieldKey:
                                                SignupScreen.passwordFieldKey,
                                            controller: _passwordController,
                                            hintText: 'Create a password',
                                            obscureText: true,
                                            showPasswordToggle: true,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter a '
                                                    'password';
                                              }
                                              if (value.length < 8) {
                                                return 'Password must be at '
                                                    'least 8 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                          _buildInlineError(_passwordError),
                                          if (_passwordController
                                              .text
                                              .isNotEmpty)
                                            _buildPasswordStrength(colorScheme),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.p16),

                                  // --- Confirm Password Field ---
                                  SlideTransition(
                                    position: _confirmSlide,
                                    child: FadeTransition(
                                      opacity: _confirmFade,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const _FieldLabel('Confirm Password'),
                                          const SizedBox(height: AppDimens.p8),
                                          AppTextField(
                                            fieldKey: SignupScreen
                                                .confirmPasswordFieldKey,
                                            controller:
                                                _confirmPasswordController,
                                            hintText: 'Confirm password',
                                            obscureText: true,
                                            showPasswordToggle: true,
                                            suffixIcon: _buildConfirmSuffix(
                                              colorScheme,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please confirm your '
                                                    'password';
                                              }
                                              return null;
                                            },
                                          ),
                                          _buildInlineError(_confirmError),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimens.p16),
                                  Text(
                                    'By continuing, you agree to use SLine for '
                                    'real work, safe payments, and respectful '
                                    'messages.',
                                    style: AmberDuskTokens.typography.bodySmall
                                        .copyWith(color: amber.muted),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppDimens.p24),

                                  // --- Actions ---
                                  SlideTransition(
                                    position: _buttonSlide,
                                    child: FadeTransition(
                                      opacity: _buttonFade,
                                      child: Column(
                                        children: [
                                          AppButton(
                                            tapTargetKey:
                                                SignupScreen.signUpButtonKey,
                                            text: 'Create Account',
                                            isLoading: authVM.isLoading,
                                            width: double.infinity,
                                            onPressed: signupsDisabled
                                                ? null
                                                : () => _handleRegister(authVM),
                                          ),
                                          const SizedBox(height: AppDimens.p24),
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                'Already have an account? ',
                                                style: AmberDuskTokens
                                                    .typography
                                                    .bodySmall
                                                    .copyWith(
                                                      color: amber.muted,
                                                    ),
                                              ),
                                              GestureDetector(
                                                key: SignupScreen.signInLinkKey,
                                                onTap: () {
                                                  AppLogger.i(
                                                    'Signin link tapped from '
                                                    'signup',
                                                    tag: 'Auth',
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  'Sign In',
                                                  style: AmberDuskTokens
                                                      .typography
                                                      .control
                                                      .copyWith(
                                                        color: amber.primary,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
*/

/// Reusable field label for the grouped signup form.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final amber = context.amberColors;
    return Text(
      text,
      style: AmberDuskTokens.widgetTheme.fields.labelStyle.copyWith(
        color: amber.text,
      ),
    );
  }
}

/// Live-region notice used for disabled signup and account errors.
class _AuthNotice extends StatelessWidget {
  const _AuthNotice({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(
            AmberDuskTokens.spacing.moduleRadius,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.p12),
          child: Text(
            text,
            style: AmberDuskTokens.typography.bodySmall.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Compact requirement row used to make password rules scannable on phones.
class _PasswordRequirementRow extends StatelessWidget {
  const _PasswordRequirementRow({
    required this.label,
    required this.isMet,
    required this.textColor,
    required this.successColor,
  });

  final String label;
  final bool isMet;
  final Color textColor;
  final Color successColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.p4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? successColor : textColor,
            size: AppDimens.iconSizeSmall,
          ),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Text(
              label,
              style: AmberDuskTokens.typography.bodySmall.copyWith(
                color: isMet ? successColor : textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
