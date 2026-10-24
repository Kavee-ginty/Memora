import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/elevations.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum MemoraCardVariant { primary, compact }

class MemoraCard extends StatelessWidget {
  const MemoraCard({
    super.key,
    required this.child,
    this.variant = MemoraCardVariant.primary,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final MemoraCardVariant variant;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = variant == MemoraCardVariant.primary
        ? MemoraRadii.primaryCard
        : MemoraRadii.compactCard;

    final EdgeInsetsGeometry effectivePadding =
        padding ?? EdgeInsets.all(variant == MemoraCardVariant.primary ? MemoraSpacing.space24 : MemoraSpacing.space16);

    final Widget cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? MemoraColors.surfaceOcean,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? MemoraColors.borderDefault, width: 1.0),
        boxShadow: MemoraElevations.cardShadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: Padding(padding: effectivePadding, child: child),
              )
            : Padding(padding: effectivePadding, child: child),
      ),
    );

    if (semanticLabel != null) {
      return Semantics(label: semanticLabel, container: true, child: cardContent);
    }

    return cardContent;
  }
}

class MemoraProgressCard extends StatelessWidget {
  const MemoraProgressCard({
    super.key,
    required this.title,
    required this.statusText,
    required this.progress,
    this.metricText,
    this.subtitle,
    this.icon,
    this.onTap,
  });

  final String title;
  final String statusText;
  final double progress; // 0.0 to 1.0
  final String? metricText;
  final String? subtitle;
  final Widget? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final String percentText = metricText ?? '${(clampedProgress * 100).round()}%';

    return Semantics(
      label: '$title. $statusText. $percentText complete.',
      value: percentText,
      child: MemoraCard(
        variant: MemoraCardVariant.primary,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null || subtitle != null) ...<Widget>[
                Row(
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      IconTheme(
                        data: const IconThemeData(size: 20, color: MemoraColors.brandBlue),
                        child: icon!,
                      ),
                      const SizedBox(width: MemoraSpacing.space8),
                    ],
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: MemoraTypography.metadata.copyWith(
                            color: MemoraColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: MemoraSpacing.space8),
              ],
              Text(title, style: MemoraTypography.pageTitle.copyWith(fontSize: 22, height: 30 / 22)),
              const SizedBox(height: MemoraSpacing.space8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(child: Text(statusText, style: MemoraTypography.metadata)),
                  const SizedBox(width: MemoraSpacing.space8),
                  Text(
                    percentText,
                    style: MemoraTypography.metadata.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MemoraColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MemoraSpacing.space8),
              ClipRRect(
                borderRadius: BorderRadius.circular(MemoraSpacing.space4),
                child: LinearProgressIndicator(
                  value: clampedProgress,
                  minHeight: 8,
                  backgroundColor: MemoraColors.borderDefault.withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(MemoraColors.brandPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemoraSelectableCard extends StatelessWidget {
  const MemoraSelectableCard({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.leading,
    this.progress,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      label: '$title${subtitle != null ? ', $subtitle' : ''}',
      child: MemoraCard(
        variant: MemoraCardVariant.compact,
        backgroundColor: isSelected ? MemoraColors.controlSelected : MemoraColors.surfaceSoft,
        borderColor: isSelected ? MemoraColors.brandPrimary : MemoraColors.borderDefault,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: MemoraSpacing.space16, vertical: MemoraSpacing.space16),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (leading != null) ...<Widget>[leading!, const SizedBox(width: MemoraSpacing.space12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(title, style: MemoraTypography.cardTitle),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: MemoraSpacing.space4),
                          Text(subtitle!, style: MemoraTypography.metadata),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: MemoraSpacing.space8),
                    trailing!,
                  ] else ...<Widget>[
                    const SizedBox(width: MemoraSpacing.space8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? MemoraColors.brandPrimary : MemoraColors.borderDefault,
                          width: isSelected ? 6.0 : 2.0,
                        ),
                        color: isSelected ? MemoraColors.surfaceCanvas : Colors.transparent,
                      ),
                    ),
                  ],
                ],
              ),
              if (progress != null) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(MemoraSpacing.space4),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: MemoraColors.borderDefault.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(MemoraColors.brandPrimary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
