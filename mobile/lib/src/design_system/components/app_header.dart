import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum MemoraHeaderVariant { root, detail, mission }

class MemoraHeader extends StatelessWidget implements PreferredSizeWidget {
  const MemoraHeader.root({
    super.key,
    this.title = 'Memora',
    this.streakDays,
    this.onMenuPressed,
    this.onProfilePressed,
    this.bottom,
    this.headingOnTitle = false,
  }) : variant = MemoraHeaderVariant.root,
       subtitle = null,
       onBackPressed = null,
       contextualAction = null,
       missionProgressText = null,
       timerText = null,
       onTimerToggle = null,
       onPauseMission = null;

  const MemoraHeader.detail({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBackPressed,
    this.contextualAction,
    this.bottom,
  }) : variant = MemoraHeaderVariant.detail,
       headingOnTitle = false,
       streakDays = null,
       onMenuPressed = null,
       onProfilePressed = null,
       missionProgressText = null,
       timerText = null,
       onTimerToggle = null,
       onPauseMission = null;

  const MemoraHeader.mission({
    super.key,
    required this.missionProgressText,
    required this.onPauseMission,
    this.timerText,
    this.onTimerToggle,
    this.bottom,
  }) : variant = MemoraHeaderVariant.mission,
       headingOnTitle = false,
       title = 'Mission',
       subtitle = null,
       streakDays = null,
       onBackPressed = null,
       onMenuPressed = null,
       onProfilePressed = null,
       contextualAction = null;

  final MemoraHeaderVariant variant;
  final String title;
  final String? subtitle;
  final int? streakDays;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onBackPressed;
  final Widget? contextualAction;
  final String? missionProgressText;
  final String? timerText;
  final VoidCallback? onTimerToggle;
  final VoidCallback? onPauseMission;
  final PreferredSizeWidget? bottom;
  final bool headingOnTitle;

  @override
  Size get preferredSize {
    final double height;
    switch (variant) {
      case MemoraHeaderVariant.root:
        height = 116.0;
      case MemoraHeaderVariant.detail:
        height = subtitle != null ? 80.0 : 68.0;
      case MemoraHeaderVariant.mission:
        height = 72.0;
    }
    return Size.fromHeight(height + (bottom?.preferredSize.height ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: !headingOnTitle,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: MemoraColors.surfaceOcean,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(MemoraRadii.primaryCardValue),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x0A0B1A2C),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space16,
            vertical: MemoraSpacing.space8,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[_buildVariantContent(context), ?bottom],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantContent(BuildContext context) {
    switch (variant) {
      case MemoraHeaderVariant.root:
        return _buildRootHeader(context);
      case MemoraHeaderVariant.detail:
        return _buildDetailHeader(context);
      case MemoraHeaderVariant.mission:
        return _buildMissionHeader(context);
    }
  }

  Widget _buildRootHeader(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Top row: Avatar & Brand
        Row(
          children: <Widget>[
            Semantics(
              button: onProfilePressed != null,
              label: 'Profile',
              child: InkWell(
                onTap: onProfilePressed,
                borderRadius: BorderRadius.circular(
                  MemoraSpacing.minTouchTarget / 2,
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: MemoraSpacing.minTouchTarget,
                    minHeight: MemoraSpacing.minTouchTarget,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MemoraColors.brandBlue,
                        width: 2.0,
                      ),
                      color: MemoraColors.surfaceCanvas,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: MemoraColors.brandBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: MemoraSpacing.space12),
            Expanded(
              child: Semantics(
                header: headingOnTitle ? true : null,
                child: Text(
                  title,
                  style: MemoraTypography.pageTitle.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: MediaQuery.highContrastOf(context)
                        ? Colors.black
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MemoraSpacing.space8),
        // Secondary row: Menu affordance & Streak badge
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: MemoraSpacing.space4,
          children: <Widget>[
            Semantics(
              button: true,
              label: 'Menu',
              child: InkWell(
                onTap: onMenuPressed,
                borderRadius: BorderRadius.circular(MemoraRadii.chipValue),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: MemoraSpacing.minTouchTarget,
                    minWidth: MemoraSpacing.minTouchTarget,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraSpacing.space8,
                    vertical: MemoraSpacing.space8,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.menu,
                        size: 22,
                        color: MemoraColors.brandPrimary,
                      ),
                      SizedBox(width: MemoraSpacing.space8),
                      Text('Menu', style: MemoraTypography.button),
                    ],
                  ),
                ),
              ),
            ),
            if (streakDays != null)
              Semantics(
                label: '$streakDays days streak secured',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraSpacing.space12,
                    vertical: MemoraSpacing.space4,
                  ),
                  decoration: BoxDecoration(
                    color: MemoraColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(MemoraRadii.pillValue),
                    border: Border.all(color: MemoraColors.borderDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.local_fire_department,
                        size: 20,
                        color: MemoraColors.brandBlue,
                      ),
                      const SizedBox(width: MemoraSpacing.space4),
                      Text(
                        '$streakDays days',
                        style: MemoraTypography.bodyStrong.copyWith(
                          fontSize: 14,
                          color: MemoraColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailHeader(BuildContext context) {
    return Row(
      children: <Widget>[
        Semantics(
          button: true,
          label: 'Go back',
          child: IconButton(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back),
            color: MemoraColors.textPrimary,
            tooltip: 'Go back',
            constraints: const BoxConstraints(
              minWidth: MemoraSpacing.minTouchTarget,
              minHeight: MemoraSpacing.minTouchTarget,
            ),
          ),
        ),
        const SizedBox(width: MemoraSpacing.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: MemoraTypography.sectionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: MemoraSpacing.space4),
                Text(
                  subtitle!,
                  style: MemoraTypography.metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        ?contextualAction,
      ],
    );
  }

  Widget _buildMissionHeader(BuildContext context) {
    return Row(
      children: <Widget>[
        Semantics(
          button: true,
          label: 'Pause and exit mission',
          child: IconButton(
            onPressed: onPauseMission,
            icon: const Icon(Icons.close),
            color: MemoraColors.textPrimary,
            tooltip: 'Pause and exit',
            constraints: const BoxConstraints(
              minWidth: MemoraSpacing.minTouchTarget,
              minHeight: MemoraSpacing.minTouchTarget,
            ),
          ),
        ),
        const SizedBox(width: MemoraSpacing.space8),
        Expanded(
          child: Text(
            missionProgressText ?? 'Daily Mission',
            style: MemoraTypography.sectionTitle.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        if (timerText != null)
          Semantics(
            label: 'Elapsed time: $timerText',
            child: InkWell(
              onTap: onTimerToggle,
              borderRadius: BorderRadius.circular(MemoraRadii.chipValue),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: MemoraSpacing.minTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: MemoraSpacing.space8,
                  vertical: MemoraSpacing.space4,
                ),
                decoration: BoxDecoration(
                  color: MemoraColors.brandAqua.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(MemoraRadii.chipValue),
                ),
                child: Center(
                  child: Text(
                    timerText!,
                    style: MemoraTypography.metadata.copyWith(
                      fontWeight: FontWeight.w700,
                      color: MemoraColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const SizedBox(width: MemoraSpacing.minTouchTarget),
      ],
    );
  }
}
