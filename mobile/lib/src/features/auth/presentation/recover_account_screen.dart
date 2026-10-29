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
import '../../../routing/app_routes.dart';

/// Password recovery screen providing safe confirmation without leaking account existence.
class RecoverAccountScreen extends ConsumerStatefulWidget {
  const RecoverAccountScreen({super.key});

  @override
  ConsumerState<RecoverAccountScreen> createState() =>
      _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends ConsumerState<RecoverAccountScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  bool _isLoading = false;
  bool _submitted = false;
  String? _emailError;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = null;
      _formError = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailError = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .sendPasswordRecoveryEmail(email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _submitted = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _formError = 'Unable to send recovery email. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MemoraColors.textPrimary),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space24,
            vertical: MemoraSpacing.space16,
          ),
          child: _submitted ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MoraPlacement(
          state: MoraState.think,
          size: 100,
          isDecorative: true,
        ),
        const SizedBox(height: MemoraSpacing.space24),
        Semantics(
          header: true,
          child: const Text(
            'Recover your account',
            textAlign: TextAlign.center,
            style: MemoraTypography.pageTitle,
          ),
        ),
        const SizedBox(height: MemoraSpacing.space8),
        const Text(
          'Enter the email associated with your account to receive recovery instructions.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: MemoraColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: MemoraSpacing.space24),
        if (_formError != null) ...[
          MemoraBanner(
            message: _formError!,
            variant: MemoraBannerVariant.critical,
          ),
          const SizedBox(height: MemoraSpacing.space16),
        ],
        MemoraTextField(
          label: 'Email address',
          hintText: 'Enter your email',
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: _emailError,
          prefixIcon: const Icon(Icons.email_outlined),
          enabled: !_isLoading,
        ),
        const SizedBox(height: MemoraSpacing.space24),
        MemoraButton(
          label: _isLoading ? 'Sending...' : 'Send Recovery Link',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MemoraSpacing.space32),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: MemoraColors.feedbackPositive,
        ),
        const SizedBox(height: MemoraSpacing.space24),
        Semantics(
          header: true,
          child: const Text(
            'Recovery link sent',
            textAlign: TextAlign.center,
            style: MemoraTypography.pageTitle,
          ),
        ),
        const SizedBox(height: MemoraSpacing.space16),
        const Text(
          'If an account with that email address exists, we have sent instructions to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: MemoraColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: MemoraSpacing.space32),
        MemoraButton(
          label: 'Return to Sign In',
          onPressed: () => context.go(AppRoutes.signIn),
        ),
      ],
    );
  }
}
