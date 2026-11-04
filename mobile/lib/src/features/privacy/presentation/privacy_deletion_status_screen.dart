import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/banner.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/dialog.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../../auth/application/session_controller.dart';
import '../application/privacy_controller.dart';
import '../domain/privacy_models.dart';
import 'privacy_page.dart';

/// Authoritative deletion status destination.
///
/// Completion is only announced when the server returns `completed` together
/// with verification proofs. An expired session while checking deletion is
/// reported as unconfirmed and never clears the local session or claims success.
class PrivacyDeletionStatusScreen extends ConsumerStatefulWidget {
  const PrivacyDeletionStatusScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<PrivacyDeletionStatusScreen> createState() =>
      _PrivacyDeletionStatusScreenState();
}

class _PrivacyDeletionStatusScreenState
    extends ConsumerState<PrivacyDeletionStatusScreen> {
  late final PrivacyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(privacyControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.loadDeletion(widget.requestId);
    });
  }

  @override
  void dispose() {
    _controller.stopPolling();
    super.dispose();
  }

  Future<void> _cancelDeletion() async {
    final cancelled = await _controller.cancelDeletion();
    if (!mounted || cancelled == null) return;
    // The server-confirmed cancellation is rendered from the new status.
  }

  void _showCancelDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return MemoraDialog(
          title: 'Cancel account deletion?',
          message:
              'Your account will remain active and the scheduled deletion will '
              'stop. This does not delete any data.',
          primaryActionLabel: 'Cancel deletion',
          onPrimaryAction: () {
            Navigator.of(dialogContext).pop();
            unawaited(_cancelDeletion());
          },
          secondaryActionLabel: 'Keep deletion request',
          onSecondaryAction: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  void _signOut() {
    ref.read(sessionControllerProvider.notifier).signOut(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privacyControllerProvider);
    final loadedDeletion = state.deletion?.id == widget.requestId
        ? state.deletion
        : null;

    return PrivacyScaffold(
      title: 'Deletion status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrivacyBanners(
            state: state,
            onRetry: () => _controller.loadDeletion(widget.requestId),
            onReauthenticate: () => context.go(AppRoutes.privacyReauth),
            onDismissFailure: _controller.clearFailure,
            onDismissNotice: _controller.clearNotice,
            onSignOut: _signOut,
          ),
          const SizedBox(height: MemoraSpacing.space8),
          if (state.outcomeUnconfirmed)
            _UnconfirmedCard(
              requestId: state.outcomeUnconfirmedRequestId ?? widget.requestId,
              onSignOut: _signOut,
            )
          else if (state.isLoading && loadedDeletion == null)
            const _DeletionLoadingCard()
          else if (loadedDeletion == null)
            _DeletionLoadFailureCard(
              onRetry: () => _controller.loadDeletion(widget.requestId),
            )
          else
            _DeletionStatusSection(
              deletion: loadedDeletion,
              state: state,
              onRefresh: () => _controller.loadDeletion(widget.requestId),
              onCancel: _showCancelDialog,
              onSignIn: () => context.go(AppRoutes.signIn),
              onBackToPrivacy: () => context.go(AppRoutes.privacy),
              onRequestNew: () => context.go(AppRoutes.privacyDelete),
            ),
        ],
      ),
    );
  }
}

class _DeletionStatusSection extends StatelessWidget {
  const _DeletionStatusSection({
    required this.deletion,
    required this.state,
    required this.onRefresh,
    required this.onCancel,
    required this.onSignIn,
    required this.onBackToPrivacy,
    required this.onRequestNew,
  });

  final PrivacyDeletion deletion;
  final PrivacyState state;
  final VoidCallback onRefresh;
  final VoidCallback onCancel;
  final VoidCallback onSignIn;
  final VoidCallback onBackToPrivacy;
  final VoidCallback onRequestNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PrivacyStatusCard(
          title: 'Deletion request',
          status: deletion.status,
          requestedAt: deletion.requestedAt,
          completedAt: deletion.completedAt,
          child: _buildStatusBody(context),
        ),
        const SizedBox(height: MemoraSpacing.space8),
        Text('Request ID: ${deletion.id}', style: MemoraTypography.metadata),
        const SizedBox(height: MemoraSpacing.space16),
        if (deletion.status.isPending) ...<Widget>[
          MemoraButton(
            key: const Key('privacy_delete_refresh'),
            label: 'Refresh status',
            variant: MemoraButtonVariant.secondary,
            isLoading: state.isRefreshing,
            onPressed: state.isRefreshing ? null : onRefresh,
          ),
        ],
        if (deletion.status == PrivacyRequestStatus.completed &&
            !deletion.isConfirmedComplete) ...<Widget>[
          MemoraButton(
            key: const Key('privacy_delete_refresh'),
            label: 'Check again',
            variant: MemoraButtonVariant.secondary,
            isLoading: state.isRefreshing,
            onPressed: state.isRefreshing ? null : onRefresh,
          ),
        ],
        if (deletion.status == PrivacyRequestStatus.unknown) ...<Widget>[
          MemoraButton(
            key: const Key('privacy_delete_refresh'),
            label: 'Check again',
            variant: MemoraButtonVariant.secondary,
            isLoading: state.isRefreshing,
            onPressed: state.isRefreshing ? null : onRefresh,
          ),
        ],
        if (deletion.status == PrivacyRequestStatus.failed) ...<Widget>[
          MemoraButton(
            key: const Key('privacy_delete_request_new'),
            label: 'Start a new deletion request',
            onPressed: onRequestNew,
          ),
        ],
        if (deletion.status == PrivacyRequestStatus.cancelled) ...<Widget>[
          MemoraButton(
            key: const Key('privacy_delete_back'),
            label: 'Back to Privacy',
            variant: MemoraButtonVariant.secondary,
            onPressed: onBackToPrivacy,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBody(BuildContext context) {
    switch (deletion.status) {
      case PrivacyRequestStatus.requested:
      case PrivacyRequestStatus.verifying:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Your deletion request is waiting for verification. You can leave '
              'this screen safely; Memora keeps checking while it is open.',
              style: MemoraTypography.body,
            ),
            if (deletion.canCancel) ...<Widget>[
              const SizedBox(height: MemoraSpacing.space16),
              Text(
                'You can still cancel while the request is requested or '
                'verifying.',
                style: MemoraTypography.metadata,
              ),
              const SizedBox(height: MemoraSpacing.space8),
              MemoraButton(
                key: const Key('privacy_delete_cancel'),
                label: 'Cancel deletion',
                variant: MemoraButtonVariant.secondary,
                isLoading: state.isSubmitting,
                onPressed: state.isSubmitting ? null : onCancel,
              ),
            ],
            const SizedBox(height: MemoraSpacing.space12),
            const LinearProgressIndicator(
              minHeight: 6,
              semanticsLabel: 'Deletion request pending',
            ),
          ],
        );
      case PrivacyRequestStatus.processing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Deletion is processing. Cancellation is no longer available. '
              'Memora will show the server-confirmed outcome when it is '
              'available.',
              style: MemoraTypography.body,
            ),
            const SizedBox(height: MemoraSpacing.space12),
            const LinearProgressIndicator(
              minHeight: 6,
              semanticsLabel: 'Deletion processing',
            ),
          ],
        );
      case PrivacyRequestStatus.completed:
        if (!deletion.isConfirmedComplete) {
          return Text(
            'The server reported completion but did not return verification '
            'details. Do not assume your data has been deleted. Check again or '
            'contact support with the request ID below.',
            style: MemoraTypography.body,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const MemoraBanner(
              variant: MemoraBannerVariant.positive,
              title: 'Deletion verified',
              message:
                  'The server confirmed the deletion and returned verification '
                  'details for the scopes below.',
            ),
            const SizedBox(height: MemoraSpacing.space16),
            Text('Verified scopes', style: MemoraTypography.cardTitle),
            const SizedBox(height: MemoraSpacing.space8),
            for (final proof in deletion.proofs) _ProofRow(proof: proof),
            const SizedBox(height: MemoraSpacing.space16),
            Text('Retention exceptions', style: MemoraTypography.cardTitle),
            const SizedBox(height: MemoraSpacing.space8),
            if (deletion.retentionExceptions.isEmpty)
              Text(
                'No retention exceptions were reported by the server.',
                style: MemoraTypography.metadata,
              )
            else
              for (final exception in deletion.retentionExceptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: MemoraSpacing.space8),
                  child: Text('• $exception', style: MemoraTypography.metadata),
                ),
            const SizedBox(height: MemoraSpacing.space16),
            MemoraButton(
              key: const Key('privacy_delete_sign_in'),
              label: 'Return to sign in',
              variant: MemoraButtonVariant.secondary,
              onPressed: onSignIn,
            ),
          ],
        );
      case PrivacyRequestStatus.failed:
        return Text(
          'The deletion could not be completed. Your last known account state '
          'is unchanged by this screen. Contact support with request '
          '${deletion.id} or start a new deletion request.',
          style: MemoraTypography.body,
        );
      case PrivacyRequestStatus.cancelled:
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MemoraBanner(
              variant: MemoraBannerVariant.positive,
              title: 'Deletion cancelled',
              message:
                  'The server confirmed the cancellation. Your account remains '
                  'active and no data was deleted by this request.',
            ),
          ],
        );
      case PrivacyRequestStatus.unknown:
        return Text(
          'Memora received a status it does not recognise. Check again later. '
          'This screen never treats an unknown status as complete or failed.',
          style: MemoraTypography.body,
        );
    }
  }
}

class _ProofRow extends StatelessWidget {
  const _ProofRow({required this.proof});

  final DeletionProof proof;

  @override
  Widget build(BuildContext context) {
    final verifiedAt = proof.verifiedAt;
    return Container(
      margin: const EdgeInsets.only(bottom: MemoraSpacing.space8),
      padding: const EdgeInsets.all(MemoraSpacing.space12),
      decoration: BoxDecoration(
        color: MemoraColors.surfaceSoft,
        borderRadius: BorderRadius.circular(MemoraSpacing.space8),
        border: Border.all(color: MemoraColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(proof.scope, style: MemoraTypography.cardTitle),
          const SizedBox(height: MemoraSpacing.space4),
          Text(
            '${proof.provider} · ${proof.result}',
            style: MemoraTypography.metadata,
          ),
          if (verifiedAt != null) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space4),
            Text(
              'Verified ${formatPrivacyTimestamp(verifiedAt)}',
              style: MemoraTypography.metadata,
            ),
          ],
        ],
      ),
    );
  }
}

class _DeletionLoadingCard extends StatelessWidget {
  const _DeletionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const MemoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Loading deletion status', style: MemoraTypography.cardTitle),
          SizedBox(height: MemoraSpacing.space12),
          LinearProgressIndicator(
            minHeight: 6,
            semanticsLabel: 'Loading deletion status',
          ),
        ],
      ),
    );
  }
}

class _DeletionLoadFailureCard extends StatelessWidget {
  const _DeletionLoadFailureCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MemoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Deletion status could not be loaded',
            style: MemoraTypography.cardTitle,
          ),
          const SizedBox(height: MemoraSpacing.space8),
          Text(
            'Memora could not read this request. Check your connection and try '
            'again. No deletion outcome is assumed.',
            style: MemoraTypography.body,
          ),
          const SizedBox(height: MemoraSpacing.space16),
          MemoraButton(
            key: const Key('privacy_delete_retry_load'),
            label: 'Try again',
            variant: MemoraButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _UnconfirmedCard extends StatelessWidget {
  const _UnconfirmedCard({required this.requestId, required this.onSignOut});

  final String requestId;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return MemoraCard(
      borderColor: MemoraColors.feedbackCritical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Deletion status unconfirmed',
            style: MemoraTypography.cardTitle.copyWith(
              color: MemoraColors.feedbackCritical,
            ),
          ),
          const SizedBox(height: MemoraSpacing.space8),
          Text(
            'Memora could not confirm deletion request $requestId. Sign in '
            'again with the same account to check it. Do not assume your data '
            'has been deleted.',
            style: MemoraTypography.body,
          ),
          const SizedBox(height: MemoraSpacing.space16),
          MemoraButton(
            key: const Key('privacy_delete_outcome_sign_out'),
            label: 'Sign out',
            variant: MemoraButtonVariant.destructive,
            icon: const Icon(Icons.logout),
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
