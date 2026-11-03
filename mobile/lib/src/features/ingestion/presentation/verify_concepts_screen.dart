import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/app_header.dart';
import '../../../design_system/components/banner.dart';
import '../../../design_system/components/bottom_sheet.dart';
import '../../../design_system/components/button.dart';
import '../../../design_system/components/card.dart';
import '../../../design_system/components/dialog.dart';
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
import 'widgets/candidate_card.dart';

/// Concept verification destination (UI/UX §9.10, Flow §9.4, D10).
///
/// High-confidence concepts arrive accepted and included. Uncertain concepts
/// are marked **Check this** and stay editable locally until one idempotent
/// decisions submission. Bottom navigation is intentionally absent because this
/// is an immersive material-verification step (Flow §3.1).
class VerifyConceptsScreen extends ConsumerWidget {
  const VerifyConceptsScreen({
    super.key,
    this.updateId,
    this.controller,
    this.onBack,
    this.onPreview,
    this.onInvalidState,
  });

  /// Route update id. Null when a test injects [controller].
  final String? updateId;

  /// Test seam: a pre-built controller with a seeded repository.
  final VerificationController? controller;

  /// Test seams for navigation; production uses the router.
  final VoidCallback? onBack;
  final VoidCallback? onPreview;
  final VoidCallback? onInvalidState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final injected = controller;
    if (injected != null) {
      return _VerifyConceptsBody(
        controller: injected,
        onBack: onBack,
        onPreview: onPreview,
        onInvalidState: onInvalidState,
      );
    }

    final id = updateId;
    if (id == null || id.isEmpty) return const NotFoundScreen();

    final verificationController = ref.watch(
      verificationControllerProvider(id).notifier,
    );
    return _VerifyConceptsBody(
      controller: verificationController,
      onBack: onBack,
      onPreview: onPreview,
      onInvalidState: onInvalidState,
    );
  }
}

class _VerifyConceptsBody extends StatefulWidget {
  const _VerifyConceptsBody({
    required this.controller,
    this.onBack,
    this.onPreview,
    this.onInvalidState,
  });

  final VerificationController controller;
  final VoidCallback? onBack;
  final VoidCallback? onPreview;
  final VoidCallback? onInvalidState;

  @override
  State<_VerifyConceptsBody> createState() => _VerifyConceptsBodyState();
}

class _VerifyConceptsBodyState extends State<_VerifyConceptsBody> {
  late VerificationState _state;
  late final TextEditingController _editController;
  VoidCallback? _removeListener;
  String? _editingCandidateId;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    _state = widget.controller.currentState;
    _editController = TextEditingController();
    _listen();
    _maybeRedirect();
  }

  @override
  void didUpdateWidget(covariant _VerifyConceptsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _removeListener?.call();
      _state = widget.controller.currentState;
      _editingCandidateId = null;
      _editController.clear();
      _redirected = false;
      _listen();
      _maybeRedirect();
    }
  }

  void _listen() {
    _removeListener = widget.controller.addListener(_onChanged);
  }

  void _onChanged(VerificationState next) {
    if (!mounted) return;
    final editingId = _editingCandidateId;
    if (editingId != null) {
      final stillReviewable = next.reviewCandidates.any(
        (candidate) => candidate.id == editingId,
      );
      if (!stillReviewable) {
        _editingCandidateId = null;
        _editController.clear();
      }
    }
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
      context.pushReplacement(
        AppRoutes.materialStatusPath(widget.controller.updateId),
      );
    });
  }

  @override
  void dispose() {
    _removeListener?.call();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state.isNotFound) return const NotFoundScreen();

    return MemoraScaffold(
      appBar: MemoraHeader.detail(
        title: 'Verify concepts',
        onBackPressed: _back,
      ),
      offlineBanner: _state.isOffline
          ? MemoraBanner(
              variant: MemoraBannerVariant.offline,
              title: "You're offline",
              message:
                  _state.failure?.message ??
                  'Reconnect to review and preview these concepts.',
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
    if (_state.update == null) return _buildLoadFailure(context);

    return _buildReady(context);
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MemoraSpacing.space24),
      children: const <Widget>[
        MemoraSkeleton.text(width: 220),
        SizedBox(height: MemoraSpacing.space16),
        MemoraSkeleton.card(height: 150),
        SizedBox(height: MemoraSpacing.space12),
        MemoraSkeleton.card(height: 150),
        SizedBox(height: MemoraSpacing.space12),
        MemoraSkeleton.card(height: 150),
      ],
    );
  }

  Widget _buildLoadFailure(BuildContext context) {
    final failure = _state.failure;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: MemoraSpacing.space24),
      children: <Widget>[
        MemoraBanner(
          variant: MemoraBannerVariant.critical,
          title: 'Could not load these concepts',
          message: failure == null
              ? 'Something went wrong. Please try again.'
              : _failureCopy(failure),
          actionLabel: (failure?.retryable ?? true) ? 'Try again' : null,
          onAction: (failure?.retryable ?? true)
              ? widget.controller.refresh
              : null,
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
          'This material is no longer ready for review',
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

  Widget _buildReady(BuildContext context) {
    final ready = _state.readyCandidates;
    final review = _state.reviewCandidates;

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
                'Review the concepts Memora found',
                style: MemoraTypography.sectionTitle,
              ),
              const SizedBox(height: MemoraSpacing.space8),
              Text(
                'Concepts marked Check this need your review. You can edit a '
                'title, remove anything irrelevant, or merge a duplicate.',
                style: MemoraTypography.body.copyWith(
                  color: MemoraColors.textSecondary,
                ),
              ),
              const SizedBox(height: MemoraSpacing.space16),
              _summary(),
              if (_state.canPreview && _state.unresolvedCount > 0) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                Text(
                  'You can preview now. Concepts marked Check this must still '
                  'be reviewed before you add this path.',
                  style: MemoraTypography.metadata,
                ),
              ],
              if (_state.conflictNotice != null) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                MemoraBanner(
                  variant: MemoraBannerVariant.attention,
                  title: 'Concepts refreshed',
                  message: _state.conflictNotice!,
                ),
              ],
              if (_state.failure != null && !_state.isOffline) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                MemoraBanner(
                  variant: MemoraBannerVariant.critical,
                  title: 'Could not update these concepts',
                  message: _failureCopy(_state.failure!),
                  actionLabel: _state.failure!.retryable ? 'Try again' : null,
                  onAction: _state.failure!.retryable
                      ? widget.controller.refresh
                      : null,
                ),
              ],
              if (_state.isRefreshing) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                const LinearProgressIndicator(color: MemoraColors.brandBlue),
              ],
              if (review.isNotEmpty) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space24),
                Text(
                  'Check this (${review.length})',
                  style: MemoraTypography.cardTitle,
                ),
                const SizedBox(height: MemoraSpacing.space8),
                for (final candidate in review) ...<Widget>[
                  _candidateCard(context, candidate),
                  const SizedBox(height: MemoraSpacing.space12),
                ],
              ],
              if (ready.isNotEmpty) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                Text(
                  'Included (${ready.length})',
                  style: MemoraTypography.cardTitle,
                ),
                const SizedBox(height: MemoraSpacing.space8),
                for (final candidate in ready) ...<Widget>[
                  _candidateCard(context, candidate),
                  const SizedBox(height: MemoraSpacing.space12),
                ],
              ],
              if (review.isEmpty && ready.isEmpty) _emptyState(),
              if (_state.hasMore) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space8),
                MemoraButton(
                  label: 'Load more concepts',
                  variant: MemoraButtonVariant.secondary,
                  isLoading: _state.isLoadingMore,
                  onPressed: widget.controller.loadMore,
                ),
              ],
            ],
          ),
        ),
        _actionArea(context),
      ],
    );
  }

  Widget _summary() {
    final included = _state.includedCount;
    final unresolved = _state.unresolvedCount;
    final label =
        '$included ${included == 1 ? 'concept' : 'concepts'} included. '
        '$unresolved ${unresolved == 1 ? 'concept needs' : 'concepts need'} '
        'a check.';

    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(MemoraSpacing.space12),
          decoration: const BoxDecoration(
            color: MemoraColors.surfaceSoft,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Text(
            label,
            style: MemoraTypography.bodyStrong.copyWith(
              color: MemoraColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _candidateCard(BuildContext context, CandidateItem candidate) {
    final draft = _state.draftFor(candidate.id);
    final targetId = draft?.mergeIntoCandidateId;
    final target = targetId == null ? null : _candidateById(targetId);
    final isEditing = _editingCandidateId == candidate.id;

    return CandidateCard(
      candidate: candidate,
      draft: draft,
      mergeTargetTitle: target?.displayTitle,
      isLocked: _state.lockedCandidateIds.contains(candidate.id),
      isEditing: isEditing,
      editController: isEditing ? _editController : null,
      canSaveEdit: _editController.text.trim().isNotEmpty,
      canMerge: _mergeTargets(candidate).isNotEmpty,
      onAccept: () => widget.controller.accept(candidate.id),
      onEdit: () => _startEdit(candidate),
      onReject: () => widget.controller.reject(candidate.id),
      onMerge: () => _chooseMergeTarget(context, candidate),
      onUndo: () => widget.controller.clearDecision(candidate.id),
      onSaveEdit: () => _saveEdit(candidate.id),
      onCancelEdit: _cancelEdit,
      onEditChanged: (_) => setState(() {}),
    );
  }

  Widget _emptyState() {
    return MemoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('No concepts to check', style: MemoraTypography.cardTitle),
          const SizedBox(height: MemoraSpacing.space8),
          Text(
            'Memora did not find study concepts in this material. Go back and '
            'add different material.',
            style: MemoraTypography.body.copyWith(
              color: MemoraColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionArea(BuildContext context) {
    final reason = _state.previewDisabledReason;
    final blockedByOffline = _state.isOffline;
    final enabled = _state.canPreview && !blockedByOffline;

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
              'Reconnect to preview your learning path.',
              textAlign: TextAlign.center,
              style: MemoraTypography.metadata,
            ),
            const SizedBox(height: MemoraSpacing.space8),
          ] else if (reason != null) ...<Widget>[
            Text(
              reason,
              textAlign: TextAlign.center,
              style: MemoraTypography.metadata,
            ),
            const SizedBox(height: MemoraSpacing.space8),
          ],
          MemoraButton(
            label: 'Preview learning path',
            isLoading: _state.isSubmitting,
            onPressed: enabled ? _preview : null,
          ),
        ],
      ),
    );
  }

  Future<void> _preview() async {
    final proceed = await widget.controller.submitAndContinue();
    if (!mounted || !proceed) return;

    final callback = widget.onPreview;
    if (callback != null) {
      callback();
      return;
    }
    context.push(AppRoutes.pathPreviewPath(widget.controller.updateId));
  }

  void _startEdit(CandidateItem candidate) {
    final draft = _state.draftFor(candidate.id);
    setState(() {
      _editingCandidateId = candidate.id;
      _editController.value = TextEditingValue(
        text: draft?.editedTitle ?? candidate.displayTitle,
        selection: TextSelection.collapsed(
          offset: (draft?.editedTitle ?? candidate.displayTitle).length,
        ),
      );
    });
  }

  void _saveEdit(String candidateId) {
    widget.controller.editTitle(candidateId, _editController.text);
    setState(() {
      _editingCandidateId = null;
      _editController.clear();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCandidateId = null;
      _editController.clear();
    });
  }

  List<CandidateItem> _mergeTargets(CandidateItem source) {
    return _state.candidates
        .where(
          (candidate) =>
              candidate.id != source.id && _state.isIncluded(candidate),
        )
        .toList(growable: false);
  }

  CandidateItem? _candidateById(String id) {
    for (final candidate in _state.candidates) {
      if (candidate.id == id) return candidate;
    }
    return null;
  }

  Future<void> _chooseMergeTarget(
    BuildContext context,
    CandidateItem source,
  ) async {
    final targets = _mergeTargets(source);
    if (targets.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return MemoraDialog(
            title: 'Nothing to merge into yet',
            message:
                'Keep or accept another concept first, then merge this '
                'duplicate into it.',
            primaryActionLabel: 'Got it',
            onPrimaryAction: () => Navigator.of(dialogContext).pop(),
          );
        },
      );
      return;
    }

    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MemoraBottomSheet(
          title: 'Merge this concept',
          subtitle:
              'Choose the concept to keep. This one will be combined into it.',
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              for (final target in targets) ...<Widget>[
                MemoraCard(
                  onTap: () => Navigator.of(sheetContext).pop(target.id),
                  semanticLabel: 'Merge into ${target.displayTitle}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        target.displayTitle,
                        style: MemoraTypography.bodyStrong,
                      ),
                      const SizedBox(height: MemoraSpacing.space4),
                      Text(
                        _bandLabel(target.band),
                        style: MemoraTypography.metadata,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space8),
              ],
            ],
          ),
        );
      },
    );

    if (chosen == null || !mounted) return;
    widget.controller.mergeInto(source.id, chosen);
  }

  void _back() {
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

String _bandLabel(ConfidenceBand band) => switch (band) {
  ConfidenceBand.high => 'High confidence',
  ConfidenceBand.medium => 'Medium confidence',
  ConfidenceBand.low => 'Low confidence',
  ConfidenceBand.unknown => 'Confidence unavailable',
};
