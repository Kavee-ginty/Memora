import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Screen representing the full Learning Path experience shown in Everyday English learning path.png.
class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key, this.onStartMission});

  final VoidCallback? onStartMission;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoraSpacing.space16,
        vertical: MemoraSpacing.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. Top Learning Path Overview Card
          const MemoraLearningPathHeader(
            title: 'Everyday English',
            completedCount: 6,
            totalCount: 10,
            subtitle: 'Your learning path',
          ),
          const SizedBox(height: MemoraSpacing.space16),

          // 2. Milestone Pill
          const MemoraMilestonePill(text: 'Quiz 1–4 completed'),
          const SizedBox(height: MemoraSpacing.space12),

          // 3. Node 5 (Right side node, left text)
          const MemoraWindingPathRow(
            stepNumber: 5,
            title: 'Daily routines',
            subtitle: 'Ready for real life',
            state: MemoraPathNodeState.completed,
            nodeSide: MemoraPathNodeSide.right,
          ),

          // 4. Node 6 (Left side node, right text)
          const MemoraWindingPathRow(
            stepNumber: 6,
            title: 'At the shops',
            subtitle: 'Completed',
            state: MemoraPathNodeState.completed,
            nodeSide: MemoraPathNodeSide.left,
          ),

          // 5. Active Mission Node with Mora & Start Quiz CTA
          MemoraPathActiveCard(
            title: 'At the café',
            subtitle: 'Lesson 7 · 5 min · +20 XP',
            speechBubbleText: 'You\'re making waves!',
            badgeText: 'YOU ARE HERE',
            buttonLabel: 'Start Quiz',
            mascotAsset: 'assets/mascot/teaching.png',
            onStart: onStartMission ?? () {},
          ),

          // 6. Node 8 (Locked node on right side)
          const MemoraWindingPathRow(
            stepNumber: 8,
            title: 'Getting around',
            subtitle: 'Complete Quiz 7',
            state: MemoraPathNodeState.locked,
            nodeSide: MemoraPathNodeSide.right,
          ),

          // 7. Reward Box Node (+50 XP reward on left side)
          const MemoraPathRewardRow(
            title: '+50 XP reward',
            subtitle: 'Finish Quiz 8 to unlock',
            nodeSide: MemoraPathNodeSide.left,
          ),
          const SizedBox(height: MemoraSpacing.space24),
        ],
      ),
    );
  }
}
