import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/banner.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/text_field.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_session_state.dart';
import '../application/privacy_controller.dart';
import '../domain/privacy_models.dart';
import 'privacy_page.dart';

/// Recent-authentication recovery for a pending privacy mutation.
///
/// Confirmation updates only the provider access token. It never re-runs
/// bootstrap, so the pending request and the current privacy route survive.
class PrivacyReauthScreen extends ConsumerStatefulWidget {
  const PrivacyReauthScreen({super.key});

  @override
  ConsumerState<PrivacyReauthScreen> createState() =>
      _PrivacyReauthScreenState();
}

class _PrivacyReauthScreenState extends ConsumerState<PrivacyReauthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _summaryFocus = FocusNode();

  late final PrivacyController _privacyController;
  late final String? _initialAccessToken;
  late final String? _currentUserId;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _awaitingGoogle = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _privacyController = ref.read(privacyControllerProvider.notifier);
    final session = ref.read(sessionControllerProvider).session;
    _initialAccessToken = session?.accessToken;
    _currentUserId = session?.userId;
    _emailController.text = session?.email ?? '';
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
    var valid = true;

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
        if (mounted) _summaryFocus.requestFocus();
      });
    }

    return valid;
  }

  Future<void> _submitEmailPassword() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _formError = null;
    });

    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .reauthenticateWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      _passwordController.clear();
      await _finishReauthentication();
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _formError = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _formError = 'Unable to confirm your identity. Please try again.';
      });
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isLoading = true;
      _awaitingGoogle = true;
      _formError = null;
    });

    try {
      final config = ref.read(appConfigurationProvider);
      await ref
          .read(sessionControllerProvider.notifier)
          .reauthenticateWithGoogle(redirectUri: config.oauthRedirectUri);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _awaitingGoogle = false;
        _formError = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _awaitingGoogle = false;
        _formError = 'Google confirmation could not be completed.';
      });
    }
  }

  void _handleSessionChanged(AppSessionState? previous, AppSessionState next) {
    if (!_awaitingGoogle) return;

    final session = next.session;
    if (session != null &&
        session.userId == _currentUserId &&
        session.accessToken != _initialAccessToken) {
      _awaitingGoogle = false;
      unawaited(_finishReauthentication());
      return;
    }

    if (next.phase == AppSessionPhase.signedOut) {
      _awaitingGoogle = false;
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _formError =
            next.failure?.message ??
            'Confirmation could not be completed. Please try again.';
      });
    }
  }

  Future<void> _finishReauthentication() async {
    final pendingAction = ref.read(privacyControllerProvider).pendingAction;
    await _privacyController.retryPendingAction();
    if (!mounted) return;

    final state = ref.read(privacyControllerProvider);
    final failure = state.failure;
    if (failure != null) {
      setState(() {
        _isLoading = false;
        _awaitingGoogle = false;
        _formError = failure.message;
      });
      return;
    }

    switch (pendingAction) {
      case PrivacyPendingAction.export:
        final export = state.export;
        if (export != null) {
          context.go(AppRoutes.privacyExportStatusPath(export.id));
          return;
        }
      case PrivacyPendingAction.deletion:
        final deletion = state.deletion;
        if (deletion != null) {
          context.go(AppRoutes.privacyDeletionStatusPath(deletion.id));
          return;
        }
      case PrivacyPendingAction.cancellation:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.privacy);
        }
        return;
      case null:
        break;
    }

    setState(() {
      _isLoading = false;
      _awaitingGoogle = false;
    });
  }

  void _cancel() {
    _privacyController.cancelReauthentication();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.privacy);
    }
  }

  Future<void> _signInAgain() async {
    await ref.read(sessionControllerProvider.notifier).signOut(force: true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppSessionState>(
      sessionControllerProvider,
      _handleSessionChanged,
    );

    final privacyState = ref.watch(privacyControllerProvider);
    final hasPendingAction = privacyState.pendingAction != null;
    // A second recent-auth rejection clears the pending action but must keep a
    // visible recovery path instead of falling back to the empty-state card.
    final signInRecoveryRequired =
        privacyState.failure?.code == 'reauthentication_failed';

    return PrivacyScaffold(
      title: "Confirm it's you",
      onBackPressed: _cancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PrivacySectionHeading('Recent sign-in required'),
          Text(
            'For your security, confirm your credentials before this privacy '
            'action continues. Confirming does not start a new request or '
            'change the request already in progress.',
            style: MemoraTypography.body,
          ),
          const SizedBox(height: MemoraSpacing.space16),
          if (!hasPendingAction && !signInRecoveryRequired) ...<Widget>[
            MemoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'No privacy action is waiting',
                    style: MemoraTypography.cardTitle,
                  ),
                  const SizedBox(height: MemoraSpacing.space8),
                  Text(
                    'Return to Privacy to start an export or deletion request.',
                    style: MemoraTypography.body,
                  ),
                  const SizedBox(height: MemoraSpacing.space16),
                  MemoraButton(
                    key: const Key('privacy_reauth_back'),
                    label: 'Back to Privacy',
                    variant: MemoraButtonVariant.secondary,
                    onPressed: _cancel,
                  ),
                ],
              ),
            ),
          ] else ...<Widget>[
            if (_formError != null) ...<Widget>[
              Focus(
                key: const Key('privacy_reauth_error_summary'),
                focusNode: _summaryFocus,
                includeSemantics: false,
                child: Semantics(
                  container: true,
                  excludeSemantics: true,
                  focusable: true,
                  liveRegion: true,
                  label: _formError,
                  child: MemoraBanner(
                    variant: MemoraBannerVariant.critical,
                    message: _formError!,
                  ),
                ),
              ),
              const SizedBox(height: MemoraSpacing.space8),
            ],
            if (_awaitingGoogle) ...<Widget>[
              const MemoraBanner(
                variant: MemoraBannerVariant.info,
                title: 'Finish in your browser',
                message:
                    'Complete the Google confirmation in your browser, then '
                    'return to Memora. Your privacy request is unchanged while '
                    'you wait.',
              ),
              const SizedBox(height: MemoraSpacing.space8),
            ],
            if (signInRecoveryRequired) ...<Widget>[
              MemoraButton(
                key: const Key('privacy_reauth_sign_in_again'),
                label: 'Sign in again',
                onPressed: _signInAgain,
              ),
              const SizedBox(height: MemoraSpacing.space8),
              MemoraButton(
                key: const Key('privacy_reauth_cancel'),
                label: 'Back to Privacy',
                variant: MemoraButtonVariant.tertiary,
                onPressed: _cancel,
              ),
            ] else
              FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(1),
                      child: MemoraTextField(
                        key: const Key('privacy_reauth_email'),
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
                        key: const Key('privacy_reauth_password'),
                        label: 'Password',
                        hintText: 'Enter your password',
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitEmailPassword(),
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
                    const SizedBox(height: MemoraSpacing.space16),
                    FocusTraversalOrder(
                      order: const NumericFocusOrder(3),
                      child: MemoraButton(
                        key: const Key('privacy_reauth_submit'),
                        label: _isLoading
                            ? 'Confirming...'
                            : 'Confirm and continue',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _submitEmailPassword,
                      ),
                    ),
                    const SizedBox(height: MemoraSpacing.space16),
                    const Row(
                      children: <Widget>[
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: MemoraSpacing.space16,
                          ),
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
                      order: const NumericFocusOrder(4),
                      child: MemoraButton(
                        key: const Key('privacy_reauth_google'),
                        label: 'Continue with Google',
                        variant: MemoraButtonVariant.secondary,
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        onPressed: _isLoading ? null : _submitGoogle,
                      ),
                    ),
                    const SizedBox(height: MemoraSpacing.space8),
                    Text(
                      'Use Continue with Google if you created your account with '
                      'Google and do not have a Memora password.',
                      style: MemoraTypography.metadata,
                    ),
                    const SizedBox(height: MemoraSpacing.space24),
                    MemoraButton(
                      key: const Key('privacy_reauth_cancel'),
                      label: 'Cancel and return to Privacy',
                      variant: MemoraButtonVariant.tertiary,
                      onPressed: _isLoading ? null : _cancel,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
