import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/design_system/design_system.dart';

double _luminanceComponent(double c) {
  if (c <= 0.04045) {
    return c / 12.92;
  }
  return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  final double r = _luminanceComponent(color.r);
  final double g = _luminanceComponent(color.g);
  final double b = _luminanceComponent(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final double l1 = _relativeLuminance(c1);
  final double l2 = _relativeLuminance(c2);
  final double lighter = math.max(l1, l2);
  final double darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Memora Design Tokens', () {
    test('WCAG 2.2 AA color contrast ratios pass', () {
      // Normal text requires >= 4.5:1
      final double textOnCanvas = _contrastRatio(MemoraColors.textPrimary, MemoraColors.surfaceCanvas);
      expect(textOnCanvas, greaterThanOrEqualTo(4.5), reason: 'Dark ink on canvas contrast');

      final double textOnOcean = _contrastRatio(MemoraColors.textPrimary, MemoraColors.surfaceOcean);
      expect(textOnOcean, greaterThanOrEqualTo(4.5), reason: 'Dark ink on ocean contrast');

      final double textOnCyan = _contrastRatio(MemoraColors.textPrimary, MemoraColors.brandPrimary);
      expect(textOnCyan, greaterThanOrEqualTo(4.5), reason: 'Dark ink on cyan primary contrast');

      final double secondaryOnCanvas = _contrastRatio(MemoraColors.textSecondary, MemoraColors.surfaceCanvas);
      expect(secondaryOnCanvas, greaterThanOrEqualTo(4.5), reason: 'Secondary text on canvas contrast');

      final double positiveOnMint = _contrastRatio(MemoraColors.feedbackPositive, MemoraColors.surfaceMint);
      expect(positiveOnMint, greaterThanOrEqualTo(4.5), reason: 'Feedback positive on mint contrast');

      final double attentionOnCanvas = _contrastRatio(MemoraColors.feedbackAttention, MemoraColors.surfaceCanvas);
      expect(attentionOnCanvas, greaterThanOrEqualTo(4.5), reason: 'Feedback attention on canvas contrast');

      final double criticalOnCanvas = _contrastRatio(MemoraColors.feedbackCritical, MemoraColors.surfaceCanvas);
      expect(criticalOnCanvas, greaterThanOrEqualTo(4.5), reason: 'Feedback critical on canvas contrast');
    });

    test('Typography scale matches UI/UX Specification 4.3', () {
      expect(MemoraTypography.display.fontSize, 32);
      expect(MemoraTypography.pageTitle.fontSize, 28);
      expect(MemoraTypography.sectionTitle.fontSize, 22);
      expect(MemoraTypography.question.fontSize, 24);
      expect(MemoraTypography.cardTitle.fontSize, 17);
      expect(MemoraTypography.button.fontSize, 16);
      expect(MemoraTypography.navigation.fontSize, 13);
      expect(MemoraTypography.body.fontSize, 16);
      expect(MemoraTypography.bodyStrong.fontSize, 16);
      expect(MemoraTypography.metadata.fontSize, 14);

      // Verify font fallbacks
      expect(MemoraTypography.fontFallbacks, contains('sans-serif'));
    });

    test('Spacing scale matches UI/UX Specification Section 5', () {
      expect(MemoraSpacing.space4, 4.0);
      expect(MemoraSpacing.space8, 8.0);
      expect(MemoraSpacing.space12, 12.0);
      expect(MemoraSpacing.space16, 16.0);
      expect(MemoraSpacing.space24, 24.0);
      expect(MemoraSpacing.space32, 32.0);
      expect(MemoraSpacing.space48, 48.0);

      // Gutters
      expect(MemoraSpacing.gutterForWidth(320), MemoraSpacing.gutterNarrow);
      expect(MemoraSpacing.gutterForWidth(359), MemoraSpacing.gutterNarrow);
      expect(MemoraSpacing.gutterForWidth(360), MemoraSpacing.gutterStandard);
      expect(MemoraSpacing.gutterForWidth(400), MemoraSpacing.gutterStandard);

      // Content bounds
      expect(MemoraSpacing.maxContentWidthFor(400), MemoraSpacing.maxContentWidthMobile);
      expect(MemoraSpacing.maxContentWidthFor(800), MemoraSpacing.maxContentWidthTablet);
    });

    test('Corner radii match UI/UX Specification Section 4.4', () {
      expect(MemoraRadii.primaryCardValue, 24.0);
      expect(MemoraRadii.compactCardValue, 16.0);
      expect(MemoraRadii.controlValue, 16.0);
      expect(MemoraRadii.chipValue, 12.0);
      expect(MemoraRadii.dialogValue, 24.0);
      expect(MemoraRadii.sheetValue, 24.0);
    });
  });
}
