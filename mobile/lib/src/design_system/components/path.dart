import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/elevations.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// The 5 canonical node states on a learning path map.
///
/// Derived from Section 9.8 of Memora_UI_UX_Design_Specification.md.
enum MemoraPathNodeState { completed, current, available, locked, needsReview }

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
        nodeBg = MemoraColors.surfaceMint;
        nodeBorder = MemoraColors.feedbackPositive;
        iconColor = MemoraColors.feedbackPositive;
        icon = Icons.check;
        break;
      case MemoraPathNodeState.current:
        nodeBg = MemoraColors.brandPrimary;
        nodeBorder = MemoraColors.brandAqua;
        iconColor = MemoraColors.textPrimary;
        icon = Icons.play_arrow_rounded;
        break;
      case MemoraPathNodeState.available:
        nodeBg = MemoraColors.surfaceCanvas;
        nodeBorder = MemoraColors.brandPrimary;
        iconColor = MemoraColors.focus;
        icon = Icons.star_border_rounded;
        break;
      case MemoraPathNodeState.locked:
        nodeBg = MemoraColors.surfaceSoft;
        nodeBorder = MemoraColors.borderDefault;
        iconColor = MemoraColors.textMuted;
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
        width: 4,
        height: length,
        decoration: BoxDecoration(
          color: isCompleted
              ? MemoraColors.brandPrimary
              : MemoraColors.borderDefault.withValues(alpha: 0.6),
          borderRadius: MemoraRadii.pill,
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
                        borderRadius: MemoraRadii.pill,
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
