import 'package:flutter/material.dart';

import 'colors.dart';

/// Memora typography styles according to Memora UI/UX Design Specification Section 4.3.
/// Exo is used for brand expression, headings, controls, navigation, and compact metrics.
/// Inter is used for explanations, longer body copy, input text, and detailed learning content.
/// Fallback is system sans-serif.
abstract final class MemoraTypography {
  static const String fontExo = 'Exo';
  static const String fontInter = 'Inter';
  static const List<String> fontFallbacks = <String>['sans-serif'];

  // Exo styles
  static const TextStyle display = TextStyle(
    fontFamily: fontExo,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 40 / 32,
    color: MemoraColors.textPrimary,
  );

  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontExo,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w600,
    fontSize: 28,
    height: 36 / 28,
    color: MemoraColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontExo,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 30 / 22,
    color: MemoraColors.textPrimary,
  );

  static const TextStyle question = TextStyle(
    fontFamily: fontExo,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 32 / 24,
    color: MemoraColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontExo,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 24 / 17,
    color: MemoraColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontExo,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    color: MemoraColors.textPrimary,
  );

  static const TextStyle navigation = TextStyle(
    fontFamily: fontExo,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    height: 20 / 13,
    color: MemoraColors.textPrimary,
  );

  // Inter styles for explanations, longer body copy, and metadata (Section 4.3)
  static const TextStyle body = TextStyle(
    fontFamily: fontInter,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 25 / 16,
    color: MemoraColors.textPrimary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontInter,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 24 / 16,
    color: MemoraColors.textPrimary,
  );

  static const TextStyle metadata = TextStyle(
    fontFamily: fontInter,
    fontFamilyFallback: fontFallbacks,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    height: 20 / 14,
    color: MemoraColors.textSecondary,
  );
}
