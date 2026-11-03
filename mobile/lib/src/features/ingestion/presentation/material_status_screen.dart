import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/app_header.dart';
import '../../../design_system/components/banner.dart';
import '../../../design_system/components/bottom_nav.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/scaffold.dart';
import '../../../design_system/components/skeleton.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/radii.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../../common/presentation/authorized_placeholder_screen.dart';
import '../application/update_status_controller.dart';
import '../domain/ingestion_failure.dart';
import '../domain/ingestion_models.dart';
import 'widgets/source_tile.dart';

/// Authoritative material status destination (Flow §9.2, D7/D9).
///
/// All eight durable update states render here. Server processing continues
/// while the student is away; every entry re-reads the update first.
class MaterialStatusScreen extends ConsumerWidget {
  const MaterialStatusScreen({
    super.key,
    this.updateId,
    this.controller,
    this.onLeave,
    this.onVerifyConcepts,
    this.onPreviewPath,
    this.onAddMaterial,
  });

  /// Route update id. Null when a test injects [controller].
  final String? updateId;

  /// Test seam: a pre-built controller with a seeded repository.
  final UpdateStatusController? controller;

  /// Test seams for navigation; production uses the router.
  final VoidCallback? onLeave;
  final VoidCallback? onVerifyConcepts;
  final VoidCallback? onPreviewPath;
  final VoidCallback? onAddMaterial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injected = controller;
    if (injected != null) {
      return _MaterialStatusBody(
        controller: injected,
        onLeave: onLeave,
        onVerifyConcepts: onVerifyConcepts,
        onPreviewPath: onPreviewPath,
        onAddMaterial: onAddMaterial,
      );
    }

    final id = updateId;
    if (id == null || id.isEmpty) return const NotFoundScreen();

    final statusController = ref.watch(
      updateStatusControllerProvider(id).notifier,
    );
    return _MaterialStatusBody(
      controller: statusController,
      onLeave: onLeave,
      onVerifyConcepts: onVerifyConcepts,
      onPreviewPath: onPreviewPath,
      onAddMaterial: onAddMaterial,
    );
  }
}

class _MaterialStatusBody extends StatefulWidget {
  const _MaterialStatusBody({
    required this.controller,
    this.onLeave,
    this.onVerifyConcepts,
    this.onPreviewPath,
    this.onAddMaterial,
  });

  final UpdateStatusController controller;
  final VoidCallback? onLeave;
  final VoidCallback? onVerifyConcepts;
  final VoidCallback? onPreviewPath;
  final VoidCallback? onAddMaterial;

  @override
  State<_MaterialStatusBody> createState() => _MaterialStatusBodyState();
}

class _MaterialStatusBodyState extends State<_MaterialStatusBody> {
  late UpdateStatusState _state;
  VoidCallback? _removeListener;

  @override
  void initState() {
    super.initState();
    _state = widget.controller.currentState;
    _listen();
  }

  @override
  void didUpdateWidget(covariant _MaterialStatusBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _removeListener?.call();
      _state = widget.controller.currentState;
      _listen();
    }
  }

  void _listen() {
    _removeListener = widget.controller.addListener(_onChanged);
  }

  void _onChanged(UpdateStatusState next) {
    if (mounted) setState(() => _state = next);
  }

  @override
  void dispose() {
    _removeListener?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state.isNotFound) return const NotFoundScreen();

    return MemoraScaffold(
      appBar: MemoraHeader.detail(
        title: 'Material status',
        onBackPressed: () => _leave(context),
      ),
      offlineBanner: state.isOffline
          ? MemoraBanner(
              variant: MemoraBannerVariant.offline,
              title: "You're offline",
              message:
                  state.failure?.message ??
                  'Reconnect to check this material again.',
              actionLabel: 'Try again',
              onAction: widget.controller.refresh,
            )
          : null,
      bottomNavigationBar: MemoraBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) => _navigate(context, index),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, UpdateStatusState state) {
    if (state.isLoading) return _buildLoading(context);

    final snapshot = state.snapshot;
    if (snapshot == null) return _buildLoadFailure(context, state);

    return _buildReady(context, state, snapshot);
  }

  Widget _buildLoading(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MemoraSpacing.space24),
      children: <Widget>[
        MemoraLoadingTimeoutView(
          skeleton: const Column(
            children: <Widget>[
              MemoraSkeleton.card(height: 180),
              SizedBox(height: MemoraSpacing.space16),
              MemoraSkeleton.text(),
              SizedBox(height: MemoraSpacing.space8),
              MemoraSkeleton.text(width: 220),
            ],
          ),
          loadingMessage: 'Loading material status…',
          timeoutMessage:
              'This is taking longer than expected. You can wait, retry, or '
              'return to Learning.',
          onRetry: widget.controller.refresh,
          onLeave: () => _leave(context),
        ),
      ],
    );
  }

  Widget _buildLoadFailure(BuildContext context, UpdateStatusState state) {
    final failure = state.failure;
    final message = failure == null
        ? 'Memora could not load this material.'
        : _failureCopy(failure);
    // The persistent offline banner already offers the retry action.
    final canRetry = !state.isOffline;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MemoraSpacing.space24),
      children: <Widget>[
        MemoraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const ExcludeSemantics(
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: MemoraColors.feedbackCritical,
                ),
              ),
              const SizedBox(height: MemoraSpacing.space12),
              Text(
                'Could not load this material',
                textAlign: TextAlign.center,
                style: MemoraTypography.sectionTitle,
              ),
              const SizedBox(height: MemoraSpacing.space8),
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
        if (canRetry) ...<Widget>[
          const SizedBox(height: MemoraSpacing.space16),
          MemoraButton(
            label: 'Try again',
            onPressed: widget.controller.refresh,
          ),
        ],
        const SizedBox(height: MemoraSpacing.space8),
        MemoraButton(
          label: 'Back to Learning',
          variant: MemoraButtonVariant.secondary,
          onPressed: () => _leave(context),
        ),
      ],
    );
  }

  Widget _buildReady(
    BuildContext context,
    UpdateStatusState state,
    UpdateSnapshot snapshot,
  ) {
    final effectiveDeletion = _effectiveDeletion(snapshot);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(
              top: MemoraSpacing.space16,
              bottom: MemoraSpacing.space24,
            ),
            children: <Widget>[
              _statusCard(snapshot),
              if (state.failure != null && !state.isOffline) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                _refreshFailureBanner(state.failure!),
              ],
              if (snapshot.uploads.isNotEmpty) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space16),
                Text('Sources', style: MemoraTypography.cardTitle),
                const SizedBox(height: MemoraSpacing.space8),
                for (final upload in snapshot.uploads) ...<Widget>[
                  _uploadTile(upload),
                  const SizedBox(height: MemoraSpacing.space8),
                ],
              ],
              if (effectiveDeletion != SourceDeletionStatus.notRequired) ...[
                const SizedBox(height: MemoraSpacing.space8),
                _deletionCard(state, snapshot, effectiveDeletion),
              ],
              if (state.isSlow && snapshot.state.isInFlight) ...[
                const SizedBox(height: MemoraSpacing.space8),
                _slowBanner(context, state),
              ],
            ],
          ),
        ),
        _actionArea(context, state, snapshot),
      ],
    );
  }

  Widget _statusCard(UpdateSnapshot snapshot) {
    final copy = _statusCopy(snapshot);
    final isProblem =
        snapshot.state == LearningUpdateState.failed ||
        snapshot.state == LearningUpdateState.expired ||
        snapshot.state == LearningUpdateState.unknown;

    return MemoraCard(
      semanticLabel: '${copy.title}. ${copy.message}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(
                  copy.icon,
                  size: 28,
                  color: isProblem
                      ? MemoraColors.feedbackCritical
                      : MemoraColors.brandBlue,
                ),
              ),
              const SizedBox(width: MemoraSpacing.space12),
              Expanded(
                child: Text(copy.title, style: MemoraTypography.sectionTitle),
              ),
            ],
          ),
          const SizedBox(height: MemoraSpacing.space12),
          Text(
            copy.message,
            style: MemoraTypography.body.copyWith(
              color: MemoraColors.textSecondary,
            ),
          ),
          if (snapshot.state.isInFlight) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space16),
            LinearProgressIndicator(
              minHeight: 6,
              borderRadius: MemoraRadii.pill,
              color: MemoraColors.brandBlue,
              backgroundColor: MemoraColors.surfaceOcean,
              semanticsLabel: snapshot.state == LearningUpdateState.uploading
                  ? 'Receiving material'
                  : 'Extracting concepts',
            ),
          ],
        ],
      ),
    );
  }

  Widget _uploadTile(SourceItem upload) {
    final deletion = upload.deletionStatus;
    return Container(
      padding: const EdgeInsets.all(MemoraSpacing.space12),
      decoration: BoxDecoration(
        color: MemoraColors.surfaceCanvas,
        borderRadius: MemoraRadii.compactCard,
        border: Border.all(color: MemoraColors.borderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: Icon(
              upload.declaredMediaType == 'application/pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              color: MemoraColors.brandBlue,
            ),
          ),
          const SizedBox(width: MemoraSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  upload.declaredName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MemoraTypography.bodyStrong,
                ),
                const SizedBox(height: MemoraSpacing.space4),
                Text(
                  '${formatSourceSize(upload.byteSize)} · '
                  '${_uploadStatusLabel(upload.status)}',
                  style: MemoraTypography.metadata,
                ),
                if (deletion != SourceDeletionStatus.notRequired) ...<Widget>[
                  const SizedBox(height: MemoraSpacing.space4),
                  Text(
                    'Temporary source: ${_deletionLabel(deletion)}',
                    style: MemoraTypography.metadata.copyWith(
                      color: deletion == SourceDeletionStatus.failed
                          ? MemoraColors.feedbackCritical
                          : MemoraColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deletionCard(
    UpdateStatusState state,
    UpdateSnapshot snapshot,
    SourceDeletionStatus status,
  ) {
    final retryable = snapshot.deletionRetryAvailable;
    return MemoraCard(
      variant: MemoraCardVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Temporary source', style: MemoraTypography.cardTitle),
          const SizedBox(height: MemoraSpacing.space4),
          Text(
            _deletionMessage(status),
            style: MemoraTypography.metadata.copyWith(
              color: status == SourceDeletionStatus.failed
                  ? MemoraColors.feedbackCritical
                  : MemoraColors.textSecondary,
            ),
          ),
          if (retryable) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space8),
            MemoraButton(
              label: 'Retry source cleanup',
              variant: MemoraButtonVariant.tertiary,
              isFullWidth: false,
              isLoading: state.isRetrying,
              onPressed: state.isOffline
                  ? null
                  : widget.controller.retryDeletion,
            ),
            if (state.isOffline)
              Text(
                'Reconnect to retry source cleanup.',
                style: MemoraTypography.metadata,
              ),
          ],
        ],
      ),
    );
  }

  Widget _refreshFailureBanner(IngestionFailure failure) {
    return MemoraBanner(
      variant: MemoraBannerVariant.critical,
      title: 'Could not refresh this material',
      message: _failureCopy(failure),
      actionLabel: failure.retryable ? 'Try again' : null,
      onAction: failure.retryable ? widget.controller.refresh : null,
    );
  }

  Widget _slowBanner(BuildContext context, UpdateStatusState state) {
    return MemoraBanner(
      variant: MemoraBannerVariant.info,
      title: state.shouldLeaveAndReturn
          ? 'This is taking longer than usual'
          : 'You can leave this screen',
      message: state.shouldLeaveAndReturn
          ? 'Memora keeps working in the background. Leave and come back later '
                'to check your material.'
          : 'Memora keeps working while you are away. You can return to '
                'Learning and come back later.',
      actionLabel: 'Back to Learning',
      onAction: () => _leave(context),
    );
  }

  Widget _actionArea(
    BuildContext context,
    UpdateStatusState state,
    UpdateSnapshot snapshot,
  ) {
    final action = _primaryAction(context, state, snapshot);
    if (action == null) return const SizedBox.shrink();

    final blockedByOffline = state.isOffline && action.requiresNetwork;
    return Container(
      padding: const EdgeInsets.only(
        top: MemoraSpacing.space12,
        bottom: MemoraSpacing.space12,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: MemoraColors.borderDefault)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (blockedByOffline) ...<Widget>[
            Text(
              'Reconnect to continue.',
              textAlign: TextAlign.center,
              style: MemoraTypography.metadata,
            ),
            const SizedBox(height: MemoraSpacing.space8),
          ],
          MemoraButton(
            label: action.label,
            isLoading: state.isRetrying,
            onPressed: blockedByOffline ? null : action.onPressed,
          ),
          if (action.secondaryLabel != null) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space8),
            MemoraButton(
              label: action.secondaryLabel!,
              variant: MemoraButtonVariant.secondary,
              onPressed: action.secondaryOnPressed,
            ),
          ],
        ],
      ),
    );
  }

  _StatusAction? _primaryAction(
    BuildContext context,
    UpdateStatusState state,
    UpdateSnapshot snapshot,
  ) {
    switch (snapshot.state) {
      case LearningUpdateState.draft:
        return _StatusAction(
          label: 'Continue editing',
          onPressed: () => _addMaterial(context, snapshot),
        );
      case LearningUpdateState.verificationRequired:
        return _StatusAction(
          label: 'Verify concepts',
          requiresNetwork: true,
          onPressed: () => _verifyConcepts(context, snapshot),
        );
      case LearningUpdateState.committed:
        return _StatusAction(
          label: 'Preview learning path',
          requiresNetwork: true,
          onPressed: () => _previewPath(context, snapshot),
        );
      case LearningUpdateState.failed:
        if (state.canRetryExtraction) {
          return _StatusAction(
            label: 'Try again',
            requiresNetwork: true,
            onPressed: widget.controller.retryExtraction,
            secondaryLabel: 'Add different material',
            secondaryOnPressed: () => _addMaterial(context, snapshot),
          );
        }
        return _StatusAction(
          label: 'Add different material',
          onPressed: () => _addMaterial(context, snapshot),
        );
      case LearningUpdateState.expired:
        return _StatusAction(
          label: 'Start a new update',
          onPressed: () => _addMaterial(context, snapshot),
        );
      case LearningUpdateState.deleted:
        return _StatusAction(
          label: 'Back to Learning',
          onPressed: () => _leave(context),
        );
      case LearningUpdateState.uploading:
      case LearningUpdateState.processing:
        return null;
      case LearningUpdateState.unknown:
        return _StatusAction(
          label: 'Try again',
          requiresNetwork: true,
          onPressed: widget.controller.refresh,
        );
    }
  }

  void _verifyConcepts(BuildContext context, UpdateSnapshot snapshot) {
    final callback = widget.onVerifyConcepts;
    if (callback != null) {
      callback();
      return;
    }
    context.push(AppRoutes.verifyConceptsPath(snapshot.id));
  }

  void _previewPath(BuildContext context, UpdateSnapshot snapshot) {
    final callback = widget.onPreviewPath;
    if (callback != null) {
      callback();
      return;
    }
    context.push(AppRoutes.pathPreviewPath(snapshot.id));
  }

  void _addMaterial(BuildContext context, UpdateSnapshot snapshot) {
    final callback = widget.onAddMaterial;
    if (callback != null) {
      callback();
      return;
    }
    context.pushReplacement(AppRoutes.addMaterialPath(snapshot.subjectId));
  }

  void _leave(BuildContext context) {
    final callback = widget.onLeave;
    if (callback != null) {
      callback();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.learning);
    }
  }

  void _navigate(BuildContext context, int index) {
    final path = switch (index) {
      0 => AppRoutes.home,
      1 => AppRoutes.learning,
      2 => AppRoutes.progress,
      3 => AppRoutes.profile,
      _ => AppRoutes.learning,
    };
    context.go(path);
  }
}

class _StatusAction {
  const _StatusAction({
    required this.label,
    required this.onPressed,
    this.requiresNetwork = false,
    this.secondaryLabel,
    this.secondaryOnPressed,
  });

  final String label;
  final VoidCallback onPressed;
  final bool requiresNetwork;
  final String? secondaryLabel;
  final VoidCallback? secondaryOnPressed;
}

class _StatusCopy {
  const _StatusCopy(this.title, this.message, this.icon);

  final String title;
  final String message;
  final IconData icon;
}

_StatusCopy _statusCopy(UpdateSnapshot snapshot) {
  final failure = snapshot.failure;
  return switch (snapshot.state) {
    LearningUpdateState.draft => const _StatusCopy(
      'Draft material',
      'This material has not been sent for extraction yet. Continue where you '
          'left off.',
      Icons.edit_note,
    ),
    LearningUpdateState.uploading => const _StatusCopy(
      'Receiving your material',
      'Memora is receiving your files. This can take a moment.',
      Icons.cloud_upload_outlined,
    ),
    LearningUpdateState.processing => const _StatusCopy(
      'Extracting concepts',
      'Memora is reading your material and finding study concepts. This can '
          'take a moment.',
      Icons.auto_awesome_outlined,
    ),
    LearningUpdateState.verificationRequired => const _StatusCopy(
      'Concepts ready',
      'Review the concepts Memora found before building your learning path.',
      Icons.fact_check_outlined,
    ),
    LearningUpdateState.committed => const _StatusCopy(
      'Learning path ready',
      'Your material is part of your learning path. Preview it before you '
          'start.',
      Icons.check_circle_outline,
    ),
    LearningUpdateState.failed => _StatusCopy(
      'Memora could not finish this material',
      failure == null
          ? 'Something went wrong while processing this material.'
          : _failureCopy(failure),
      Icons.error_outline,
    ),
    LearningUpdateState.expired => const _StatusCopy(
      'Temporary material unavailable',
      'The temporary source expired before Memora could finish. Nothing was '
          'added to your learning path.',
      Icons.schedule,
    ),
    LearningUpdateState.deleted => const _StatusCopy(
      'Source removed',
      'This material was removed. Nothing was added to your learning path.',
      Icons.delete_outline,
    ),
    LearningUpdateState.unknown => const _StatusCopy(
      'Material unavailable',
      'We cannot show this material right now. Refresh to check again.',
      Icons.help_outline,
    ),
  };
}

String _failureCopy(IngestionFailure failure) {
  final nextAction = failure.nextAction;
  return nextAction == null
      ? failure.message
      : '${failure.message} $nextAction';
}

String _uploadStatusLabel(SourceUploadState status) {
  return switch (status) {
    SourceUploadState.authorized => 'Waiting to upload',
    SourceUploadState.uploaded => 'Uploaded, waiting for checks',
    SourceUploadState.validated => 'Checked',
    SourceUploadState.processing => 'Reading',
    SourceUploadState.deleting => 'Removing',
    SourceUploadState.deleted => 'Removed',
    SourceUploadState.rejected => 'Rejected',
    SourceUploadState.expired => 'Expired',
    SourceUploadState.unknown => 'Status unavailable',
  };
}

SourceDeletionStatus _effectiveDeletion(UpdateSnapshot snapshot) {
  if (snapshot.sourceDeletionStatus != SourceDeletionStatus.notRequired) {
    return snapshot.sourceDeletionStatus;
  }
  for (final upload in snapshot.uploads) {
    if (upload.deletionStatus != SourceDeletionStatus.notRequired) {
      return upload.deletionStatus;
    }
  }
  return SourceDeletionStatus.notRequired;
}

String _deletionLabel(SourceDeletionStatus status) {
  return switch (status) {
    SourceDeletionStatus.notRequired => 'Not required',
    SourceDeletionStatus.pending => 'Removing…',
    SourceDeletionStatus.deleted => 'Removed',
    SourceDeletionStatus.failed => 'Could not be removed yet',
    SourceDeletionStatus.unknown => 'Status unavailable',
  };
}

String _deletionMessage(SourceDeletionStatus status) {
  return switch (status) {
    SourceDeletionStatus.notRequired => '',
    SourceDeletionStatus.pending => 'Memora is removing the temporary source.',
    SourceDeletionStatus.deleted => 'The temporary source has been removed.',
    SourceDeletionStatus.failed =>
      'The temporary source could not be removed yet. Your learning path is '
          'not affected.',
    SourceDeletionStatus.unknown =>
      'The temporary source status is unavailable. Try again later.',
  };
}
