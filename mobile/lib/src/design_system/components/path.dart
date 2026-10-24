import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/elevations.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'button.dart';

/// The 5 canonical node states on a learning path map.
///
/// Derived from Section 9.8 of Memora_UI_UX_Design_Specification.md.
enum MemoraPathNodeState { completed, current, available, locked, needsReview }

/// Which side the circular node is placed on in an alternating winding path.
enum MemoraPathNodeSide { left, right }

/// A node widget on the winding learning path map.
///
/// Adheres to UIX-001 (clear primary action), UIX-005 (non-color meaning),
/// and UIX-030 (minimum 48x48 px touch target).
class MemoraPathNode extends StatelessWidget {
  const MemoraPathNode({
    super.key,
    required this.title,
    required this.state,
    this.stepNumber,
    this.onTap,
    this.lockReason,
  });

  final String title;
  final MemoraPathNodeState state;
  final int? stepNumber;
  final VoidCallback? onTap;
  final String? lockReason;

  @override
  Widget build(BuildContext context) {
    final bool isReducedMotion = MediaQuery.disableAnimationsOf(context);

    Color nodeBg;
    Color nodeBorder;
    Color iconColor;
    IconData icon;

    switch (state) {
      case MemoraPathNodeState.completed:
        nodeBg = MemoraColors.brandPrimary;
        nodeBorder = MemoraColors.brandAqua;
        iconColor = Colors.white;
        icon = Icons.check;
        break;
      case MemoraPathNodeState.current:
        nodeBg = MemoraColors.brandPrimary;
        nodeBorder = MemoraColors.brandAqua;
        iconColor = Colors.white;
        icon = Icons.play_arrow_rounded;
        break;
      case MemoraPathNodeState.available:
        nodeBg = MemoraColors.surfaceCanvas;
        nodeBorder = MemoraColors.brandPrimary;
        iconColor = MemoraColors.focus;
        icon = Icons.star_border_rounded;
        break;
      case MemoraPathNodeState.locked:
        nodeBg = const Color(0xFFE2EEF8);
        nodeBorder = const Color(0xFFCCE2F2);
        iconColor = const Color(0xFF7A9BB8);
        icon = Icons.lock_outline_rounded;
        break;
      case MemoraPathNodeState.needsReview:
        nodeBg = const Color(0xFFFFF9F2);
        nodeBorder = MemoraColors.feedbackAttention;
        iconColor = MemoraColors.feedbackAttention;
        icon = Icons.replay_rounded;
        break;
    }

    final String semanticLabel = switch (state) {
      MemoraPathNodeState.completed => 'Completed concept: $title',
      MemoraPathNodeState.current => 'Current mission: $title. Ready to start.',
      MemoraPathNodeState.available => 'Available concept: $title',
      MemoraPathNodeState.locked =>
        'Locked concept: $title. ${lockReason ?? 'Prerequisites incomplete.'}',
      MemoraPathNodeState.needsReview => 'Review due for: $title',
    };

    return Semantics(
      button: state != MemoraPathNodeState.locked,
      enabled: state != MemoraPathNodeState.locked,
      label: semanticLabel,
      child: GestureDetector(
        onTap: state == MemoraPathNodeState.locked ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Circular Node Anchor
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Pulse halo ring for Current node (static if reduced motion)
                if (state == MemoraPathNodeState.current)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MemoraColors.brandPrimary.withValues(
                        alpha: isReducedMotion ? 0.25 : 0.35,
                      ),
                    ),
                  ),

                // Main Node circle (meets >= 48px touch target: 60x60 px)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: nodeBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: nodeBorder,
                      width: state == MemoraPathNodeState.current ? 3.0 : 2.0,
                    ),
                    boxShadow: MemoraElevations.cardShadows,
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 28)),
                ),

                // Optional Step Number indicator
                if (stepNumber != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: MemoraColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$stepNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MemoraSpacing.space8),
            // Node title label
            SizedBox(
              width: 120,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: MemoraTypography.metadata.copyWith(
                  fontWeight: state == MemoraPathNodeState.current
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: state == MemoraPathNodeState.locked
                      ? MemoraColors.textMuted
                      : MemoraColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Learning Path Header Card at the top of the Learning screen.
///
/// Shows subject title, quiz completion ratio, and thick rounded progress bar.
class MemoraLearningPathHeader extends StatelessWidget {
  const MemoraLearningPathHeader({
    super.key,
    required this.title,
    required this.completedCount,
    required this.totalCount,
    this.subtitle = 'Your learning path',
  });

  final String title;
  final int completedCount;
  final int totalCount;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final double fraction = totalCount > 0
        ? (completedCount / totalCount).clamp(0.0, 1.0)
        : 0.0;
    final int percentage = (fraction * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(MemoraSpacing.space24),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F0FD),
        borderRadius: MemoraRadii.primaryCard,
        border: Border.all(color: const Color(0xFFCCE2F6)),
        boxShadow: MemoraElevations.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.menu_book_rounded,
                color: MemoraColors.brandPrimary,
                size: 20,
              ),
              const SizedBox(width: MemoraSpacing.space8),
              Text(
                subtitle,
                style: MemoraTypography.metadata.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MemoraColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoraSpacing.space8),
          Text(
            title,
            style: MemoraTypography.pageTitle.copyWith(
              fontSize: 24,
              color: MemoraColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MemoraSpacing.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '$completedCount of $totalCount Quizzes completed',
                style: MemoraTypography.bodyStrong.copyWith(
                  color: MemoraColors.textPrimary,
                ),
              ),
              Text(
                '$percentage%',
                style: MemoraTypography.pageTitle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MemoraColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoraSpacing.space8),
          ClipRRect(
            borderRadius: BorderRadius.circular(MemoraRadii.pillValue),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: <Widget>[
                  Container(color: const Color(0xFFC7E2F8)),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: MemoraColors.brandPrimary,
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

/// Small milestone pill centered between units (e.g. "✓ Quiz 1–4 completed").
class MemoraMilestonePill extends StatelessWidget {
  const MemoraMilestonePill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MemoraSpacing.space16,
          vertical: MemoraSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: MemoraRadii.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.check, size: 16, color: MemoraColors.brandPrimary),
            const SizedBox(width: MemoraSpacing.space4),
            Text(
              text,
              style: MemoraTypography.metadata.copyWith(
                fontWeight: FontWeight.w600,
                color: MemoraColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An alternating node row on the winding path trail.
///
/// Places the circular node on the [nodeSide] (left or right) and the descriptive
/// text on the opposite side, connected by the visual trail.
class MemoraWindingPathRow extends StatelessWidget {
  const MemoraWindingPathRow({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.state,
    this.nodeSide = MemoraPathNodeSide.right,
    this.onTap,
  });

  final int stepNumber;
  final String title;
  final String subtitle;
  final MemoraPathNodeState state;
  final MemoraPathNodeSide nodeSide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = state == MemoraPathNodeState.completed;
    final bool isLocked = state == MemoraPathNodeState.locked;

    final Color nodeBg = isCompleted
        ? MemoraColors.brandPrimary
        : (isLocked ? const Color(0xFFE2EEF8) : MemoraColors.surfaceCanvas);
    final Color nodeBorder = isCompleted
        ? MemoraColors.brandAqua
        : (isLocked ? const Color(0xFFCCE2F2) : MemoraColors.brandPrimary);
    final Color iconColor = isCompleted
        ? Colors.white
        : (isLocked ? const Color(0xFF7A9BB8) : MemoraColors.brandPrimary);
    final IconData icon = isCompleted
        ? Icons.check
        : (isLocked ? Icons.lock_outline_rounded : Icons.star_border_rounded);

    final Widget nodeWidget = GestureDetector(
      onTap: isLocked ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: nodeBg,
          shape: BoxShape.circle,
          border: Border.all(color: nodeBorder, width: 2.0),
          boxShadow: isCompleted ? MemoraElevations.cardShadows : null,
        ),
        child: Center(child: Icon(icon, color: iconColor, size: 28)),
      ),
    );

    final Widget textWidget = Column(
      crossAxisAlignment: nodeSide == MemoraPathNodeSide.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$stepNumber · $title',
          style: MemoraTypography.cardTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isLocked ? MemoraColors.textMuted : MemoraColors.textPrimary,
          ),
        ),
        const SizedBox(height: MemoraSpacing.space4),
        Text(
          subtitle,
          style: MemoraTypography.metadata.copyWith(
            color: MemoraColors.textMuted,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space16,
        vertical: MemoraSpacing.space12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: nodeSide == MemoraPathNodeSide.right
            ? <Widget>[
                Expanded(child: textWidget),
                const SizedBox(width: MemoraSpacing.space16),
                nodeWidget,
              ]
            : <Widget>[
                nodeWidget,
                const SizedBox(width: MemoraSpacing.space16),
                Expanded(child: textWidget),
              ],
      ),
    );
  }
}

/// The active mission node card with Mora mascot illustration, speech bubble,
/// "YOU ARE HERE" badge, lesson metadata, and primary "Start Quiz" button.
///
/// Matches the center of the uploaded Everyday English screen.
class MemoraPathActiveCard extends StatelessWidget {
  const MemoraPathActiveCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.speechBubbleText = "You're making waves!",
    this.badgeText = 'YOU ARE HERE',
    this.buttonLabel = 'Start Quiz',
    this.onStart,
    this.mascotAsset = 'assets/mascot/teaching.png',
  });

  final String title;
  final String subtitle;
  final String speechBubbleText;
  final String badgeText;
  final String buttonLabel;
  final VoidCallback? onStart;
  final String mascotAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space16,
        vertical: MemoraSpacing.space16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Concentric double-ring Active Node
          GestureDetector(
            onTap: onStart,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: MemoraColors.brandPrimary,
                  width: 3.5,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x3300AFFF),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: MemoraColors.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: MemoraSpacing.space16),

          // Right Column: Mora mascot with speech bubble + Mission info & CTA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Mora mascot + Speech Bubble row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    // Speech bubble
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MemoraSpacing.space12,
                          vertical: MemoraSpacing.space8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5FE),
                          borderRadius: BorderRadius.circular(
                            MemoraRadii.chipValue,
                          ),
                          border: Border.all(color: const Color(0xFFD4EBFB)),
                        ),
                        child: Text(
                          speechBubbleText,
                          style: MemoraTypography.metadata.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MemoraColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: MemoraSpacing.space8),
                    // Transparent Mora illustration
                    Image.asset(
                      mascotAsset,
                      width: 76,
                      height: 76,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4EBFB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school,
                                color: MemoraColors.brandPrimary,
                              ),
                            );
                          },
                    ),
                  ],
                ),
                const SizedBox(height: MemoraSpacing.space4),

                // YOU ARE HERE badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraSpacing.space8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF1FE),
                    borderRadius: BorderRadius.circular(MemoraRadii.pillValue),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontFamily: 'Exo',
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Color(0xFF007ECC),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space8),

                // Lesson title & metadata
                Text(
                  title,
                  style: MemoraTypography.cardTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space4),
                Text(
                  subtitle,
                  style: MemoraTypography.metadata.copyWith(
                    color: MemoraColors.textMuted,
                  ),
                ),
                const SizedBox(height: MemoraSpacing.space12),

                // Start Quiz primary button
                SizedBox(
                  width: double.infinity,
                  child: MemoraButton(
                    label: buttonLabel,
                    variant: MemoraButtonVariant.primary,
                    onPressed: onStart,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reward gift box node row (e.g. "+50 XP reward, Finish Quiz 8 to unlock").
class MemoraPathRewardRow extends StatelessWidget {
  const MemoraPathRewardRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.card_giftcard_rounded,
    this.nodeSide = MemoraPathNodeSide.left,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final MemoraPathNodeSide nodeSide;

  @override
  Widget build(BuildContext context) {
    final Widget giftWidget = Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFE2F0FD),
        borderRadius: BorderRadius.circular(MemoraRadii.controlValue),
        border: Border.all(color: const Color(0xFFCCE4F8), width: 1.5),
      ),
      child: Center(
        child: Icon(icon, color: MemoraColors.brandPrimary, size: 28),
      ),
    );

    final Widget textWidget = Column(
      crossAxisAlignment: nodeSide == MemoraPathNodeSide.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: MemoraTypography.cardTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0088D6),
          ),
        ),
        const SizedBox(height: MemoraSpacing.space4),
        Text(
          subtitle,
          style: MemoraTypography.metadata.copyWith(
            color: MemoraColors.textMuted,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space16,
        vertical: MemoraSpacing.space12,
      ),
      child: Row(
        children: nodeSide == MemoraPathNodeSide.left
            ? <Widget>[
                giftWidget,
                const SizedBox(width: MemoraSpacing.space16),
                Expanded(child: textWidget),
              ]
            : <Widget>[
                Expanded(child: textWidget),
                const SizedBox(width: MemoraSpacing.space16),
                giftWidget,
              ],
      ),
    );
  }
}

/// A connecting path line (straight or curved) between nodes on a level map.
class MemoraPathConnector extends StatelessWidget {
  const MemoraPathConnector({
    super.key,
    this.isCompleted = false,
    this.length = 40.0,
  });

  final bool isCompleted;
  final double length;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 6,
        height: length,
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFFD4EBFB)
              : MemoraColors.borderDefault.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(MemoraRadii.pillValue),
        ),
      ),
    );
  }
}

/// A milestone card dividing units or chapters along the learning path.
class MemoraPathMilestoneCard extends StatelessWidget {
  const MemoraPathMilestoneCard({
    super.key,
    required this.unitNumber,
    required this.title,
    required this.conceptsCount,
    this.progress = 0.0,
    this.onTap,
  });

  final int unitNumber;
  final String title;
  final int conceptsCount;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: onTap != null,
      label:
          'Unit $unitNumber: $title, $conceptsCount concepts, ${(progress * 100).toInt()}% complete',
      child: Material(
        color: MemoraColors.surfaceCanvas,
        borderRadius: MemoraRadii.primaryCard,
        child: InkWell(
          onTap: onTap,
          borderRadius: MemoraRadii.primaryCard,
          child: Container(
            padding: const EdgeInsets.all(MemoraSpacing.space16),
            decoration: BoxDecoration(
              borderRadius: MemoraRadii.primaryCard,
              border: Border.all(color: MemoraColors.borderDefault),
              boxShadow: MemoraElevations.cardShadows,
            ),
            child: Row(
              children: <Widget>[
                // Unit badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: MemoraColors.brandGradient,
                    borderRadius: MemoraRadii.chip,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'U$unitNumber',
                    style: const TextStyle(
                      fontFamily: 'Exo',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: MemoraColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: MemoraSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style: MemoraTypography.cardTitle.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: MemoraSpacing.space4),
                      Text(
                        '$conceptsCount concepts • ${(progress * 100).toInt()}% complete',
                        style: MemoraTypography.metadata.copyWith(
                          color: MemoraColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: MemoraSpacing.space8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          MemoraRadii.pillValue,
                        ),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: MemoraColors.borderDefault
                              .withValues(alpha: 0.35),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            MemoraColors.brandPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
