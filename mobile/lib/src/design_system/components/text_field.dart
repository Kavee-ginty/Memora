import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class MemoraTextField extends StatefulWidget {
  const MemoraTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.helperText,
    this.successText,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final String? helperText;
  final String? successText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;

  @override
  State<MemoraTextField> createState() => _MemoraTextFieldState();
}

class _MemoraTextFieldState extends State<MemoraTextField> {
  late FocusNode _focusNode;
  bool _isSelfFocusNode = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _isSelfFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_isSelfFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final bool hasSuccess = widget.successText != null && widget.successText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Persistent label above the field
        Semantics(
          label: widget.label,
          child: Text(
            widget.label,
            style: MemoraTypography.bodyStrong.copyWith(
              fontSize: 14,
              color: widget.enabled ? MemoraColors.textPrimary : MemoraColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: MemoraSpacing.space8),
        // Input container
        Container(
          constraints: const BoxConstraints(minHeight: MemoraSpacing.minTouchTarget),
          decoration: BoxDecoration(
            color: widget.enabled ? MemoraColors.surfaceOcean : MemoraColors.surfaceSoft,
            borderRadius: MemoraRadii.control,
            border: Border.all(
              color: hasError
                  ? MemoraColors.feedbackCritical
                  : (_isFocused ? MemoraColors.focus : MemoraColors.borderDefault),
              width: hasError || _isFocused ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: <Widget>[
              if (widget.prefixIcon != null) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: MemoraSpacing.space16),
                  child: IconTheme(
                    data: const IconThemeData(color: MemoraColors.brandBlue, size: 20),
                    child: widget.prefixIcon!,
                  ),
                ),
              ],
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  initialValue: widget.initialValue,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  obscureText: widget.obscureText,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  autofocus: widget.autofocus,
                  maxLines: widget.maxLines,
                  onChanged: widget.onChanged,
                  onFieldSubmitted: widget.onSubmitted,
                  validator: widget.validator,
                  style: MemoraTypography.body.copyWith(
                    color: widget.enabled ? MemoraColors.textPrimary : MemoraColors.textMuted,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: MemoraSpacing.space16,
                      vertical: MemoraSpacing.space12,
                    ),
                  ),
                ),
              ),
              if (widget.suffixIcon != null) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: MemoraSpacing.space8),
                  child: widget.suffixIcon!,
                ),
              ],
            ],
          ),
        ),
        // Validation / helper text below the field
        if (hasError) ...<Widget>[
          const SizedBox(height: MemoraSpacing.space4),
          Semantics(
            liveRegion: true,
            child: Row(
              children: <Widget>[
                const Icon(Icons.error_outline, color: MemoraColors.feedbackCritical, size: 16),
                const SizedBox(width: MemoraSpacing.space4),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: MemoraTypography.metadata.copyWith(color: MemoraColors.feedbackCritical),
                  ),
                ),
              ],
            ),
          ),
        ] else if (hasSuccess) ...<Widget>[
          const SizedBox(height: MemoraSpacing.space4),
          Semantics(
            liveRegion: true,
            child: Row(
              children: <Widget>[
                const Icon(Icons.check_circle_outline, color: MemoraColors.feedbackPositive, size: 16),
                const SizedBox(width: MemoraSpacing.space4),
                Expanded(
                  child: Text(
                    widget.successText!,
                    style: MemoraTypography.metadata.copyWith(color: MemoraColors.feedbackPositive),
                  ),
                ),
              ],
            ),
          ),
        ] else if (widget.helperText != null) ...<Widget>[
          const SizedBox(height: MemoraSpacing.space4),
          Text(widget.helperText!, style: MemoraTypography.metadata.copyWith(color: MemoraColors.textMuted)),
        ],
      ],
    );
  }
}
