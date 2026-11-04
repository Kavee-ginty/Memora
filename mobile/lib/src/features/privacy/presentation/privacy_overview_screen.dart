import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/button.dart';
import '../../../design_system/components/banner.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/bootstrap_state.dart';
import '../application/privacy_controller.dart';
import 'privacy_page.dart';

/// Privacy hub reached from Profile.
///
/// The hub explains the two approved workflows and never invents request state.
/// A bootstrap pending summary is resolved by reading the export endpoint first
/// and the deletion endpoint second, because T20 omits the request type.
class PrivacyOverviewScreen extends ConsumerStatefulWidget {
  const PrivacyOverviewScreen({super.key});

  @override
  ConsumerState<PrivacyOverviewScreen> createState() =>
      _PrivacyOverviewScreenState();
}

class _PrivacyOverviewScreenState extends ConsumerState<PrivacyOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(privacyControllerProvider.notifier).initializeOverview();
    });
  }

  Future<void> _openPendingRequest(PendingResourceSummaryDomain pending) async {
    final controller = ref.read(privacyControllerProvider.notifier);
    final workflow = await controller.recoverPendingRequest(pending.id);
    if (!mounted) return;

    if (workflow == PrivacyWorkflow.export) {
      context.go(AppRoutes.privacyExportStatusPath(pending.id));
    } else if (workflow == PrivacyWorkflow.deletion) {
      context.go(AppRoutes.privacyDeletionStatusPath(pending.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privacyControllerProvider);
    final controller = ref.read(privacyControllerProvider.notifier);
    final sessionState = ref.watch(sessionControllerProvider);
    final pending =
        sessionState.bootstrapData?.pendingPrivacyRequests ??
        const <PendingResourceSummaryDomain>[];

    return PrivacyScaffold(
      title: 'Privacy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrivacyBanners(
            state: state,
            onRetry: controller.checkReachability,
            onReauthenticate: () => context.go(AppRoutes.privacyReauth),
            onDismissFailure: controller.clearFailure,
            onDismissNotice: controller.clearNotice,
            onSignOut: () {
              ref.read(sessionControllerProvider.notifier).signOut(force: true);
            },
          ),
          const SizedBox(height: MemoraSpacing.space8),
          const PrivacySectionHeading('Your data, your choice'),
          Text(
            'Request a copy of your Memora data or permanently delete your '
            'account. Both actions require you to confirm your identity first.',
            style: MemoraTypography.body,
          ),
          const SizedBox(height: MemoraSpacing.space24),
          if (pending.isNotEmpty) ...<Widget>[
            _PendingRequestCard(
              pending: pending.first,
              isBusy: state.isLoading,
              onOpen: () => _openPendingRequest(pending.first),
            ),
            const SizedBox(height: MemoraSpacing.space16),
          ],
          _PrivacyActionCard(
            icon: Icons.download_outlined,
            title: 'Export your data',
            description:
                'Get a temporary download of your profile, learning '
                'materials, notes, missions and progress. The link opens in '
                'your browser and expires after a short period.',
            action: MemoraButton(
              key: const Key('privacy_overview_export'),
              label: 'Export my data',
              icon: const Icon(Icons.download_outlined),
              onPressed: () => context.go(AppRoutes.privacyExport),
            ),
          ),
          const SizedBox(height: MemoraSpacing.space16),
          _PrivacyActionCard(
            icon: Icons.delete_outline,
            title: 'Delete your account',
            description:
                'Start a verified deletion of your account and learning data. '
                'You can review what is removed and what may be retained before '
                'you confirm.',
            action: MemoraButton(
              key: const Key('privacy_overview_delete'),
              label: 'Review deletion',
              variant: MemoraButtonVariant.secondary,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => context.go(AppRoutes.privacyDelete),
            ),
          ),
          const SizedBox(height: MemoraSpacing.space24),
          const MemoraBanner(
            variant: MemoraBannerVariant.info,
            title: 'Recent sign-in required',
            message:
                'For your security, Memora asks you to confirm your credentials '
                'when your recent sign-in has expired. You can cancel before '
                'any privacy request is sent.',
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.pending,
    required this.isBusy,
    required this.onOpen,
  });

  final PendingResourceSummaryDomain pending;
  final bool isBusy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return MemoraCard(
      borderColor: MemoraColors.brandPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Privacy request in progress',
            style: MemoraTypography.cardTitle,
          ),
          const SizedBox(height: MemoraSpacing.space8),
          Text(
            'Request ${pending.id} is still ${pending.status}. Open it to see '
            'the latest server-reported status.',
            style: MemoraTypography.metadata,
          ),
          const SizedBox(height: MemoraSpacing.space16),
          MemoraButton(
            key: const Key('privacy_overview_pending_status'),
            label: 'View request status',
            variant: MemoraButtonVariant.secondary,
            isLoading: isBusy,
            onPressed: isBusy ? null : onOpen,
          ),
        ],
      ),
    );
  }
}

class _PrivacyActionCard extends StatelessWidget {
  const _PrivacyActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return MemoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: MemoraColors.brandBlue, size: 24),
              const SizedBox(width: MemoraSpacing.space12),
              Expanded(child: Text(title, style: MemoraTypography.cardTitle)),
            ],
          ),
          const SizedBox(height: MemoraSpacing.space12),
          Text(description, style: MemoraTypography.body),
          const SizedBox(height: MemoraSpacing.space16),
          action,
        ],
      ),
    );
  }
}
