import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/banner.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../../auth/application/session_controller.dart';
import '../application/consent_controller.dart';
import '../domain/consent_policy.dart';
import '../domain/consent_state.dart';

/// Authenticated consent review destination.
///
/// Shows only policies that currently require action, the server-returned
/// policy names and versions, and one explicit acceptance checkbox per policy.
/// It never invents policy text, links or legal claims.
class ConsentReviewScreen extends ConsumerStatefulWidget {
  const ConsentReviewScreen({super.key});

  @override
  ConsumerState<ConsentReviewScreen> createState() =>
      _ConsentReviewScreenState();
}

class _ConsentReviewScreenState extends ConsumerState<ConsentReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(consentControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consentControllerProvider);

    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: MemoraColors.surfaceSoft,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Consent'),
        actions: <Widget>[
          TextButton(onPressed: _signOut, child: const Text('Sign out')),
        ],
      ),
      body: SafeArea(child: _buildBody(state)),
    );
  }

  Widget _buildBody(ConsentState state) {
    switch (state.phase) {
      case ConsentPhase.initial:
      case ConsentPhase.loading:
        return const _ConsentLoading();
      case ConsentPhase.submitting:
        return const _ConsentLoading(message: 'Saving your choices…');
      case ConsentPhase.error:
        return _ConsentPanel(
          title: 'We could not load your consent choices',
          message:
              state.errorMessage ??
              'Check your connection and try again to continue.',
          primaryLabel: 'Retry',
          onPrimary: () => ref.read(consentControllerProvider.notifier).load(),
          onSignOut: _signOut,
        );
      case ConsentPhase.blocked:
        return _ConsentPanel(
          title: 'Consent needs attention',
          message:
              'A required policy is not supported by this version of Memora. '
              'Update the app or contact support to continue.',
          primaryLabel: 'Retry',
          onPrimary: () => ref.read(consentControllerProvider.notifier).load(),
          onSignOut: _signOut,
        );
      case ConsentPhase.completed:
        return _ConsentPanel(
          title: 'Consent recorded',
          message: 'Your choices have been saved. You can continue to Memora.',
          primaryLabel: 'Continue to Home',
          onPrimary: () => context.go(AppRoutes.home),
        );
      case ConsentPhase.ready:
        return _buildReady(state);
    }
  }

  Widget _buildReady(ConsentState state) {
    final required = state.requiredPolicies;
    final canContinue = required.isEmpty || state.canSubmit;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space24,
        vertical: MemoraSpacing.space24,
      ),
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            required.isEmpty ? 'No policies need review' : 'Review and accept',
            style: MemoraTypography.pageTitle,
          ),
        ),
        const SizedBox(height: MemoraSpacing.space12),
        Text(
          required.isEmpty
              ? 'Every required policy is current for this account.'
              : 'Each policy below currently requires your acceptance. '
                    'The name and version shown are the exact policy you are accepting.',
          style: MemoraTypography.body.copyWith(
            color: MemoraColors.textSecondary,
          ),
        ),
        if (state.notice != null) ...<Widget>[
          const SizedBox(height: MemoraSpacing.space8),
          MemoraBanner(
            key: const Key('consent_notice'),
            message: state.notice!,
            variant: MemoraBannerVariant.attention,
          ),
        ],
        const SizedBox(height: MemoraSpacing.space16),
        for (final policy in required) _buildPolicy(policy),
        const SizedBox(height: MemoraSpacing.space24),
        MemoraButton(
          label: required.isEmpty ? 'Continue to Home' : 'Continue',
          onPressed: canContinue ? _continue : null,
        ),
      ],
    );
  }

  Widget _buildPolicy(ConsentPolicy policy) {
    return CheckboxListTile(
      key: Key('consent_checkbox_${policy.wireId}'),
      value: ref.watch(consentControllerProvider).isSelected(policy.wireId),
      onChanged: policy.isKnown
          ? (_) => ref
                .read(consentControllerProvider.notifier)
                .toggle(policy.wireId)
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        policy.checkboxLabel,
        style: MemoraTypography.body.copyWith(color: MemoraColors.textPrimary),
      ),
    );
  }

  Future<void> _continue() async {
    await ref.read(consentControllerProvider.notifier).submit();
    if (!mounted) return;

    final state = ref.read(consentControllerProvider);
    if (state.phase != ConsentPhase.completed) return;

    final sessionController = ref.read(sessionControllerProvider.notifier);
    final target = sessionController.consumeSafeReturnLocation();
    if (!mounted) return;

    final path = target == null || target.path == AppRoutes.consent
        ? AppRoutes.home
        : target.path;
    context.go(path);
  }

  Future<void> _signOut() async {
    await ref.read(sessionControllerProvider.notifier).signOut(force: true);
  }
}

class _ConsentLoading extends StatelessWidget {
  const _ConsentLoading({this.message = 'Loading your consent choices…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MemoraSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!reduceMotion) ...<Widget>[
              const CircularProgressIndicator(
                semanticsLabel: 'Loading consent choices',
              ),
              const SizedBox(height: MemoraSpacing.space16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: MemoraTypography.body.copyWith(
                color: MemoraColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentPanel extends StatelessWidget {
  const _ConsentPanel({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.onSignOut,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: MemoraSpacing.space24,
          vertical: MemoraSpacing.space32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: MemoraTypography.pageTitle,
              ),
            ),
            const SizedBox(height: MemoraSpacing.space16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: MemoraTypography.body.copyWith(
                color: MemoraColors.textSecondary,
              ),
            ),
            const SizedBox(height: MemoraSpacing.space32),
            MemoraButton(label: primaryLabel, onPressed: onPrimary),
            if (onSignOut != null) ...<Widget>[
              const SizedBox(height: MemoraSpacing.space12),
              MemoraButton(
                label: 'Sign out',
                variant: MemoraButtonVariant.secondary,
                onPressed: onSignOut,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
