import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

enum MemoraButtonVariant { primary, secondary, tertiary, destructive }

class MemoraButton extends StatefulWidget {
  const MemoraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MemoraButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final MemoraButtonVariant variant;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final String? semanticLabel;

  @override
  State<MemoraButton> createState() => _MemoraButtonState();
}

class _MemoraButtonState extends State<MemoraButton> {
  bool _isFocused = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double minHeight = (MemoraSpacing.minTouchTarget * (textScale > 1.2 ? textScale * 0.9 : 1.0)).clamp(
      MemoraSpacing.minTouchTarget,
      120.0,
    );

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.isLoading) ...<Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_loadingIndicatorColor),
            ),
          ),
          const SizedBox(width: MemoraSpacing.space8),
        ] else if (widget.icon != null) ...<Widget>[
          IconTheme(
            data: IconThemeData(size: 20, color: _textColor),
            child: widget.icon!,
          ),
          const SizedBox(width: MemoraSpacing.space8),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: MemoraTypography.button.copyWith(color: _textColor),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        if (widget.trailingIcon != null && !widget.isLoading) ...<Widget>[
          const SizedBox(width: MemoraSpacing.space8),
          IconTheme(
            data: IconThemeData(size: 20, color: _textColor),
            child: widget.trailingIcon!,
          ),
        ],
      ],
    );

    final BoxDecoration decoration = _buildDecoration();

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.semanticLabel ?? (widget.isLoading ? '${widget.label}, loading' : widget.label),
      child: Focus(
        onFocusChange: (bool focused) {
          setState(() {
            _isFocused = focused;
          });
        },
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          constraints: BoxConstraints(minHeight: minHeight, minWidth: MemoraSpacing.minTouchTarget),
          decoration: _isFocused
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(MemoraRadii.controlValue + 2),
                  border: Border.all(color: MemoraColors.focus, width: 2.0),
                )
              : null,
          padding: _isFocused ? const EdgeInsets.all(2.0) : EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            borderRadius: MemoraRadii.control,
            child: Ink(
              decoration: decoration,
              child: InkWell(
                onTap: _isEnabled ? widget.onPressed : null,
                borderRadius: MemoraRadii.control,
                splashColor: _splashColor,
                highlightColor: _highlightColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraSpacing.space16,
                    vertical: MemoraSpacing.space12,
                  ),
                  child: ExcludeSemantics(child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _textColor {
    if (!_isEnabled && widget.variant != MemoraButtonVariant.primary) {
      return MemoraColors.textMuted;
    }
    switch (widget.variant) {
      case MemoraButtonVariant.primary:
        return _isEnabled ? MemoraColors.textPrimary : MemoraColors.textPrimary.withValues(alpha: 0.5);
      case MemoraButtonVariant.secondary:
        return MemoraColors.textPrimary;
      case MemoraButtonVariant.tertiary:
        return MemoraColors.brandBlue;
      case MemoraButtonVariant.destructive:
        return MemoraColors.feedbackCritical;
    }
  }

  Color get _loadingIndicatorColor {
    switch (widget.variant) {
      case MemoraButtonVariant.primary:
        return MemoraColors.textPrimary;
      case MemoraButtonVariant.secondary:
      case MemoraButtonVariant.tertiary:
        return MemoraColors.brandBlue;
      case MemoraButtonVariant.destructive:
        return MemoraColors.feedbackCritical;
    }
  }

  Color get _splashColor {
    switch (widget.variant) {
      case MemoraButtonVariant.primary:
        return Colors.white.withValues(alpha: 0.3);
      case MemoraButtonVariant.secondary:
      case MemoraButtonVariant.tertiary:
        return MemoraColors.brandBlue.withValues(alpha: 0.12);
      case MemoraButtonVariant.destructive:
        return MemoraColors.feedbackCritical.withValues(alpha: 0.12);
    }
  }

  Color get _highlightColor {
    switch (widget.variant) {
      case MemoraButtonVariant.primary:
        return Colors.white.withValues(alpha: 0.2);
      case MemoraButtonVariant.secondary:
      case MemoraButtonVariant.tertiary:
        return MemoraColors.brandBlue.withValues(alpha: 0.08);
      case MemoraButtonVariant.destructive:
        return MemoraColors.feedbackCritical.withValues(alpha: 0.08);
    }
  }

  BoxDecoration _buildDecoration() {
    final double opacity = _isEnabled ? 1.0 : 0.5;

    switch (widget.variant) {
      case MemoraButtonVariant.primary:
        return BoxDecoration(
          gradient: _isEnabled
              ? MemoraColors.brandGradient
              : LinearGradient(
                  colors: <Color>[
                    MemoraColors.brandPrimary.withValues(alpha: opacity),
                    MemoraColors.brandAqua.withValues(alpha: opacity),
                  ],
                ),
          borderRadius: MemoraRadii.control,
          boxShadow: _isEnabled
              ? const <BoxShadow>[BoxShadow(color: Color(0x1F00AFFF), blurRadius: 8, offset: Offset(0, 3))]
              : null,
        );

      case MemoraButtonVariant.secondary:
        return BoxDecoration(
          color: MemoraColors.surfaceCanvas.withValues(alpha: opacity),
          borderRadius: MemoraRadii.control,
          border: Border.all(color: _isEnabled ? MemoraColors.brandBlue : MemoraColors.borderDefault, width: 1.5),
        );

      case MemoraButtonVariant.tertiary:
        return const BoxDecoration(color: Colors.transparent, borderRadius: MemoraRadii.control);

      case MemoraButtonVariant.destructive:
        return BoxDecoration(
          color: const Color(0xFFFDE8E8).withValues(alpha: opacity),
          borderRadius: MemoraRadii.control,
          border: Border.all(
            color: _isEnabled ? MemoraColors.feedbackCritical : MemoraColors.borderDefault,
            width: 1.0,
          ),
        );
    }
  }
}
