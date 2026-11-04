import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/app_header.dart';
import '../../../design_system/components/banner.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../application/privacy_controller.dart';
import '../domain/privacy_models.dart';

/// Shared privacy page shell with a detail header and bounded content width.
class PrivacyScaffold extends StatelessWidget {
  const PrivacyScaffold({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: MemoraColors.surfaceSoft,
      appBar: MemoraHeader.detail(
        title: title,
        onBackPressed: () => _goBack(context),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MemoraSpacing.maxContentWidthFor(width),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MemoraSpacing.gutterForWidth(width),
                vertical: MemoraSpacing.space16,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  static void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }
}

/// Section heading used inside a privacy page.
class PrivacySectionHeading extends StatelessWidget {
  const PrivacySectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MemoraSpacing.space8),
      child: Text(text, style: MemoraTypography.sectionTitle),
    );
  }
}

/// Human-readable label for a server-reported privacy request status.
String privacyStatusLabel(PrivacyRequestStatus status) {
  switch (status) {
    case PrivacyRequestStatus.requested:
      return 'Requested';
    case PrivacyRequestStatus.verifying:
      return 'Verifying';
    case PrivacyRequestStatus.processing:
      return 'Processing';
    case PrivacyRequestStatus.completed:
      return 'Completed';
    case PrivacyRequestStatus.failed:
      return 'Failed';
    case PrivacyRequestStatus.cancelled:
      return 'Cancelled';
    case PrivacyRequestStatus.unknown:
      return 'Status unavailable';
  }
}

/// Semantic color for a privacy request status.
Color privacyStatusColor(PrivacyRequestStatus status) {
  switch (status) {
    case PrivacyRequestStatus.requested:
    case PrivacyRequestStatus.verifying:
    case PrivacyRequestStatus.processing:
      return MemoraColors.feedbackAttention;
    case PrivacyRequestStatus.completed:
      return MemoraColors.feedbackPositive;
    case PrivacyRequestStatus.failed:
      return MemoraColors.feedbackCritical;
    case PrivacyRequestStatus.cancelled:
    case PrivacyRequestStatus.unknown:
      return MemoraColors.textMuted;
  }
}

/// Formats a server timestamp for display without inventing timezone offsets.
String formatPrivacyTimestamp(DateTime? value) {
  if (value == null) return 'Not available';
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} ${local.year}, '
      '$hour:$minute local time';
}

/// Compact status pill with an accessible status label.
class PrivacyStatusChip extends StatelessWidget {
  const PrivacyStatusChip({super.key, required this.status});

  final PrivacyRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final label = privacyStatusLabel(status);
    final color = privacyStatusColor(status);

    return Semantics(
      label: 'Status: $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space12,
            vertical: MemoraSpacing.space4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(MemoraSpacing.space16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Text(
            label,
            style: MemoraTypography.metadata.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Request status summary card shared by export and deletion screens.
class PrivacyStatusCard extends StatelessWidget {
  const PrivacyStatusCard({
    super.key,
    required this.title,
    required this.status,
    this.requestedAt,
    this.completedAt,
    this.child,
  });

  final String title;
  final PrivacyRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? completedAt;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return MemoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: Text(title, style: MemoraTypography.cardTitle)),
              const SizedBox(width: MemoraSpacing.space8),
              PrivacyStatusChip(status: status),
            ],
          ),
          if (requestedAt != null) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space8),
            Text(
              'Requested ${formatPrivacyTimestamp(requestedAt)}',
              style: MemoraTypography.metadata,
            ),
          ],
          if (completedAt != null) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space4),
            Text(
              'Completed ${formatPrivacyTimestamp(completedAt)}',
              style: MemoraTypography.metadata,
            ),
          ],
          if (child != null) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space16),
            child!,
          ],
        ],
      ),
    );
  }
}

/// Consistent privacy banners for reachability, recovery and safe failures.
class PrivacyBanners extends StatelessWidget {
  const PrivacyBanners({
    super.key,
    required this.state,
    required this.onRetry,
    this.onReauthenticate,
    this.onDismissFailure,
    this.onDismissNotice,
    this.onSignOut,
  });

  final PrivacyState state;
  final VoidCallback onRetry;
  final VoidCallback? onReauthenticate;
  final VoidCallback? onDismissFailure;
  final VoidCallback? onDismissNotice;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    final showGenericFailure =
        failure != null &&
        !state.awaitingReauthentication &&
        !state.outcomeUnconfirmed &&
        !(state.isOffline && failure.code == 'network_error');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (state.isCheckingReachability)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: MemoraSpacing.space8),
            child: LinearProgressIndicator(
              minHeight: 4,
              semanticsLabel: 'Checking connection',
            ),
          ),
        if (state.isOffline)
          MemoraBanner(
            variant: MemoraBannerVariant.offline,
            title: 'You are offline',
            message:
                'Privacy actions are unavailable until Memora reconnects. '
                'Your requests are not changed while offline.',
            actionLabel: 'Retry',
            onAction: onRetry,
          ),
        if (state.awaitingReauthentication)
          MemoraBanner(
            variant: MemoraBannerVariant.attention,
            title: 'Confirm your identity',
            message:
                'For your security, confirm your credentials before this '
                'privacy action continues.',
            actionLabel: onReauthenticate == null ? null : 'Confirm identity',
            onAction: onReauthenticate,
          ),
        if (state.outcomeUnconfirmed)
          MemoraBanner(
            variant: MemoraBannerVariant.critical,
            title: 'Deletion status unconfirmed',
            message:
                'We could not confirm deletion request '
                '${state.outcomeUnconfirmedRequestId ?? 'unknown'}. Sign in '
                'again to check its status. Do not assume your data has been '
                'deleted.',
            actionLabel: onSignOut == null ? null : 'Sign out',
            onAction: onSignOut,
          ),
        if (state.proofMissing)
          const MemoraBanner(
            variant: MemoraBannerVariant.critical,
            title: 'Verification details missing',
            message:
                'The server reported this deletion as completed but did not '
                'return verification details. Do not assume all data has been '
                'removed. Contact support with the request ID shown here.',
          ),
        if (showGenericFailure)
          MemoraBanner(
            variant: failure.retryable
                ? MemoraBannerVariant.attention
                : MemoraBannerVariant.critical,
            title: 'Something went wrong',
            message: failure.message,
            actionLabel: failure.retryable ? 'Try again' : null,
            onAction: failure.retryable ? onRetry : null,
            onDismiss: onDismissFailure,
          ),
        if (state.notice != null)
          MemoraBanner(
            variant: MemoraBannerVariant.positive,
            message: state.notice!,
            onDismiss: onDismissNotice,
          ),
      ],
    );
  }
}
