import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/banner.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../../auth/application/session_controller.dart';
import '../application/privacy_controller.dart';
import '../domain/privacy_models.dart';
import 'privacy_page.dart';

/// Export request and status destination.
///
/// Without [requestId] the screen explains and starts one export. With a
/// request identifier it reads the authoritative server status, polls while the
/// request is pending and offers a download only while the signed URL is valid.
class PrivacyExportScreen extends ConsumerStatefulWidget {
  const PrivacyExportScreen({super.key, this.requestId});

  final String? requestId;

  @override
  ConsumerState<PrivacyExportScreen> createState() =>
      _PrivacyExportScreenState();
}

class _PrivacyExportScreenState extends ConsumerState<PrivacyExportScreen> {
  late final PrivacyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(privacyControllerProvider.notifier);
    if (widget.requestId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.loadExport(widget.requestId!);
      });
    }
  }

  @override
  void dispose() {
    _controller.stopPolling();
    super.dispose();
  }

  Future<void> _requestExport() async {
    final export = await _controller.requestExport();
    if (!mounted || export == null) return;
    context.go(AppRoutes.privacyExportStatusPath(export.id));
  }

  void _retry() {
    final requestId = widget.requestId;
    if (requestId != null) {
      _controller.loadExport(requestId);
    } else {
      _controller.checkReachability();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privacyControllerProvider);
    final export = state.export;
    final isStatusRoute = widget.requestId != null;
    final loadedExport =
        export != null &&
            (widget.requestId == null || export.id == widget.requestId)
        ? export
        : null;

    return PrivacyScaffold(
      title: 'Export your data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrivacyBanners(
            state: state,
            onRetry: _retry,
            onReauthenticate: () => context.go(AppRoutes.privacyReauth),
            onDismissFailure: _controller.clearFailure,
            onDismissNotice: _controller.clearNotice,
            onSignOut: () {
              ref.read(sessionControllerProvider.notifier).signOut(force: true);
            },
          ),
          const SizedBox(height: MemoraSpacing.space8),
          if (state.isLoading && loadedExport == null)
            const _ExportLoadingCard()
          else if (isStatusRoute && loadedExport == null)
            _ExportLoadFailureCard(onRetry: _retry)
          else if (loadedExport == null)
            _ExportIntroCard(
              isSubmitting: state.isSubmitting,
              onRequest: _requestExport,
            )
          else
            _ExportStatusSection(
              export: loadedExport,
              state: state,
              canDownload: _controller.canDownloadExport,
              onDownload: _controller.downloadExport,
              onRefresh: _retry,
              onRequestNew: _requestExport,
            ),
        ],
      ),
    );
  }
}

class _ExportIntroCard extends StatelessWidget {
  const _ExportIntroCard({required this.isSubmitting, required this.onRequest});

  final bool isSubmitting;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PrivacySectionHeading('A copy of your Memora data'),
        Text(
          'Memora prepares a copy of your account data, including your '
          'profile, learning materials, notes, missions and progress. The '
          'export is generated in the background, so you can leave this screen '
          'safely.',
          style: MemoraTypography.body,
        ),
        const SizedBox(height: MemoraSpacing.space16),
        const _PrivacyBullet(
          text: 'The download link is temporary and opens in your browser.',
        ),
        const _PrivacyBullet(
          text: 'Keep the link private. Anyone with the link can open it.',
        ),
        const _PrivacyBullet(
          text:
              'Requesting again creates a fresh link after the old one '
              'expires.',
        ),
        const SizedBox(height: MemoraSpacing.space24),
        MemoraButton(
          key: const Key('privacy_export_request'),
          label: 'Request export',
          icon: const Icon(Icons.download_outlined),
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : onRequest,
        ),
        const SizedBox(height: MemoraSpacing.space16),
        const MemoraBanner(
          variant: MemoraBannerVariant.info,
          message:
              'Export requires a recent sign-in. If your recent sign-in has '
              'expired, Memora asks you to confirm your credentials first.',
        ),
      ],
    );
  }
}

class _ExportStatusSection extends StatelessWidget {
  const _ExportStatusSection({
    required this.export,
    required this.state,
    required this.canDownload,
    required this.onDownload,
    required this.onRefresh,
    required this.onRequestNew,
  });

  final PrivacyExport export;
  final PrivacyState state;
  final bool canDownload;
  final Future<void> Function() onDownload;
  final VoidCallback onRefresh;
  final Future<void> Function() onRequestNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PrivacyStatusCard(
          title: 'Export request',
          status: export.status,
          requestedAt: export.requestedAt,
          completedAt: export.completedAt,
          child: _buildStatusBody(context),
        ),
        const SizedBox(height: MemoraSpacing.space16),
        if (export.status.isPending) ...<Widget>[
          MemoraButton(
            key: const Key('privacy_export_refresh'),
            label: 'Refresh status',
            variant: MemoraButtonVariant.secondary,
            isLoading: state.isRefreshing,
            onPressed: state.isRefreshing ? null : onRefresh,
          ),
        ],
        if (export.status == PrivacyRequestStatus.completed) ...<Widget>[
          if (canDownload) ...<Widget>[
            MemoraButton(
              key: const Key('privacy_export_download'),
              label: 'Download export',
              icon: const Icon(Icons.open_in_new),
              isLoading: state.downloadInProgress,
              onPressed: state.downloadInProgress ? null : onDownload,
            ),
          ],
          const SizedBox(height: MemoraSpacing.space8),
          MemoraButton(
            key: const Key('privacy_export_request_new'),
            label: 'Request another export',
            variant: MemoraButtonVariant.tertiary,
            onPressed: state.isSubmitting ? null : onRequestNew,
          ),
        ],
        if (export.status == PrivacyRequestStatus.failed ||
            export.status == PrivacyRequestStatus.cancelled) ...<Widget>[
          MemoraButton(
            key: const Key('privacy_export_request_new'),
            label: 'Request a new export',
            onPressed: state.isSubmitting ? null : onRequestNew,
          ),
        ],
        if (export.status == PrivacyRequestStatus.unknown) ...<Widget>[
          MemoraButton(
            key: const Key('privacy_export_refresh'),
            label: 'Check again',
            variant: MemoraButtonVariant.secondary,
            isLoading: state.isRefreshing,
            onPressed: state.isRefreshing ? null : onRefresh,
          ),
        ],
        const SizedBox(height: MemoraSpacing.space24),
        const MemoraBanner(
          variant: MemoraBannerVariant.info,
          message:
              'The download link is temporary and is never stored by Memora. '
              'Request a new export if it expires.',
        ),
      ],
    );
  }

  Widget _buildStatusBody(BuildContext context) {
    switch (export.status) {
      case PrivacyRequestStatus.requested:
      case PrivacyRequestStatus.verifying:
      case PrivacyRequestStatus.processing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'We are preparing your export. You can leave this screen safely '
              'and return later.',
              style: MemoraTypography.body,
            ),
            const SizedBox(height: MemoraSpacing.space12),
            const LinearProgressIndicator(
              minHeight: 6,
              semanticsLabel: 'Export in progress',
            ),
          ],
        );
      case PrivacyRequestStatus.completed:
        if (!canDownload) {
          return Text(
            'The download link has expired. Request a new export to get a '
            'fresh temporary link.',
            style: MemoraTypography.body,
          );
        }
        final expiresAt = export.downloadExpiresAt;
        return Text(
          expiresAt == null
              ? 'Your export is ready. The download link is temporary.'
              : 'Your export is ready. The download link expires '
                    '${formatPrivacyTimestamp(expiresAt)}.',
          style: MemoraTypography.body,
        );
      case PrivacyRequestStatus.failed:
        return Text(
          'The export could not be completed. No download is available. You '
          'can request a new export when you are ready.',
          style: MemoraTypography.body,
        );
      case PrivacyRequestStatus.cancelled:
        return Text(
          'This export request was cancelled. You can request a new export.',
          style: MemoraTypography.body,
        );
      case PrivacyRequestStatus.unknown:
        return Text(
          'Memora received a status it does not recognise. Check again later. '
          'This screen never treats an unknown status as complete.',
          style: MemoraTypography.body,
        );
    }
  }
}

class _ExportLoadingCard extends StatelessWidget {
  const _ExportLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const MemoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Loading export status', style: MemoraTypography.cardTitle),
          SizedBox(height: MemoraSpacing.space12),
          LinearProgressIndicator(
            minHeight: 6,
            semanticsLabel: 'Loading export status',
          ),
        ],
      ),
    );
  }
}

class _ExportLoadFailureCard extends StatelessWidget {
  const _ExportLoadFailureCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MemoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Export status could not be loaded',
            style: MemoraTypography.cardTitle,
          ),
          const SizedBox(height: MemoraSpacing.space8),
          Text(
            'Memora could not read this request. Check your connection and try '
            'again. No export outcome is assumed.',
            style: MemoraTypography.body,
          ),
          const SizedBox(height: MemoraSpacing.space16),
          MemoraButton(
            key: const Key('privacy_export_retry_load'),
            label: 'Try again',
            variant: MemoraButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _PrivacyBullet extends StatelessWidget {
  const _PrivacyBullet({required this.text});

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
              Icons.check_circle_outline,
              size: 18,
              color: MemoraColors.brandBlue,
            ),
          ),
          const SizedBox(width: MemoraSpacing.space8),
          Expanded(child: Text(text, style: MemoraTypography.metadata)),
        ],
      ),
    );
  }
}
