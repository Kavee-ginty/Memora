import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// The canonical visual states of Mora the mascot guardian.
enum MoraState { guide, encourage, celebrate, think, rest, happy, sad, crying }

/// A responsive, accessible mascot component rendering transparent mascot illustrations.
///
/// Complies with UIX-002, UIX-006, and UIX-031 (decorative art uses empty alternative text).
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

  /// Returns the asset path for the transparent mascot PNG corresponding to this state.
  String get assetPath {
    switch (state) {
      case MoraState.guide:
        return 'assets/mascot/teaching.png';
      case MoraState.encourage:
        return 'assets/mascot/encouraging.png';
      case MoraState.celebrate:
        return 'assets/mascot/celebrating.png';
      case MoraState.think:
        return 'assets/mascot/questioning.png';
      case MoraState.rest:
        return 'assets/mascot/sleeping.png';
      case MoraState.happy:
        return 'assets/mascot/happy.png';
      case MoraState.sad:
        return 'assets/mascot/sad.png';
      case MoraState.crying:
        return 'assets/mascot/crying.png';
    }
  }

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
              padding: const EdgeInsets.symmetric(
                horizontal: MemoraSpacing.space16,
                vertical: MemoraSpacing.space12,
              ),
              decoration: BoxDecoration(
                color: MemoraColors.surfaceCanvas,
                borderRadius: MemoraRadii.compactCard,
                border: Border.all(color: MemoraColors.borderDefault),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0A0B1A2C),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                speechBubbleText!,
                style: MemoraTypography.body.copyWith(
                  fontSize: 14,
                  color: MemoraColors.textPrimary,
                ),
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
      label: speechBubbleText != null
          ? '$label. Mora says: $speechBubbleText'
          : label,
      child: ExcludeSemantics(child: content),
    );
  }

  String get _defaultSemanticLabel {
    switch (state) {
      case MoraState.guide:
        return 'Mora guiding and teaching';
      case MoraState.encourage:
        return 'Mora smiling encouragingly';
      case MoraState.celebrate:
        return 'Mora celebrating joyfully';
      case MoraState.think:
        return 'Mora thinking and questioning';
      case MoraState.rest:
        return 'Mora resting peacefully';
      case MoraState.happy:
        return 'Mora looking happy and cheerful';
      case MoraState.sad:
        return 'Mora looking sympathetic';
      case MoraState.crying:
        return 'Mora feeling upset';
    }
  }

  Widget _buildMoraAvatar(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: MemoraColors.surfaceOcean,
                  shape: BoxShape.circle,
                  border: Border.all(color: MemoraColors.brandPrimary),
                ),
                child: Icon(
                  Icons.pets_rounded,
                  size: size * 0.5,
                  color: MemoraColors.brandPrimary,
                ),
              );
            },
      ),
    );
  }
}
