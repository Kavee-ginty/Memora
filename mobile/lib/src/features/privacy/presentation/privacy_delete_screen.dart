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
import '../../auth/domain/bootstrap_state.dart';
import '../application/privacy_controller.dart';
import 'privacy_page.dart';

/// Deletion explanation and explicit confirmation destination.
///
/// The screen never claims that data is deleted. It only starts the server
/// workflow and routes to the authoritative status screen.
class PrivacyDeleteScreen extends ConsumerStatefulWidget {
  const PrivacyDeleteScreen({super.key});

  @override
  ConsumerState<PrivacyDeleteScreen> createState() =>
      _PrivacyDeleteScreenState();
}

class _PrivacyDeleteScreenState extends ConsumerState<PrivacyDeleteScreen> {
  late final PrivacyController _controller;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(privacyControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.checkReachability();
    });
  }

  Future<void> _submit() async {
    final deletion = await _controller.requestDeletion(confirmed: true);
    if (!mounted || deletion == null) return;

    final sessionController = ref.read(sessionControllerProvider.notifier);
    // Navigate before projecting deletion-pending locally so the status route
    // is already the current destination when the guard re-evaluates.
    context.go(AppRoutes.privacyDeletionStatusPath(deletion.id));
    sessionController.markDeletionPending(
      deletion.id,
      status: deletion.status.name,
    );
  }

  void _showConfirmationDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return MemoraDialog(
          title: 'Delete your account?',
          message:
              'This starts a verified deletion of your account and learning '
              'data. You can cancel while the request is requested or '
              'verifying. After processing begins, it cannot be undone.',
          isDestructive: true,
          primaryActionLabel: 'Delete account',
          onPrimaryAction: () {
            Navigator.of(dialogContext).pop();
            unawaited(_submit());
          },
          secondaryActionLabel: 'Cancel',
          onSecondaryAction: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privacyControllerProvider);
    final sessionState = ref.watch(sessionControllerProvider);
    final pending =
        sessionState.bootstrapData?.pendingPrivacyRequests ??
        const <PendingResourceSummaryDomain>[];
    final pendingDeletion = state.deletion?.status.isPending == true;
    final canSubmit =
        _confirmed &&
        state.canMutate &&
        !state.isSubmitting &&
        !pendingDeletion;

    return PrivacyScaffold(
      title: 'Delete your account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrivacyBanners(
            state: state,
            onRetry: _controller.checkReachability,
            onReauthenticate: () => context.push(AppRoutes.privacyReauth),
            onDismissFailure: _controller.clearFailure,
            onDismissNotice: _controller.clearNotice,
            onSignOut: () {
              ref.read(sessionControllerProvider.notifier).signOut(force: true);
            },
          ),
          const SizedBox(height: MemoraSpacing.space8),
          if (pendingDeletion) ...<Widget>[
            PrivacyStatusCard(
              title: 'Deletion request',
              status: state.deletion!.status,
              requestedAt: state.deletion!.requestedAt,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'A deletion request is already in progress. Check its '
                    'status before starting another request.',
                    style: MemoraTypography.body,
                  ),
                  const SizedBox(height: MemoraSpacing.space16),
                  MemoraButton(
                    key: const Key('privacy_delete_view_status'),
                    label: 'View deletion status',
                    variant: MemoraButtonVariant.secondary,
                    onPressed: () => context.go(
                      AppRoutes.privacyDeletionStatusPath(state.deletion!.id),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MemoraSpacing.space16),
          ] else if (pending.isNotEmpty) ...<Widget>[
            MemoraBanner(
              variant: MemoraBannerVariant.attention,
              title: 'Another privacy request is in progress',
              message:
                  'Request ${pending.first.id} is still ${pending.first.status}. '
                  'Check its status before starting a deletion request.',
              actionLabel: 'View privacy requests',
              onAction: () => context.go(AppRoutes.privacy),
            ),
            const SizedBox(height: MemoraSpacing.space16),
          ],
          const PrivacySectionHeading('What deletion means'),
          Text(
            'Deleting your account removes your Memora identity and learning '
            'data. This is different from signing out and cannot be undone once '
            'processing begins.',
            style: MemoraTypography.body,
          ),
          const SizedBox(height: MemoraSpacing.space16),
          const _DeletionBullet(
            text:
                'Your profile, learning materials, notes, missions and '
                'progress are deleted.',
          ),
          const _DeletionBullet(
            text:
                'You can cancel only while the request is requested or '
                'verifying.',
          ),
          const _DeletionBullet(
            text: 'Once processing begins, the deletion cannot be cancelled.',
          ),
          const _DeletionBullet(
            text:
                'Some records may be retained where the law requires it. Any '
                'retention exceptions are shown after deletion.',
          ),
          const SizedBox(height: MemoraSpacing.space24),
          MemoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CheckboxListTile(
                  key: const Key('privacy_delete_confirm_checkbox'),
                  value: _confirmed,
                  onChanged: state.isSubmitting || pendingDeletion
                      ? null
                      : (value) {
                          setState(() => _confirmed = value ?? false);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: MemoraColors.brandPrimary,
                  title: Text(
                    'I understand that my account and learning data will be '
                    'permanently deleted and that deletion cannot be undone '
                    'once processing begins.',
                    style: MemoraTypography.body,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space16),
                MemoraButton(
                  key: const Key('privacy_delete_submit'),
                  label: 'Delete my account',
                  variant: MemoraButtonVariant.destructive,
                  icon: const Icon(Icons.delete_outline),
                  isLoading: state.isSubmitting,
                  onPressed: canSubmit ? _showConfirmationDialog : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: MemoraSpacing.space16),
          const MemoraBanner(
            variant: MemoraBannerVariant.info,
            message:
                'Deletion requires a recent sign-in. If your recent sign-in has '
                'expired, Memora asks you to confirm your credentials before '
                'the request is sent.',
          ),
        ],
      ),
    );
  }
}

class _DeletionBullet extends StatelessWidget {
  const _DeletionBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MemoraSpacing.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: MemoraSpacing.space4),
            child: Icon(
              Icons.info_outline,
              size: 18,
              color: MemoraColors.textSecondary,
            ),
          ),
          const SizedBox(width: MemoraSpacing.space8),
          Expanded(child: Text(text, style: MemoraTypography.metadata)),
        ],
      ),
    );
  }
}
