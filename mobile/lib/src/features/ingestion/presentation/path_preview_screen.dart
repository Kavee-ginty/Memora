import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/app_header.dart';
import '../../../design_system/components/banner.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/scaffold.dart';
import '../../../design_system/components/skeleton.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../routing/app_routes.dart';
import '../../common/presentation/authorized_placeholder_screen.dart';
import '../application/verification_controller.dart';
import '../domain/ingestion_failure.dart';
import '../domain/ingestion_models.dart';

/// Learning-path preview destination (UI/UX §9.11, Flow §9.5, D11).
///
/// The preview shows the subject, source, concept count, estimated first
/// mission duration and the first concepts. **Add to my learning path** performs
/// one replay-safe commit. The ready state keeps **Start first mission** disabled
/// with an explanation while the backend returns no first mission. Bottom
/// navigation is intentionally absent because this is a material verification
/// step (Flow §3.1).
class PathPreviewScreen extends ConsumerWidget {
  const PathPreviewScreen({
    super.key,
    this.updateId,
    this.controller,
    this.onBack,
    this.onEditConcepts,
    this.onInvalidState,
    this.onStartMission,
  });

  /// Route update id. Null when a test injects [controller].
  final String? updateId;

  /// Test seam: a pre-built controller with a seeded repository.
  final PathPreviewController? controller;

  /// Test seams for navigation; production uses the router.
  final VoidCallback? onBack;
  final VoidCallback? onEditConcepts;
  final VoidCallback? onInvalidState;
  final VoidCallback? onStartMission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injected = controller;
    if (injected != null) {
      return _PathPreviewBody(
        controller: injected,
        onBack: onBack,
        onEditConcepts: onEditConcepts,
        onInvalidState: onInvalidState,
        onStartMission: onStartMission,
      );
    }

    final id = updateId;
    if (id == null || id.isEmpty) return const NotFoundScreen();

    final previewController = ref.watch(
      pathPreviewControllerProvider(id).notifier,
    );
    return _PathPreviewBody(
      controller: previewController,
      onBack: onBack,
      onEditConcepts: onEditConcepts,
      onInvalidState: onInvalidState,
      onStartMission: onStartMission,
    );
  }
}

class _PathPreviewBody extends StatefulWidget {
  const _PathPreviewBody({
    required this.controller,
    this.onBack,
    this.onEditConcepts,
    this.onInvalidState,
    this.onStartMission,
  });

  final PathPreviewController controller;
  final VoidCallback? onBack;
  final VoidCallback? onEditConcepts;
  final VoidCallback? onInvalidState;
  final VoidCallback? onStartMission;

  @override
  State<_PathPreviewBody> createState() => _PathPreviewBodyState();
}

class _PathPreviewBodyState extends State<_PathPreviewBody> {
  late PathPreviewState _state;
  VoidCallback? _removeListener;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    _state = widget.controller.currentState;
    _listen();
    _maybeRedirect();
  }

  @override
  void didUpdateWidget(covariant _PathPreviewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _removeListener?.call();
      _state = widget.controller.currentState;
      _redirected = false;
      _listen();
      _maybeRedirect();
    }
  }

  void _listen() {
    _removeListener = widget.controller.addListener(_onChanged);
  }

  void _onChanged(PathPreviewState next) {
    if (!mounted) return;
    setState(() => _state = next);
    _maybeRedirect();
  }

  void _maybeRedirect() {
    if (_redirected || !_state.isInvalidState) return;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final callback = widget.onInvalidState;
      if (callback != null) {
        callback();
        return;
      }
      context.go(AppRoutes.materialStatusPath(widget.controller.updateId));
    });
  }

  @override
  void dispose() {
    _removeListener?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isNotFound) return const NotFoundScreen();

    return MemoraScaffold(
      appBar: MemoraHeader.detail(
        title: 'Learning path preview',
        onBackPressed: _back,
      ),
      offlineBanner: _state.isOffline
          ? MemoraBanner(
              variant: MemoraBannerVariant.offline,
              title: "You're offline",
              message:
                  _state.failure?.message ??
                  'Reconnect to review and add this learning path.',
              actionLabel: 'Try again',
              onAction: widget.controller.refresh,
            )
          : null,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_state.isInvalidState) return _buildInvalidState(context);
    if (_state.isLoading) return _buildLoading();
    if (_state.isCommitted) return _buildReady(context);
    if (_state.preview == null) return _buildLoadFailure(context);
    return _buildPreview(context);
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MemoraSpacing.space24),
      children: const <Widget>[
        MemoraSkeleton.text(width: 240),
        SizedBox(height: MemoraSpacing.space16),
        MemoraSkeleton.card(height: 210),
        SizedBox(height: MemoraSpacing.space12),
        MemoraSkeleton.card(height: 140),
      ],
    );
  }

  Widget _buildLoadFailure(BuildContext context) {
    final failure = _state.failure;
    // The persistent offline banner already offers the retry action.
    final canRetry = !_state.isOffline && (failure?.retryable ?? true);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MemoraSpacing.space24),
      children: <Widget>[
        MemoraBanner(
          variant: MemoraBannerVariant.critical,
          title: 'Could not load your learning path',
          message: failure == null
              ? 'Something went wrong. Please try again.'
              : _failureCopy(failure),
          actionLabel: canRetry ? 'Try again' : null,
          onAction: canRetry ? widget.controller.refresh : null,
        ),
        const SizedBox(height: MemoraSpacing.space16),
        MemoraButton(
          label: 'Back to material status',
          variant: MemoraButtonVariant.secondary,
          onPressed: _back,
        ),
      ],
    );
  }

  Widget _buildInvalidState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MemoraSpacing.space24),
      children: <Widget>[
        Text(
          'This material is not ready to preview',
          style: MemoraTypography.sectionTitle,
        ),
        const SizedBox(height: MemoraSpacing.space8),
        Text(
          'Its status changed while you were away. Memora will show the latest '
          'status instead.',
          style: MemoraTypography.body.copyWith(
            color: MemoraColors.textSecondary,
          ),
        ),
        const SizedBox(height: MemoraSpacing.space24),
        MemoraButton(label: 'Back to material status', onPressed: _back),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final blockedReason = _state.blockedReasonCopy;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(
              top: MemoraSpacing.space16,
              bottom: MemoraSpacing.space24,
            ),
            children: <Widget>[
              Text(
                'Preview your learning path',
                style: MemoraTypography.sectionTitle,
              ),
              const SizedBox(height: MemoraSpacing.space8),
              Text(
                'Check the subject, source and concepts before adding them to '
                'your learning path.',
                style: MemoraTypography.body.copyWith(
                  color: MemoraColors.textSecondary,
                ),
              ),
              const SizedBox(height: MemoraSpacing.space16),
              _summaryCard(),
              if (_state.notice != null) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                MemoraBanner(
                  variant: MemoraBannerVariant.attention,
                  title: 'Preview refreshed',
                  message: _state.notice!,
                ),
              ],
              if (blockedReason != null) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                MemoraBanner(
                  variant: MemoraBannerVariant.attention,
                  title: 'This path is not ready yet',
                  message: blockedReason,
                ),
              ],
              if (_state.failure != null && !_state.isOffline) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                MemoraBanner(
                  variant: MemoraBannerVariant.critical,
                  title: 'Could not add this learning path',
                  message: _failureCopy(_state.failure!),
                  actionLabel: _state.failure!.retryable ? 'Try again' : null,
                  onAction: _state.failure!.retryable && _state.canCommit
                      ? _commit
                      : null,
                ),
              ],
              if (_state.isRefreshing) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                const LinearProgressIndicator(color: MemoraColors.brandBlue),
              ],
              const SizedBox(height: MemoraSpacing.space24),
              Text('First concepts', style: MemoraTypography.cardTitle),
              const SizedBox(height: MemoraSpacing.space8),
              _conceptList(),
              const SizedBox(height: MemoraSpacing.space16),
              Text(
                'Adding this path does not earn XP. You earn XP by completing '
                'retrieval missions.',
                style: MemoraTypography.metadata,
              ),
            ],
          ),
        ),
        _previewActions(),
      ],
    );
  }

  Widget _buildReady(BuildContext context) {
    final mission = _state.firstMission;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(
              top: MemoraSpacing.space16,
              bottom: MemoraSpacing.space24,
            ),
            children: <Widget>[
              Text(
                'Your learning path is ready',
                style: MemoraTypography.sectionTitle,
              ),
              const SizedBox(height: MemoraSpacing.space8),
              Text(
                _state.outcome == null
                    ? 'This material is already in your learning path.'
                    : 'Your concepts are now part of your learning path.',
                style: MemoraTypography.body.copyWith(
                  color: MemoraColors.textSecondary,
                ),
              ),
              const SizedBox(height: MemoraSpacing.space16),
              _summaryCard(),
              if (_state.notice != null) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                MemoraBanner(
                  variant: MemoraBannerVariant.attention,
                  title: 'Learning path updated',
                  message: _state.notice!,
                ),
              ],
              const SizedBox(height: MemoraSpacing.space24),
              Text('First concepts', style: MemoraTypography.cardTitle),
              const SizedBox(height: MemoraSpacing.space8),
              _conceptList(),
              const SizedBox(height: MemoraSpacing.space16),
              Text(
                'Adding this path does not earn XP. You earn XP by completing '
                'retrieval missions.',
                style: MemoraTypography.metadata,
              ),
              const SizedBox(height: MemoraSpacing.space16),
              _deletionCard(),
            ],
          ),
        ),
        _readyActions(mission),
      ],
    );
  }

  Widget _summaryCard() {
    final minutes = _state.estimatedFirstMissionMinutes;
    final count = _state.conceptCount;
    return MemoraCard(
      semanticLabel:
          '${_state.subjectName ?? 'Subject unavailable'}. '
          '${_state.sourceName ?? 'Source unavailable'}. '
          '$count ${count == 1 ? 'concept' : 'concepts'}. '
          '${minutes == null ? 'First mission duration not available yet.' : 'Estimated first mission $minutes minutes.'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _detail('Subject', _state.subjectName ?? 'Subject unavailable'),
          const SizedBox(height: MemoraSpacing.space12),
          _detail('Source', _state.sourceName ?? 'Source unavailable'),
          const SizedBox(height: MemoraSpacing.space12),
          _detail('Concepts', '$count'),
          const SizedBox(height: MemoraSpacing.space12),
          _detail(
            'First mission',
            minutes == null ? 'Not available yet' : 'About $minutes min',
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: MemoraTypography.metadata),
        const SizedBox(height: MemoraSpacing.space4),
        Text(value, style: MemoraTypography.bodyStrong),
      ],
    );
  }

  Widget _conceptList() {
    final concepts = _state.firstConcepts;
    if (concepts.isEmpty) {
      return MemoraCard(
        variant: MemoraCardVariant.compact,
        child: Text(
          'No concepts are included yet.',
          style: MemoraTypography.body.copyWith(
            color: MemoraColors.textSecondary,
          ),
        ),
      );
    }

    return MemoraCard(
      variant: MemoraCardVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var index = 0; index < concepts.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(height: MemoraSpacing.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ExcludeSemantics(
                  child: Text(
                    '${index + 1}.',
                    style: MemoraTypography.bodyStrong.copyWith(
                      color: MemoraColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: MemoraSpacing.space8),
                Expanded(
                  child: Text(
                    concepts[index].title,
                    style: MemoraTypography.bodyStrong,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _deletionCard() {
    final status = _state.deletionStatus;
    final isProblem = status == SourceDeletionStatus.failed;
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
              color: isProblem
                  ? MemoraColors.feedbackCritical
                  : MemoraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewActions() {
    // The blocked banner above already explains a disabled commit. Only the
    // connectivity reason needs to sit next to the action.
    final reason = _state.isOffline ? _state.commitDisabledReason : null;
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
          if (reason != null) ...<Widget>[
            Text(
              reason,
              textAlign: TextAlign.center,
              style: MemoraTypography.metadata,
            ),
            const SizedBox(height: MemoraSpacing.space8),
          ],
          MemoraButton(
            label: 'Add to my learning path',
            isLoading: _state.isCommitting,
            onPressed: _state.canCommit ? _commit : null,
          ),
          const SizedBox(height: MemoraSpacing.space8),
          MemoraButton(
            label: 'Edit concepts',
            variant: MemoraButtonVariant.secondary,
            onPressed: _state.isCommitting ? null : _editConcepts,
          ),
        ],
      ),
    );
  }

  Widget _readyActions(FirstMissionInfo? mission) {
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
          if (mission == null) ...<Widget>[
            Text(
              'The first mission is not available yet. Your learning path is '
              'saved, and you can start missions from Home when they are ready.',
              textAlign: TextAlign.center,
              style: MemoraTypography.metadata,
            ),
            const SizedBox(height: MemoraSpacing.space8),
          ],
          MemoraButton(
            label: 'Start first mission',
            onPressed: mission == null ? null : _startMission,
          ),
          const SizedBox(height: MemoraSpacing.space8),
          MemoraButton(
            label: 'Back to material status',
            variant: MemoraButtonVariant.secondary,
            onPressed: _backToStatus,
          ),
        ],
      ),
    );
  }

  Future<void> _commit() async {
    await widget.controller.commit();
  }

  void _editConcepts() {
    final callback = widget.onEditConcepts;
    if (callback != null) {
      callback();
      return;
    }
    context.pushReplacement(
      AppRoutes.verifyConceptsPath(widget.controller.updateId),
    );
  }

  void _startMission() {
    final mission = _state.firstMission;
    if (mission == null) return;
    final callback = widget.onStartMission;
    if (callback != null) {
      callback();
      return;
    }
    context.push(AppRoutes.missionPreviewPath(mission.missionId));
  }

  void _backToStatus() {
    final callback = widget.onBack;
    if (callback != null) {
      callback();
      return;
    }
    context.go(AppRoutes.materialStatusPath(widget.controller.updateId));
  }

  void _back() {
    if (_state.isCommitted) {
      _backToStatus();
      return;
    }
    final callback = widget.onBack;
    if (callback != null) {
      callback();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.materialStatusPath(widget.controller.updateId));
    }
  }
}

String _failureCopy(IngestionFailure failure) {
  final nextAction = failure.nextAction;
  return nextAction == null
      ? failure.message
      : '${failure.message} $nextAction';
}

String _deletionMessage(SourceDeletionStatus status) {
  return switch (status) {
    SourceDeletionStatus.notRequired => 'No temporary source needs cleanup.',
    SourceDeletionStatus.pending =>
      'Memora is removing the temporary source. Your learning path is not '
          'affected.',
    SourceDeletionStatus.deleted =>
      'The temporary source has been removed. Your learning path is kept.',
    SourceDeletionStatus.failed =>
      'The temporary source could not be removed yet. Your learning path is '
          'not affected.',
    SourceDeletionStatus.unknown =>
      'The temporary source status is unavailable. Try again later.',
  };
}
