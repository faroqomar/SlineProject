import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sline_app/app/main_navigation_screen.dart';
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
import 'package:sline_app/core/utils/transitions/custom_route_transitions.dart';
import 'package:sline_app/core/widgets/app_button.dart';
import 'package:sline_app/core/widgets/app_text_field.dart';
import 'package:sline_app/features/auth/view/forgot_password_screen.dart';
import 'package:sline_app/features/auth/viewmodels/auth_form_view_model.dart';
import 'package:sline_app/features/auth/viewmodels/auth_session_view_model.dart';

/// Login screen for user authentication (MVVM) with staggered entrance
/// animations, inline error handling, and form shake on invalid submit.
///
/// Architecture: Uses a local AuthFormViewModel provider for scoped state.
/// The View handles navigation and inline error display based on ViewModel
/// state, keeping the ViewModel framework-agnostic.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authViewModelFactory,
    this.mainNavigationBuilder,
  });

  final AuthFormViewModel Function()? authViewModelFactory;
  final WidgetBuilder? mainNavigationBuilder;

  static const Key emailFieldKey = ValueKey<String>('login_email_field');
  static const Key passwordFieldKey = ValueKey<String>('login_password_field');
  static const Key signInButtonKey = ValueKey<String>('login_sign_in_button');

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── Stagger entrance animation ──────────────────────────────
  late final AnimationController _staggerController;
  late final AnimationController _shakeController;

  // ── Per-element stagger animations (slide + fade) ───────────
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _emailSlide;
  late final Animation<double> _emailFade;
  late final Animation<Offset> _passwordSlide;
  late final Animation<double> _passwordFade;
  late final Animation<Offset> _signInSlide;
  late final Animation<double> _signInFade;
  late final Animation<Offset> _signUpSlide;
  late final Animation<double> _signUpFade;

  // ── Inline error state ──────────────────────────────────────
  String? _emailError;
  String? _passwordError;

  // ── Per-field validation state ──────────────────────────────
  bool? _emailValid;
  bool? _passwordValid;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();

    // Stagger controller — 500ms total
    _staggerController = AnimationController(
      duration: AppMotion.emphasis,
      vsync: this,
    );

    // Shake controller — 300ms
    _shakeController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );

    // Build stagger intervals: each element gets a slide + fade pair.
    _logoSlide = _buildSlide(0.0, 0.3);
    _logoFade = _buildFade(0.0, 0.3);
    _emailSlide = _buildSlide(0.15, 0.45);
    _emailFade = _buildFade(0.15, 0.45);
    _passwordSlide = _buildSlide(0.30, 0.60);
    _passwordFade = _buildFade(0.30, 0.60);
    _signInSlide = _buildSlide(0.45, 0.75);
    _signInFade = _buildFade(0.45, 0.75);
    _signUpSlide = _buildSlide(0.55, 0.85);
    _signUpFade = _buildFade(0.55, 0.85);

    // Start stagger after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppLogger.d('Login stagger animation started', tag: 'Auth');
      unawaited(_staggerController.forward());

      // Show session errors inline (if any)
      try {
        final sessionVm = context.read<AuthSessionViewModel>();
        final sessionError = sessionVm.error;
        if (sessionError != null && sessionError.isNotEmpty) {
          setState(() => _emailError = sessionError);
          sessionVm.clearError();
        }
      } on ProviderNotFoundException catch (_) {
        // AuthSessionViewModel not provided (e.g. in tests)
      }
    });
  }

  /// Build a slide animation (Offset(0, 0.3) -> Offset.zero) for a stagger
  /// interval.
  Animation<Offset> _buildSlide(double begin, double end) {
    return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: AppMotion.curveDecel),
      ),
    );
  }

  /// Build a fade animation (0 -> 1) for a stagger interval.
  Animation<double> _buildFade(double begin, double end) {
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(begin, end, curve: AppMotion.curveDecel),
      ),
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Per-field validation ────────────────────────────────────

  void _onEmailChanged(String value) {
    final trimmed = value.trim();
    setState(() {
      if (trimmed.isEmpty) {
        _emailValid = null;
        _emailError = null;
      } else {
        _emailValid = _emailRegex.hasMatch(trimmed);
        if (_emailValid!) _emailError = null;
      }
    });
  }

  void _onPasswordChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordValid = null;
        _passwordError = null;
      } else {
        _passwordValid = value.length >= 6;
        if (_passwordValid!) _passwordError = null;
      }
    });
  }

  // ── Form shake ─────────────────────────────────────────────

  void _triggerShake() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_shakeController.forward(from: 0));
  }

  // ── Login handler ──────────────────────────────────────────

  Future<void> _handleLogin(AuthFormViewModel authVM) async {
    AppLogger.i('Login form submitted', tag: 'Auth');

    // Clear previous inline errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate fields
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    var hasError = false;

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      hasError = true;
    } else if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter your password');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      hasError = true;
    }

    if (hasError) {
      _triggerShake();
      return;
    }

    final success = await authVM.login(email: email, password: password);

    if (!mounted) return;

    if (success) {
      AppLogger.i('Login successful, navigating to main', tag: 'Auth');
      unawaited(
        Navigator.pushReplacement(
          context,
          SlinePageRoute.forwardPush(
            child:
                widget.mainNavigationBuilder?.call(context) ??
                const MainNavigationScreen(),
          ),
        ),
      );
    } else {
      final error = authVM.error ?? 'Login failed';
      AppLogger.e('Login failed', tag: 'Auth');
      setState(() => _emailError = error);
      _triggerShake();
    }
  }

  // ── Validation icon builder ────────────────────────────────

  Widget _buildValidationIcon(bool? isValid, AppColorScheme colorScheme) {
    if (isValid == null) return const SizedBox.shrink();

    final icon = isValid
        ? Icon(
            Icons.check_circle,
            color: colorScheme.success,
            size: AppLayout.iconStandard,
          )
        : Icon(
            Icons.cancel,
            color: colorScheme.danger,
            size: AppLayout.iconStandard,
          );

    final label = isValid ? 'Valid input' : 'Invalid input';

    return AnimatedSwitcher(
      duration: AppMotion.fast,
      child: Semantics(
        label: label,
        child: Padding(
          key: ValueKey<bool>(isValid),
          padding: const EdgeInsets.only(right: AppDimens.p12),
          child: icon,
        ),
      ),
    );
  }

  // ── Inline error widget ────────────────────────────────────

  Widget _buildInlineError(String? errorText, AppColorScheme colorScheme) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.curveStandard,
      alignment: Alignment.topLeft,
      child: AnimatedOpacity(
        opacity: hasError ? 1.0 : 0.0,
        duration: AppMotion.fast,
        child: hasError
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
                      color: colorScheme.danger,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  // ── Stagger wrapper ────────────────────────────────────────

  Widget _staggered({
    required Animation<Offset> slide,
    required Animation<double> fade,
    required Widget child,
  }) {
    return SlideTransition(
      position: slide,
      child: FadeTransition(opacity: fade, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final amber = context.amberColors;
    final panelRecipe = AmberDuskTokens.surfaces.raised;
    final signupsDisabled =
        context.watch<SystemConfigViewModel?>()?.config.disableSignups ?? false;

    return ChangeNotifierProvider(
      create: (_) => widget.authViewModelFactory?.call() ?? AuthFormViewModel(),
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
                // Form shake wrapper
                child: AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        sin(
                              _shakeController.value *
                                  pi *
                                  AppInteractionStates.shakeCycles,
                            ) *
                            AppInteractionStates.shakeAmplitude,
                        0,
                      ),
                      child: child,
                    );
                  },
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
                          child: Column(
                            children: [
                              // --- Header ---
                              // A stable trust mark keeps first-run auth calm
                              // while using Amber Dusk's warm surface language.
                              _staggered(
                                slide: _logoSlide,
                                fade: _logoFade,
                                child: Column(
                                  children: [
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: amber.primary,
                                        borderRadius: BorderRadius.circular(
                                          AmberDuskTokens.spacing.moduleRadius,
                                        ),
                                        boxShadow: AppDecorations.elevation(
                                          AppDimens.p2.toInt(),
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

                                    // Title
                                    Text(
                                      'Welcome Back',
                                      style: AmberDuskTokens
                                          .typography
                                          .screenTitle
                                          .copyWith(color: amber.text),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppDimens.p8),

                                    // Subtitle
                                    Text(
                                      'Sign in to continue to SLine',
                                      style: AmberDuskTokens.typography.body
                                          .copyWith(color: amber.muted),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (signupsDisabled) ...[
                                      const SizedBox(height: AppDimens.p12),
                                      Semantics(
                                        liveRegion: true,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: amber.dangerMuted,
                                            borderRadius: BorderRadius.circular(
                                              AmberDuskTokens
                                                  .spacing
                                                  .moduleRadius,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(
                                              AppDimens.p12,
                                            ),
                                            child: Text(
                                              'New account registration is '
                                              'temporarily paused.',
                                              style: AmberDuskTokens
                                                  .typography
                                                  .bodySmall
                                                  .copyWith(
                                                    color: amber.rust,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimens.p32),

                              // --- Email field ---
                              _staggered(
                                slide: _emailSlide,
                                fade: _emailFade,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email',
                                      style: AmberDuskTokens
                                          .widgetTheme
                                          .fields
                                          .labelStyle
                                          .copyWith(color: amber.text),
                                    ),
                                    const SizedBox(height: AppDimens.p8),
                                    AppTextField(
                                      fieldKey: LoginScreen.emailFieldKey,
                                      controller: _emailController,
                                      hintText: 'your@email.com',
                                      keyboardType: TextInputType.emailAddress,
                                      onChanged: _onEmailChanged,
                                      showClearButton: true,
                                      suffixIcon: _buildValidationIcon(
                                        _emailValid,
                                        colorScheme,
                                      ),
                                    ),
                                    _buildInlineError(_emailError, colorScheme),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimens.p16),

                              // --- Password field ---
                              _staggered(
                                slide: _passwordSlide,
                                fade: _passwordFade,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password',
                                      style: AmberDuskTokens
                                          .widgetTheme
                                          .fields
                                          .labelStyle
                                          .copyWith(color: amber.text),
                                    ),
                                    const SizedBox(height: AppDimens.p8),
                                    AppTextField(
                                      fieldKey: LoginScreen.passwordFieldKey,
                                      controller: _passwordController,
                                      hintText: 'Enter your password',
                                      obscureText: true,
                                      showPasswordToggle: true,
                                      onChanged: _onPasswordChanged,
                                    ),
                                    _buildInlineError(
                                      _passwordError,
                                      colorScheme,
                                    ),

                                    // Forgot Password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          AppLogger.i(
                                            'Forgot password tapped from '
                                            'login',
                                            tag: 'Auth',
                                          );
                                          unawaited(
                                            Navigator.push(
                                              context,
                                              SlinePageRoute.forwardPush(
                                                child:
                                                    const ForgotPasswordScreen(),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: AmberDuskTokens
                                              .typography
                                              .control
                                              .copyWith(color: amber.primary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimens.p24),

                              // --- Sign In Button ---
                              _staggered(
                                slide: _signInSlide,
                                fade: _signInFade,
                                child: Consumer<AuthFormViewModel>(
                                  builder: (context, authVM, child) {
                                    return AppButton(
                                      tapTargetKey: LoginScreen.signInButtonKey,
                                      text: 'Sign In',
                                      isLoading: authVM.isLoading,
                                      width: double.infinity,
                                      onPressed: () => _handleLogin(authVM),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppDimens.p24),

                              // --- Sign Up Link ---
                              _staggered(
                                slide: _signUpSlide,
                                fade: _signUpFade,
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: AmberDuskTokens
                                          .typography
                                          .bodySmall
                                          .copyWith(color: amber.muted),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        AppLogger.i(
                                          'Signup link tapped from login',
                                          tag: 'Auth',
                                        );
                                        unawaited(
                                          Navigator.pushNamed(
                                            context,
                                            '/signup',
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDimens.p8,
                                          vertical: AppDimens.p8,
                                        ),
                                        minimumSize: const Size(
                                          AppDimens.touchTarget,
                                          AppDimens.touchTarget,
                                        ),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: AmberDuskTokens
                                            .typography
                                            .control
                                            .copyWith(color: amber.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
