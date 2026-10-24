import 'package:flutter/material.dart';

import '../tokens/colors.dart';

@immutable
class MemoraColorTokens extends ThemeExtension<MemoraColorTokens> {
  const MemoraColorTokens({
    required this.brandPrimary,
    required this.brandAqua,
    required this.brandBlue,
    required this.surfaceCanvas,
    required this.surfaceSoft,
    required this.surfaceOcean,
    required this.surfaceMint,
    required this.surfaceLilac,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderDefault,
    required this.controlRest,
    required this.controlSelected,
    required this.feedbackPositive,
    required this.feedbackAttention,
    required this.feedbackCritical,
    required this.focus,
    required this.brandGradient,
  });

  final Color brandPrimary;
  final Color brandAqua;
  final Color brandBlue;
  final Color surfaceCanvas;
  final Color surfaceSoft;
  final Color surfaceOcean;
  final Color surfaceMint;
  final Color surfaceLilac;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderDefault;
  final Color controlRest;
  final Color controlSelected;
  final Color feedbackPositive;
  final Color feedbackAttention;
  final Color feedbackCritical;
  final Color focus;
  final LinearGradient brandGradient;

  static const MemoraColorTokens light = MemoraColorTokens(
    brandPrimary: MemoraColors.brandPrimary,
    brandAqua: MemoraColors.brandAqua,
    brandBlue: MemoraColors.brandBlue,
    surfaceCanvas: MemoraColors.surfaceCanvas,
    surfaceSoft: MemoraColors.surfaceSoft,
    surfaceOcean: MemoraColors.surfaceOcean,
    surfaceMint: MemoraColors.surfaceMint,
    surfaceLilac: MemoraColors.surfaceLilac,
    textPrimary: MemoraColors.textPrimary,
    textSecondary: MemoraColors.textSecondary,
    textMuted: MemoraColors.textMuted,
    borderDefault: MemoraColors.borderDefault,
    controlRest: MemoraColors.controlRest,
    controlSelected: MemoraColors.controlSelected,
    feedbackPositive: MemoraColors.feedbackPositive,
    feedbackAttention: MemoraColors.feedbackAttention,
    feedbackCritical: MemoraColors.feedbackCritical,
    focus: MemoraColors.focus,
    brandGradient: MemoraColors.brandGradient,
  );

  @override
  ThemeExtension<MemoraColorTokens> copyWith({
    Color? brandPrimary,
    Color? brandAqua,
    Color? brandBlue,
    Color? surfaceCanvas,
    Color? surfaceSoft,
    Color? surfaceOcean,
    Color? surfaceMint,
    Color? surfaceLilac,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? borderDefault,
    Color? controlRest,
    Color? controlSelected,
    Color? feedbackPositive,
    Color? feedbackAttention,
    Color? feedbackCritical,
    Color? focus,
    LinearGradient? brandGradient,
  }) {
    return MemoraColorTokens(
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandAqua: brandAqua ?? this.brandAqua,
      brandBlue: brandBlue ?? this.brandBlue,
      surfaceCanvas: surfaceCanvas ?? this.surfaceCanvas,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceOcean: surfaceOcean ?? this.surfaceOcean,
      surfaceMint: surfaceMint ?? this.surfaceMint,
      surfaceLilac: surfaceLilac ?? this.surfaceLilac,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      borderDefault: borderDefault ?? this.borderDefault,
      controlRest: controlRest ?? this.controlRest,
      controlSelected: controlSelected ?? this.controlSelected,
      feedbackPositive: feedbackPositive ?? this.feedbackPositive,
      feedbackAttention: feedbackAttention ?? this.feedbackAttention,
      feedbackCritical: feedbackCritical ?? this.feedbackCritical,
      focus: focus ?? this.focus,
      brandGradient: brandGradient ?? this.brandGradient,
    );
  }

  @override
  ThemeExtension<MemoraColorTokens> lerp(covariant ThemeExtension<MemoraColorTokens>? other, double t) {
    if (other is! MemoraColorTokens) {
      return this;
    }
    return MemoraColorTokens(
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandAqua: Color.lerp(brandAqua, other.brandAqua, t)!,
      brandBlue: Color.lerp(brandBlue, other.brandBlue, t)!,
      surfaceCanvas: Color.lerp(surfaceCanvas, other.surfaceCanvas, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      surfaceOcean: Color.lerp(surfaceOcean, other.surfaceOcean, t)!,
      surfaceMint: Color.lerp(surfaceMint, other.surfaceMint, t)!,
      surfaceLilac: Color.lerp(surfaceLilac, other.surfaceLilac, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      controlRest: Color.lerp(controlRest, other.controlRest, t)!,
      controlSelected: Color.lerp(controlSelected, other.controlSelected, t)!,
      feedbackPositive: Color.lerp(feedbackPositive, other.feedbackPositive, t)!,
      feedbackAttention: Color.lerp(feedbackAttention, other.feedbackAttention, t)!,
      feedbackCritical: Color.lerp(feedbackCritical, other.feedbackCritical, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      brandGradient: brandGradient,
    );
  }
}

extension MemoraThemeContext on BuildContext {
  MemoraColorTokens get memoraColors => Theme.of(this).extension<MemoraColorTokens>() ?? MemoraColorTokens.light;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
