import 'package:flutter/material.dart';

import '../../../../design_system/components/button.dart';
import '../../../../design_system/components/text_field.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/radii.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../design_system/tokens/typography.dart';
import '../../domain/ingestion_models.dart';

/// One extracted concept with its confidence band, source context and local
/// review controls (UI/UX §9.10, D10).
///
/// Confidence is always communicated with text and an icon, never colour alone
/// (UIX-005). High-confidence concepts arrive already accepted and are shown as
/// included; uncertain concepts carry the **Check this** marker until the
/// student accepts, edits, rejects or merges them.
class CandidateCard extends StatelessWidget {
  const CandidateCard({
    super.key,
    required this.candidate,
    this.draft,
    this.mergeTargetTitle,
    this.isLocked = false,
    this.isEditing = false,
    this.editController,
    this.canSaveEdit = false,
    this.canMerge = false,
    this.onAccept,
    this.onEdit,
    this.onReject,
    this.onMerge,
    this.onUndo,
    this.onSaveEdit,
    this.onCancelEdit,
    this.onEditChanged,
  });

  final CandidateItem candidate;
  final DecisionDraft? draft;
  final String? mergeTargetTitle;
  final bool isLocked;
  final bool isEditing;
  final TextEditingController? editController;
  final bool canSaveEdit;
  final bool canMerge;
  final VoidCallback? onAccept;
  final VoidCallback? onEdit;
  final VoidCallback? onReject;
  final VoidCallback? onMerge;
  final VoidCallback? onUndo;
  final VoidCallback? onSaveEdit;
  final VoidCallback? onCancelEdit;
  final ValueChanged<String>? onEditChanged;

  bool get _needsReview => candidate.needsReview;

  bool get _isRejected => draft?.kind == VerificationDecisionKind.reject;

  String get _displayTitle => draft?.kind == VerificationDecisionKind.edit
      ? (draft?.editedTitle ?? candidate.displayTitle)
      : candidate.displayTitle;

  String get _stateLabel {
    if (!_needsReview) return 'Included in your learning path';
    final decision = draft;
    if (decision == null) return 'Check this';
    return switch (decision.kind) {
      VerificationDecisionKind.accept => 'Accepted',
      VerificationDecisionKind.edit => 'Edited and accepted',
      VerificationDecisionKind.reject => 'Removed',
      VerificationDecisionKind.merge =>
        mergeTargetTitle == null
            ? 'Merged into another concept'
            : 'Merged into $mergeTargetTitle',
    };
  }

  /// One combined announcement so a screen reader hears confidence, state,
  /// title, summary and source context before the action controls.
  String get _semanticLabel {
    final summary = candidate.displaySummary?.trim();
    return <String>[
      _bandLabel(candidate.band),
      _stateLabel,
      _displayTitle,
      if (summary != null && summary.isNotEmpty) summary,
      if (candidate.sourceContext != null) candidate.sourceContext!,
    ].join('. ');
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _needsReview && draft == null
        ? MemoraColors.feedbackAttention
        : MemoraColors.borderDefault;

    return Container(
      padding: const EdgeInsets.all(MemoraSpacing.space16),
      decoration: BoxDecoration(
        color: MemoraColors.surfaceCanvas,
        borderRadius: MemoraRadii.compactCard,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MemoraSpacing.space8,
            runSpacing: MemoraSpacing.space8,
            children: <Widget>[
              ExcludeSemantics(child: _BandChip(band: candidate.band)),
              ExcludeSemantics(
                child: _StateChip(
                  label: _stateLabel,
                  isRejected: _isRejected,
                  needsReview: _needsReview && draft == null,
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoraSpacing.space12),
          if (isEditing)
            MemoraTextField(
              label: 'Concept title',
              controller: editController,
              maxLines: 2,
              enabled: !isLocked,
              helperText: 'Up to 240 characters.',
              onChanged: onEditChanged,
            )
          else
            Semantics(
              container: true,
              label: _semanticLabel,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _displayTitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: MemoraTypography.cardTitle.copyWith(
                        color: _isRejected
                            ? MemoraColors.textMuted
                            : MemoraColors.textPrimary,
                        decoration: _isRejected
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (candidate.displaySummary != null &&
                        candidate.displaySummary!
                            .trim()
                            .isNotEmpty) ...<Widget>[
                      const SizedBox(height: MemoraSpacing.space8),
                      Text(
                        candidate.displaySummary!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: MemoraTypography.body.copyWith(
                          color: MemoraColors.textSecondary,
                        ),
                      ),
                    ],
                    if (candidate.sourceContext != null) ...<Widget>[
                      const SizedBox(height: MemoraSpacing.space8),
                      Text(
                        candidate.sourceContext!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MemoraTypography.metadata,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (isEditing) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space12),
            Wrap(
              spacing: MemoraSpacing.space8,
              runSpacing: MemoraSpacing.space8,
              children: <Widget>[
                MemoraButton(
                  label: 'Save title',
                  semanticLabel: 'Save title for $_displayTitle',
                  isFullWidth: false,
                  onPressed: isLocked || !canSaveEdit ? null : onSaveEdit,
                ),
                MemoraButton(
                  label: 'Cancel',
                  semanticLabel: 'Cancel editing $_displayTitle',
                  variant: MemoraButtonVariant.tertiary,
                  isFullWidth: false,
                  onPressed: isLocked ? null : onCancelEdit,
                ),
              ],
            ),
          ] else if (_needsReview) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space12),
            Wrap(
              spacing: MemoraSpacing.space8,
              runSpacing: MemoraSpacing.space8,
              children: <Widget>[
                if (draft == null) ...<Widget>[
                  MemoraButton(
                    label: 'Accept',
                    semanticLabel: 'Accept $_displayTitle',
                    isFullWidth: false,
                    onPressed: isLocked ? null : onAccept,
                  ),
                  MemoraButton(
                    label: 'Edit title',
                    semanticLabel: 'Edit title of $_displayTitle',
                    variant: MemoraButtonVariant.secondary,
                    isFullWidth: false,
                    onPressed: isLocked ? null : onEdit,
                  ),
                  MemoraButton(
                    label: 'Remove',
                    semanticLabel: 'Remove $_displayTitle',
                    variant: MemoraButtonVariant.tertiary,
                    isFullWidth: false,
                    onPressed: isLocked ? null : onReject,
                  ),
                  if (canMerge)
                    MemoraButton(
                      label: 'Merge',
                      semanticLabel: 'Merge $_displayTitle',
                      variant: MemoraButtonVariant.tertiary,
                      isFullWidth: false,
                      onPressed: isLocked ? null : onMerge,
                    ),
                ] else ...<Widget>[
                  MemoraButton(
                    label: 'Undo',
                    semanticLabel: 'Undo decision for $_displayTitle',
                    variant: MemoraButtonVariant.secondary,
                    isFullWidth: false,
                    onPressed: isLocked ? null : onUndo,
                  ),
                  if (draft!.kind !=
                      VerificationDecisionKind.reject) ...<Widget>[
                    MemoraButton(
                      label: 'Edit title',
                      semanticLabel: 'Edit title of $_displayTitle',
                      variant: MemoraButtonVariant.tertiary,
                      isFullWidth: false,
                      onPressed: isLocked ? null : onEdit,
                    ),
                    if (canMerge)
                      MemoraButton(
                        label: 'Merge',
                        semanticLabel: 'Merge $_displayTitle',
                        variant: MemoraButtonVariant.tertiary,
                        isFullWidth: false,
                        onPressed: isLocked ? null : onMerge,
                      ),
                  ],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BandChip extends StatelessWidget {
  const _BandChip({required this.band});

  final ConfidenceBand band;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (band) {
      ConfidenceBand.high => (
        Icons.verified_outlined,
        'High confidence',
        MemoraColors.feedbackPositive,
      ),
      ConfidenceBand.medium => (
        Icons.help_outline,
        'Medium confidence',
        MemoraColors.feedbackAttention,
      ),
      ConfidenceBand.low => (
        Icons.error_outline,
        'Low confidence',
        MemoraColors.feedbackCritical,
      ),
      ConfidenceBand.unknown => (
        Icons.help_outline,
        'Confidence unavailable',
        MemoraColors.textMuted,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: MemoraSpacing.space4),
        Flexible(
          child: Text(
            label,
            style: MemoraTypography.metadata.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.isRejected,
    required this.needsReview,
  });

  final String label;
  final bool isRejected;
  final bool needsReview;

  @override
  Widget build(BuildContext context) {
    final color = needsReview
        ? MemoraColors.feedbackAttention
        : isRejected
        ? MemoraColors.textMuted
        : MemoraColors.feedbackPositive;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space8,
        vertical: MemoraSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: MemoraColors.surfaceSoft,
        borderRadius: MemoraRadii.pill,
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: MemoraTypography.metadata.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _bandLabel(ConfidenceBand band) => switch (band) {
  ConfidenceBand.high => 'High confidence',
  ConfidenceBand.medium => 'Medium confidence',
  ConfidenceBand.low => 'Low confidence',
  ConfidenceBand.unknown => 'Confidence unavailable',
};
