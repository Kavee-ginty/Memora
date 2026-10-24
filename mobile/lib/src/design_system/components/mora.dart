import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum MoraState { guide, encourage, celebrate, think, rest }

class MoraPlacement extends StatelessWidget {
  const MoraPlacement({
    super.key,
    required this.state,
    this.size = 80.0,
    this.speechBubbleText,
    this.isDecorative = true,
    this.semanticLabel,
  });

  final MoraState state;
  final double size;
  final String? speechBubbleText;
  final bool isDecorative;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = _buildMoraAvatar(context);

    Widget content = avatar;

    if (speechBubbleText != null && speechBubbleText!.isNotEmpty) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          avatar,
          const SizedBox(width: MemoraSpacing.space12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: MemoraSpacing.space16, vertical: MemoraSpacing.space12),
              decoration: BoxDecoration(
                color: MemoraColors.surfaceCanvas,
                borderRadius: MemoraRadii.compactCard,
                border: Border.all(color: MemoraColors.borderDefault),
                boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x0A0B1A2C), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Text(
                speechBubbleText!,
                style: MemoraTypography.body.copyWith(fontSize: 14, color: MemoraColors.textPrimary),
              ),
            ),
          ),
        ],
      );
    }

    if (isDecorative) {
      return ExcludeSemantics(child: content);
    }

    final String label = semanticLabel ?? _defaultSemanticLabel;
    return Semantics(
      label: speechBubbleText != null ? '$label. Mora says: $speechBubbleText' : label,
      child: ExcludeSemantics(child: content),
    );
  }

  String get _defaultSemanticLabel {
    switch (state) {
      case MoraState.guide:
        return 'Mora the guide with a notebook';
      case MoraState.encourage:
        return 'Mora smiling encouragingly';
      case MoraState.celebrate:
        return 'Mora celebrating joyfully';
      case MoraState.think:
        return 'Mora thinking and analyzing';
      case MoraState.rest:
        return 'Mora resting';
    }
  }

  Widget _buildMoraAvatar(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: MemoraColors.surfaceOcean,
        shape: BoxShape.circle,
        border: Border.all(color: _stateBorderColor, width: 2.0),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x1200AFFF), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Base shark icon representation
          Icon(_stateMainIcon, size: size * 0.55, color: MemoraColors.brandPrimary),
          // Badge in corner for specific state
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _stateBadgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: MemoraColors.surfaceCanvas, width: 1.5),
              ),
              child: Icon(_stateBadgeIcon, size: size * 0.22, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _stateMainIcon {
    switch (state) {
      case MoraState.guide:
        return Icons.school_rounded;
      case MoraState.encourage:
        return Icons.mood_rounded;
      case MoraState.celebrate:
        return Icons.celebration_rounded;
      case MoraState.think:
        return Icons.psychology_rounded;
      case MoraState.rest:
        return Icons.nightlight_round;
    }
  }

  IconData get _stateBadgeIcon {
    switch (state) {
      case MoraState.guide:
        return Icons.auto_stories;
      case MoraState.encourage:
        return Icons.thumb_up_alt_rounded;
      case MoraState.celebrate:
        return Icons.star_rounded;
      case MoraState.think:
        return Icons.lightbulb_outline_rounded;
      case MoraState.rest:
        return Icons.bedtime_outlined;
    }
  }

  Color get _stateBorderColor {
    switch (state) {
      case MoraState.guide:
      case MoraState.encourage:
        return MemoraColors.brandPrimary;
      case MoraState.celebrate:
        return MemoraColors.brandAqua;
      case MoraState.think:
        return MemoraColors.brandBlue;
      case MoraState.rest:
        return MemoraColors.borderDefault;
    }
  }

  Color get _stateBadgeColor {
    switch (state) {
      case MoraState.guide:
        return MemoraColors.brandBlue;
      case MoraState.encourage:
        return MemoraColors.feedbackPositive;
      case MoraState.celebrate:
        return const Color(0xFFFAAD14);
      case MoraState.think:
        return MemoraColors.brandPrimary;
      case MoraState.rest:
        return MemoraColors.textMuted;
    }
  }
}
