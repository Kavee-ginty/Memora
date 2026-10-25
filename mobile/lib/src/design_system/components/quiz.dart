import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
/// Designed to exactly match the solid colored pill buttons in Memora quiz screens
/// (docs/screens/quiz.png and UI mockups).
/// Complies with UIX-005 (meaning never conveyed by color alone via semantics)
/// and UIX-030 (minimum 48x48 px touch target).
class MemoraQuizOption extends StatefulWidget {
  const MemoraQuizOption({
    super.key,
    required this.text,
    this.indexLabel,
    this.state = MemoraQuizOptionState.defaultState,
    this.onTap,
    this.isMultiSelect = false,
    this.showIndexBadge = false,
    this.focusNode,
    this.autofocus = false,
  });

  final String text;
  final String? indexLabel;
  final MemoraQuizOptionState state;
  final VoidCallback? onTap;
  final bool isMultiSelect;
  final bool showIndexBadge;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<MemoraQuizOption> createState() => _MemoraQuizOptionState();
}

class _MemoraQuizOptionState extends State<MemoraQuizOption> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isFocused = _effectiveFocusNode.hasFocus;
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(MemoraQuizOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(
        _handleFocusChange,
      );
      _effectiveFocusNode.addListener(_handleFocusChange);
      _isFocused = _effectiveFocusNode.hasFocus;
    }
  }

  void _handleFocusChange() {
    if (mounted && _isFocused != _effectiveFocusNode.hasFocus) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    (widget.focusNode ?? _internalFocusNode)?.removeListener(
      _handleFocusChange,
    );
    _internalFocusNode?.dispose();
    super.dispose();
  }

  bool get _isEnabled =>
      widget.state != MemoraQuizOptionState.disabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor = MemoraColors.textPrimary;

    switch (widget.state) {
      case MemoraQuizOptionState.defaultState:
        backgroundColor = MemoraColors.quizOptionRest; // #86BBE7
        borderColor = const Color(0xFF7CB1E8);
        break;
      case MemoraQuizOptionState.selected:
        backgroundColor = const Color(0xFFD4EBFB); // Distinct selected tint
        borderColor = MemoraColors.focus; // Cyan focus border
        break;
      case MemoraQuizOptionState.correct:
        backgroundColor = MemoraColors.quizOptionCorrect; // #1FE46B
        borderColor = const Color(0xFF15C858);
        break;
      case MemoraQuizOptionState.weakMemory:
        backgroundColor = MemoraColors.quizOptionWeakMemory; // #ED8F91
        borderColor = const Color(0xFFD67375);
        break;
      case MemoraQuizOptionState.disabled:
        backgroundColor = MemoraColors.quizOptionRest.withValues(alpha: 0.45);
        borderColor = Colors.transparent;
        textColor = MemoraColors.textMuted;
        break;
    }

    final String labelPrefix = widget.indexLabel != null
        ? 'Option ${widget.indexLabel}, '
        : 'Option ';
    final String stateLabel = switch (widget.state) {
      MemoraQuizOptionState.defaultState => '$labelPrefix${widget.text}',
      MemoraQuizOptionState.selected => '$labelPrefix${widget.text}, selected',
      MemoraQuizOptionState.correct =>
        '$labelPrefix${widget.text}, correct, memory protected',
      MemoraQuizOptionState.weakMemory =>
        '$labelPrefix${widget.text}, weak memory',
      MemoraQuizOptionState.disabled => '$labelPrefix${widget.text}, disabled',
    };

    final bool showFocusBorder =
        _isFocused || widget.state == MemoraQuizOptionState.selected;

    return Semantics(
      button: true,
      enabled: widget.state != MemoraQuizOptionState.disabled,
      selected: widget.state == MemoraQuizOptionState.selected,
      label: stateLabel,
      child: Focus(
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        onFocusChange: (bool focused) {
          if (mounted && _isFocused != focused) {
            setState(() {
              _isFocused = focused;
            });
          }
        },
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (_isEnabled &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            if (event is KeyDownEvent) {
              widget.onTap?.call();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18.0),
          elevation: 0,
          child: InkWell(
            onTap: widget.state == MemoraQuizOptionState.disabled
                ? null
                : widget.onTap,
            borderRadius: BorderRadius.circular(18.0),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(
                horizontal: MemoraSpacing.space16,
                vertical: MemoraSpacing.space12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(
                  color: _isFocused ? MemoraColors.focus : borderColor,
                  width: showFocusBorder ? 2.0 : 1.0,
                ),
                boxShadow: widget.state == MemoraQuizOptionState.selected
                    ? MemoraElevations.cardShadows
                    : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (widget.showIndexBadge &&
                      widget.indexLabel != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        widget.indexLabel!,
                        style: MemoraTypography.metadata.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: MemoraSpacing.space8),
                  ],
                  Flexible(
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: MemoraTypography.bodyStrong.copyWith(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A responsive container for quiz answer choice buttons conforming to UIX-017.
///
/// Per UIX-017: Answer options may use two columns only when every option fits
/// on one line at the active text scale and each target remains at least 48 px tall.
/// Otherwise, answers automatically switch to a single column layout.
class MemoraQuizGrid extends StatelessWidget {
  const MemoraQuizGrid({
    super.key,
    required this.options,
    this.spacing = MemoraSpacing.space12,
    this.forceSingleColumn = false,
  });

  final List<Widget> options;
  final double spacing;
  final bool forceSingleColumn;

  bool _shouldUseTwoColumns(BuildContext context, double maxWidth) {
    if (forceSingleColumn) return false;
    if (options.length != 4) return false;
    if (!maxWidth.isFinite || maxWidth <= 0) return false;

    final double columnWidth = (maxWidth - spacing) / 2.0;
    // If column width is less than minimum viable touch width or cramped
    if (columnWidth < 120.0) return false;

    final TextScaler textScaler = MediaQuery.textScalerOf(context);

    // Padding inside MemoraQuizOption: 16px horizontal on each side = 32px + 4px border margin
    final double horizontalPadding = (MemoraSpacing.space16 * 2) + 4.0;
    final double availableTextWidth = columnWidth - horizontalPadding;
    if (availableTextWidth <= 0) return false;

    // Check each option: all 4 must fit on a single line at the active text scale
    for (final Widget option in options) {
      if (option is MemoraQuizOption) {
        double optAvailableWidth = availableTextWidth;
        if (option.showIndexBadge && option.indexLabel != null) {
          optAvailableWidth -= 40.0;
        }
        if (optAvailableWidth <= 0) return false;

        final TextPainter painter = TextPainter(
          text: TextSpan(
            text: option.text,
            style: MemoraTypography.bodyStrong.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
          maxLines: 1,
        )..layout(maxWidth: double.infinity);

        // If single line width exceeds available column text width, must use single column
        if (painter.width > optAvailableWidth) {
          return false;
        }
      } else {
        // Fallback for non-MemoraQuizOption widgets
        if (textScaler.scale(1.0) >= 1.5 || columnWidth < 140.0) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useTwoColumns = _shouldUseTwoColumns(
          context,
          constraints.maxWidth,
        );

        if (useTwoColumns && options.length == 4) {
          return Column(
            key: const ValueKey('MemoraQuizGridTwoColumns'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                key: const ValueKey('MemoraQuizGridRow0'),
                children: <Widget>[
                  Expanded(child: options[0]),
                  SizedBox(width: spacing),
                  Expanded(child: options[1]),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                key: const ValueKey('MemoraQuizGridRow1'),
                children: <Widget>[
                  Expanded(child: options[2]),
                  SizedBox(width: spacing),
                  Expanded(child: options[3]),
                ],
              ),
            ],
          );
        }

        // Single column layout per UIX-017
        return Column(
          key: const ValueKey('MemoraQuizGridSingleColumn'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < options.length; i++) ...<Widget>[
              if (i > 0) SizedBox(height: spacing),
              options[i],
            ],
          ],
        );
      },
    );
  }
}

/// Rounded countdown timer badge displayed at the top right of the quiz card.
///
/// Matches the cyan timer in docs/screens/quiz.png (#00C7FF).
class MemoraTimerBadge extends StatelessWidget {
  const MemoraTimerBadge({
    super.key,
    this.timeFormatted,
    this.remainingSeconds,
    this.label = 'Time remaining',
  });

  final String? timeFormatted;
  final int? remainingSeconds;
  final String label;

  String get _displayTime {
    if (timeFormatted != null) {
      return timeFormatted!;
    }
    if (remainingSeconds != null) {
      final int m = remainingSeconds! ~/ 60;
      final int s = remainingSeconds! % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '04:32';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space12,
        vertical: MemoraSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: MemoraColors.timerBadge,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: MemoraElevations.cardShadows,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            _displayTime,
            style: MemoraTypography.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MemoraColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: MemoraTypography.metadata.copyWith(
              fontSize: 9,
              color: MemoraColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary action button at the bottom of the quiz card.
///
/// Preserves canonical brand primary styling (#00C7FF) for retrieval progression actions.
enum MemoraQuizActionVariant {
  checkAnswer,
  nextPrimary,
  nextCorrect,
  nextWeakMemory,
}

class MemoraQuizActionButton extends StatelessWidget {
  const MemoraQuizActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MemoraQuizActionVariant.checkAnswer,
  });

  final String label;
  final VoidCallback? onPressed;
  final MemoraQuizActionVariant variant;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = switch (variant) {
      MemoraQuizActionVariant.checkAnswer ||
      MemoraQuizActionVariant.nextPrimary =>
        MemoraColors.timerBadge, // #00C7FF (Canonical brand action)
      MemoraQuizActionVariant.nextCorrect =>
        MemoraColors.quizOptionMint, // #74EFA3
      MemoraQuizActionVariant.nextWeakMemory =>
        MemoraColors.quizOptionWeakMemory, // #ED8F91
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: MemoraSpacing.minTouchTarget,
        minWidth: double.infinity,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: MemoraColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space16,
            vertical: MemoraSpacing.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          softWrap: true,
          style: MemoraTypography.button.copyWith(
            color: MemoraColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
                softWrap: true,
                style: MemoraTypography.metadata.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MemoraColors.textMuted,
                ),
              ),
              Text(
                '$memoriesProtectedCount protected',
                softWrap: true,
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
