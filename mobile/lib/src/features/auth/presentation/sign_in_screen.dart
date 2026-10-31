import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/banner.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/mora.dart';
import '../../../design_system/components/text_field.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../application/session_controller.dart';
import '../domain/app_session_state.dart';
import '../../../routing/app_routes.dart';

/// Screen for authenticating an existing student with email/password or Google.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _summaryFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;
  String? _expiryNotice;

  static const String _sessionExpiredMessage =
      'Your session expired. Sign in again to continue.';

  @override
  void initState() {
    super.initState();
    final failure = ref.read(sessionControllerProvider).failure;
    if (failure?.code == 'expired_session') {
      // Read once per mount so unrelated rebuilds never re-announce.
      _expiryNotice = _sessionExpiredMessage;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _summaryFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _formError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool valid = true;

    if (email.isEmpty) {
      _emailError = 'Please enter your email.';
      valid = false;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = 'Please enter a valid email address.';
      valid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter your password.';
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
    if (_expiryNotice != null) {
      setState(() {
        _expiryNotice = null;
      });
    }
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _formError = null;
    });

    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .signInWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Clean password from memory after sign in
      _passwordController.clear();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          _formError = 'Unable to connect to Memora. Please try again.';
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
    final canGoBack = Navigator.of(context).canPop();

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
                if (canGoBack)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                // Top Card with Mora Header
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
                          'Welcome back',
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
                        'A little learning. A little closer.\nPick up where you left off.',
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
                if (_expiryNotice != null) ...[
                  MemoraBanner(
                    key: const Key('session_expired_notice'),
                    message: _expiryNotice!,
                    variant: MemoraBannerVariant.attention,
                  ),
                  const SizedBox(height: MemoraSpacing.space16),
                ],
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
                    label: 'Email',
                    hintText: 'Enter your email',
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    prefixIcon: const Icon(Icons.person_outline),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: MemoraTextField(
                    label: 'Password',
                    hintText: 'Enter your password',
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
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
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.push(AppRoutes.recoverAccount),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontFamily: 'Exo',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0072B2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: MemoraButton(
                    label: _isLoading ? 'Signing in...' : 'Log in',
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
                  order: const NumericFocusOrder(5),
                  child: MemoraButton(
                    label: 'Continue with Google',
                    variant: MemoraButtonVariant.secondary,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    onPressed: _isLoading ? null : _submitGoogle,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space24),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(6),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'New to Memora? ',
                        style: TextStyle(color: MemoraColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.push(AppRoutes.createAccount),
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
                        child: const Text('Create an account'),
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
