import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum MemoraBannerVariant { info, attention, critical, offline, positive }

class MemoraBanner extends StatelessWidget {
  const MemoraBanner({
    super.key,
    required this.message,
    this.title,
    this.variant = MemoraBannerVariant.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final String message;
  final String? title;
  final MemoraBannerVariant variant;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: MemoraSpacing.space8),
        padding: const EdgeInsets.all(MemoraSpacing.space16),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: MemoraRadii.compactCard,
          border: Border.all(color: _borderColor, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(_icon, color: _iconColor, size: 22),
            const SizedBox(width: MemoraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (title != null) ...<Widget>[
                    Text(title!, style: MemoraTypography.cardTitle.copyWith(color: _titleColor)),
                    const SizedBox(height: MemoraSpacing.space4),
                  ],
                  Text(message, style: MemoraTypography.body.copyWith(fontSize: 14, color: MemoraColors.textPrimary)),
                  if (actionLabel != null && onAction != null) ...<Widget>[
                    const SizedBox(height: MemoraSpacing.space8),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 36),
                        foregroundColor: _iconColor,
                        textStyle: MemoraTypography.button.copyWith(fontSize: 14),
                      ),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null) ...<Widget>[
              const SizedBox(width: MemoraSpacing.space8),
              Semantics(
                button: true,
                label: 'Dismiss banner',
                child: IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 20),
                  color: MemoraColors.textMuted,
                  tooltip: 'Dismiss',
                  constraints: const BoxConstraints(
                    minWidth: MemoraSpacing.minTouchTarget,
                    minHeight: MemoraSpacing.minTouchTarget,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    switch (variant) {
      case MemoraBannerVariant.info:
        return Icons.info_outline;
      case MemoraBannerVariant.attention:
        return Icons.warning_amber_rounded;
      case MemoraBannerVariant.critical:
        return Icons.error_outline;
      case MemoraBannerVariant.offline:
        return Icons.wifi_off_rounded;
      case MemoraBannerVariant.positive:
        return Icons.check_circle_outline;
    }
  }

  Color get _iconColor {
    switch (variant) {
      case MemoraBannerVariant.info:
        return MemoraColors.brandBlue;
      case MemoraBannerVariant.attention:
        return MemoraColors.feedbackAttention;
      case MemoraBannerVariant.critical:
        return MemoraColors.feedbackCritical;
      case MemoraBannerVariant.offline:
        return MemoraColors.textSecondary;
      case MemoraBannerVariant.positive:
        return MemoraColors.feedbackPositive;
    }
  }

  Color get _titleColor {
    return _iconColor;
  }

  Color get _backgroundColor {
    switch (variant) {
      case MemoraBannerVariant.info:
        return MemoraColors.surfaceOcean;
      case MemoraBannerVariant.attention:
        return const Color(0xFFFFF8E7);
      case MemoraBannerVariant.critical:
        return const Color(0xFFFDE8E8);
      case MemoraBannerVariant.offline:
        return MemoraColors.surfaceSoft;
      case MemoraBannerVariant.positive:
        return MemoraColors.surfaceMint;
    }
  }

  Color get _borderColor {
    switch (variant) {
      case MemoraBannerVariant.info:
        return MemoraColors.borderDefault;
      case MemoraBannerVariant.attention:
        return const Color(0xFFFFD591);
      case MemoraBannerVariant.critical:
        return const Color(0xFFFCA5A5);
      case MemoraBannerVariant.offline:
        return MemoraColors.borderDefault;
      case MemoraBannerVariant.positive:
        return const Color(0xFFB7EB8F);
    }
  }
}
