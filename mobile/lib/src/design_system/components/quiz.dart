import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/elevations.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'button.dart';

/// State of a quiz option selection in an active retrieval mission.
enum MemoraQuizOptionState {
  defaultState,
  selected,
  correct,
  weakMemory,
  disabled,
}

/// A responsive, accessible answer choice card for quiz questions.
///
/// Complies with UIX-005 (meaning never conveyed by color alone) and UIX-025 (response controls).
class MemoraQuizOption extends StatelessWidget {
  const MemoraQuizOption({
    super.key,
    required this.indexLabel,
    required this.text,
    this.state = MemoraQuizOptionState.defaultState,
    this.onTap,
    this.isMultiSelect = false,
  });

  final String indexLabel;
  final String text;
  final MemoraQuizOptionState state;
  final VoidCallback? onTap;
  final bool isMultiSelect;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor = MemoraColors.textPrimary;
    Widget? trailingIcon;

    switch (state) {
      case MemoraQuizOptionState.defaultState:
        backgroundColor = MemoraColors.surfaceCanvas;
        borderColor = MemoraColors.borderDefault;
        break;
      case MemoraQuizOptionState.selected:
        backgroundColor = MemoraColors.controlSelected;
        borderColor = MemoraColors.focus;
        trailingIcon = Icon(
          isMultiSelect ? Icons.check_box : Icons.radio_button_checked,
          color: MemoraColors.focus,
          size: 20,
        );
        break;
      case MemoraQuizOptionState.correct:
        backgroundColor = MemoraColors.surfaceMint;
        borderColor = MemoraColors.feedbackPositive;
        trailingIcon = const Icon(
          Icons.check_circle,
          color: MemoraColors.feedbackPositive,
          size: 20,
        );
        break;
      case MemoraQuizOptionState.weakMemory:
        backgroundColor = const Color(0xFFFFF9F2);
        borderColor = MemoraColors.feedbackAttention;
        trailingIcon = const Icon(
          Icons.error_outline,
          color: MemoraColors.feedbackAttention,
          size: 20,
        );
        break;
      case MemoraQuizOptionState.disabled:
        backgroundColor = MemoraColors.surfaceSoft;
        borderColor = MemoraColors.borderDefault.withValues(alpha: 0.5);
        textColor = MemoraColors.textMuted;
        break;
    }

    final String stateLabel = switch (state) {
      MemoraQuizOptionState.defaultState => 'Option $indexLabel, $text',
      MemoraQuizOptionState.selected => 'Option $indexLabel, $text, selected',
      MemoraQuizOptionState.correct =>
        'Option $indexLabel, $text, correct, memory protected',
      MemoraQuizOptionState.weakMemory =>
        'Option $indexLabel, $text, weak memory',
      MemoraQuizOptionState.disabled => 'Option $indexLabel, $text, disabled',
    };

    return Semantics(
      button: true,
      enabled: state != MemoraQuizOptionState.disabled,
      selected: state == MemoraQuizOptionState.selected,
      label: stateLabel,
      child: Material(
        color: backgroundColor,
        borderRadius: MemoraRadii.control,
        elevation: 0,
        child: InkWell(
          onTap: state == MemoraQuizOptionState.disabled ? null : onTap,
          borderRadius: MemoraRadii.control,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(
              horizontal: MemoraSpacing.space16,
              vertical: MemoraSpacing.space12,
            ),
            decoration: BoxDecoration(
              borderRadius: MemoraRadii.control,
              border: Border.all(
                color: borderColor,
                width:
                    state == MemoraQuizOptionState.selected ||
                        state == MemoraQuizOptionState.correct ||
                        state == MemoraQuizOptionState.weakMemory
                    ? 2.0
                    : 1.0,
              ),
              boxShadow: state == MemoraQuizOptionState.selected
                  ? MemoraElevations.cardShadows
                  : null,
            ),
            child: Row(
              children: <Widget>[
                // Index Indicator badge (A, B, C, D)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: state == MemoraQuizOptionState.selected
                        ? MemoraColors.brandPrimary
                        : (state == MemoraQuizOptionState.correct
                              ? MemoraColors.feedbackPositive
                              : MemoraColors.surfaceSoft),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color:
                          state == MemoraQuizOptionState.selected ||
                              state == MemoraQuizOptionState.correct
                          ? Colors.transparent
                          : MemoraColors.borderDefault,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    indexLabel,
                    style: MemoraTypography.metadata.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          state == MemoraQuizOptionState.selected ||
                              state == MemoraQuizOptionState.correct
                          ? Colors.white
                          : MemoraColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: MemoraSpacing.space12),
                // Text prompt
                Expanded(
                  child: Text(
                    text,
                    style: MemoraTypography.body.copyWith(
                      color: textColor,
                      fontWeight: state == MemoraQuizOptionState.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...<Widget>[
                  const SizedBox(width: MemoraSpacing.space8),
                  trailingIcon,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented progress bar for retrieval missions showing question progression.
class MemoraQuizProgressBar extends StatelessWidget {
  const MemoraQuizProgressBar({
    super.key,
    required this.totalQuestions,
    required this.currentQuestionIndex,
    this.memoriesProtectedCount = 0,
  }) : assert(totalQuestions > 0, 'Total questions must be greater than zero');

  final int totalQuestions;
  final int currentQuestionIndex;
  final int memoriesProtectedCount;

  @override
  Widget build(BuildContext context) {
    final double fraction = ((currentQuestionIndex + 1) / totalQuestions).clamp(
      0.0,
      1.0,
    );

    return Semantics(
      label:
          'Mission progress: Question ${currentQuestionIndex + 1} of $totalQuestions, '
          '$memoriesProtectedCount memories protected',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MemoraSpacing.space8,
            runSpacing: MemoraSpacing.space4,
            children: <Widget>[
              Text(
                'Question ${currentQuestionIndex + 1} of $totalQuestions',
                style: MemoraTypography.metadata.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MemoraColors.textMuted,
                ),
              ),
              Text(
                '$memoriesProtectedCount protected',
                style: MemoraTypography.metadata.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MemoraColors.feedbackPositive,
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoraSpacing.space8),
          ClipRRect(
            borderRadius: MemoraRadii.pill,
            child: SizedBox(
              height: 8,
              child: Stack(
                children: <Widget>[
                  Container(
                    color: MemoraColors.borderDefault.withValues(alpha: 0.35),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: MemoraColors.brandGradient,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Variant of the feedback panel shown immediately after answer check.
enum MemoraFeedbackType { recalled, weakMemory }

/// Inline feedback panel for active retrieval missions.
///
/// Follows UIX-002, UIX-004, UIX-005 and Section 9.13/9.14.
class MemoraFeedbackPanel extends StatelessWidget {
  const MemoraFeedbackPanel({
    super.key,
    required this.type,
    required this.headline,
    required this.body,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final MemoraFeedbackType type;
  final String headline;
  final String body;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final bool isRecalled = type == MemoraFeedbackType.recalled;
    final Color bgColor = isRecalled
        ? MemoraColors.surfaceMint
        : const Color(0xFFFFF9F2);
    final Color borderColor = isRecalled
        ? const Color(0xFFA6E0B8)
        : const Color(0xFFF7D19E);
    final Color iconColor = isRecalled
        ? MemoraColors.feedbackPositive
        : MemoraColors.feedbackAttention;
    final IconData icon = isRecalled
        ? Icons.shield_outlined
        : Icons.healing_outlined;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$headline. $body',
      child: Container(
        padding: const EdgeInsets.all(MemoraSpacing.space16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: MemoraRadii.primaryCard,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: MemoraElevations.cardShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: MemoraSpacing.space12),
                Expanded(
                  child: Text(
                    headline,
                    style: MemoraTypography.cardTitle.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MemoraSpacing.space8),
            Text(
              body,
              style: MemoraTypography.body.copyWith(
                color: MemoraColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: MemoraSpacing.space16),
            Wrap(
              spacing: MemoraSpacing.space12,
              runSpacing: MemoraSpacing.space8,
              children: <Widget>[
                if (secondaryActionLabel != null && onSecondaryAction != null)
                  MemoraButton(
                    label: secondaryActionLabel!,
                    variant: MemoraButtonVariant.secondary,
                    onPressed: onSecondaryAction,
                  ),
                MemoraButton(
                  label: primaryActionLabel,
                  variant: MemoraButtonVariant.primary,
                  onPressed: onPrimaryAction,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Concept explanation card shown during active missions (UIX Section 9.15).
class MemoraConceptExplanationCard extends StatelessWidget {
  const MemoraConceptExplanationCard({
    super.key,
    required this.conceptTitle,
    required this.explanation,
    required this.sourceExcerpt,
    this.sourceTitle,
    this.onContinue,
  });

  final String conceptTitle;
  final String explanation;
  final String sourceExcerpt;
  final String? sourceTitle;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MemoraSpacing.space16),
      decoration: BoxDecoration(
        color: MemoraColors.surfaceCanvas,
        borderRadius: MemoraRadii.primaryCard,
        border: Border.all(color: MemoraColors.borderDefault),
        boxShadow: MemoraElevations.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.lightbulb_outline,
                color: MemoraColors.focus,
                size: 22,
              ),
              const SizedBox(width: MemoraSpacing.space8),
              Expanded(
                child: Text(
                  conceptTitle,
                  style: MemoraTypography.cardTitle.copyWith(
                    color: MemoraColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoraSpacing.space12),
          Text(
            explanation,
            style: MemoraTypography.body.copyWith(
              color: MemoraColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: MemoraSpacing.space16),
          // Source Reference Block
          Container(
            padding: const EdgeInsets.all(MemoraSpacing.space12),
            decoration: BoxDecoration(
              color: MemoraColors.surfaceSoft,
              borderRadius: MemoraRadii.chip,
              border: Border.all(color: MemoraColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 14,
                      color: MemoraColors.textMuted,
                    ),
                    const SizedBox(width: MemoraSpacing.space4),
                    Expanded(
                      child: Text(
                        sourceTitle ?? 'Source Material Excerpt',
                        style: MemoraTypography.metadata.copyWith(
                          fontWeight: FontWeight.bold,
                          color: MemoraColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MemoraSpacing.space4),
                Text(
                  '"$sourceExcerpt"',
                  style: MemoraTypography.metadata.copyWith(
                    fontStyle: FontStyle.italic,
                    color: MemoraColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onContinue != null) ...<Widget>[
            const SizedBox(height: MemoraSpacing.space16),
            SizedBox(
              width: double.infinity,
              child: MemoraButton(
                label: 'Continue Mission',
                onPressed: onContinue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
