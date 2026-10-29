import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/banner.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/mora.dart';
import '../../../design_system/components/text_field.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../application/session_controller.dart';
import '../domain/app_session_state.dart';
import '../../../routing/app_routes.dart';

/// Screen for registering a new student account with visible password rules.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _summaryFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _emailVerificationPending = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _summaryFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _formError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    bool valid = true;

    if (name.isEmpty) {
      _nameError = 'Please enter your full name.';
      valid = false;
    }

    if (email.isEmpty) {
      _emailError = 'Please enter your email.';
      valid = false;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = 'Please enter a valid email address.';
      valid = false;
    }

    if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters long.';
      valid = false;
    }

    if (confirm != password) {
      _confirmPasswordError = 'Passwords do not match.';
      valid = false;
    }

    if (!valid) {
      setState(() {
        _formError = 'Please check the highlighted fields below.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _summaryFocus.requestFocus();
        }
      });
    }

    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _formError = null;
    });

    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .createAccount(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on AuthFailure catch (e) {
      if (e.code == 'unconfirmed_email') {
        if (mounted) {
          setState(() {
            _emailVerificationPending = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _formError = e.message;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _formError =
              'Account creation could not be completed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isLoading = true;
      _formError = null;
    });

    try {
      final config = ref.read(appConfigurationProvider);
      await ref
          .read(sessionControllerProvider.notifier)
          .signInWithGoogle(redirectUri: config.oauthRedirectUri);
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() {
          _formError = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _formError = 'Google sign-in could not be completed.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailVerificationPending) {
      return Scaffold(
        backgroundColor: MemoraColors.surfaceSoft,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MemoraSpacing.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MoraPlacement(
                  state: MoraState.guide,
                  size: 110,
                  isDecorative: true,
                ),
                const SizedBox(height: MemoraSpacing.space24),
                Semantics(
                  header: true,
                  child: const Text(
                    'Check your email',
                    textAlign: TextAlign.center,
                    style: MemoraTypography.pageTitle,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                Text(
                  'We sent a verification link to ${_emailController.text.trim()}.\nPlease confirm your email to sign in.',
                  textAlign: TextAlign.center,
                  style: MemoraTypography.body,
                ),
                const SizedBox(height: MemoraSpacing.space32),
                MemoraButton(
                  label: 'Proceed to Sign In',
                  onPressed: () => context.go(AppRoutes.signIn),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space24,
            vertical: MemoraSpacing.space16,
          ),
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Card with Mora
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraSpacing.space24,
                    vertical: MemoraSpacing.space24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F1FC),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const MoraPlacement(
                        state: MoraState.guide,
                        size: 110.0,
                        isDecorative: true,
                      ),
                      const SizedBox(height: MemoraSpacing.space8),
                      const Text(
                        'Memora',
                        style: TextStyle(
                          fontFamily: 'Exo',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: MemoraSpacing.space8),
                      Semantics(
                        header: true,
                        child: const Text(
                          'Welcome to Memora',
                          style: TextStyle(
                            fontFamily: 'Exo',
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            color: Color(0xFF102A43),
                          ),
                        ),
                      ),
                      const SizedBox(height: MemoraSpacing.space8),
                      const Text(
                        'Create your student account to build your personalized learning path.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF486581),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space24),
                if (_formError != null) ...[
                  Focus(
                    key: const Key('validation_summary'),
                    focusNode: _summaryFocus,
                    includeSemantics: false,
                    child: Semantics(
                      container: true,
                      excludeSemantics: true,
                      focusable: true,
                      liveRegion: true,
                      label: _formError,
                      child: MemoraBanner(
                        message: _formError!,
                        variant: MemoraBannerVariant.critical,
                      ),
                    ),
                  ),
                  const SizedBox(height: MemoraSpacing.space16),
                ],
                // Form Fields
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: MemoraTextField(
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    controller: _nameController,
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    errorText: _nameError,
                    prefixIcon: const Icon(Icons.person_outline),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: MemoraTextField(
                    label: 'Email',
                    hintText: 'Enter your email',
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    prefixIcon: const Icon(Icons.email_outlined),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: MemoraTextField(
                    label: 'Password',
                    hintText: 'Enter your password',
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    errorText: _passwordError,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: Semantics(
                      toggled: !_obscurePassword,
                      label: 'Password visibility',
                      value: _obscurePassword ? 'Hidden' : 'Visible',
                      child: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space8),
                // Visible password requirement before submission (UI/UX 9.6)
                Row(
                  children: [
                    Icon(
                      _passwordController.text.length >= 8
                          ? Icons.check_circle
                          : Icons.info_outline,
                      size: 16,
                      color: _passwordController.text.length >= 8
                          ? MemoraColors.feedbackPositive
                          : MemoraColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Must be at least 8 characters long',
                        style: TextStyle(
                          fontSize: 12,
                          color: MemoraColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MemoraSpacing.space16),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: MemoraTextField(
                    label: 'Re-enter Password',
                    hintText: 'Re-enter your password',
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    errorText: _confirmPasswordError,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: Semantics(
                      toggled: !_obscureConfirmPassword,
                      label: 'Password visibility',
                      value: _obscureConfirmPassword ? 'Hidden' : 'Visible',
                      child: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: _obscureConfirmPassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space24),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(5),
                  child: MemoraButton(
                    label: _isLoading
                        ? 'Creating account...'
                        : 'Create Account',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: MemoraColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: MemoraSpacing.space16),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(6),
                  child: MemoraButton(
                    label: 'Continue with Google',
                    variant: MemoraButtonVariant.secondary,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    onPressed: _isLoading ? null : _submitGoogle,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space24),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(7),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: MemoraColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.go(AppRoutes.signIn),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(
                            MemoraSpacing.minTouchTarget,
                            MemoraSpacing.minTouchTarget,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: MemoraSpacing.space4,
                          ),
                          foregroundColor: const Color(0xFF0072B2),
                          textStyle: const TextStyle(
                            fontFamily: 'Exo',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
