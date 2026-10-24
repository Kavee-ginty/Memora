import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/elevations.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'theme_extensions.dart';

abstract final class MemoraTheme {
  static ThemeData light() {
    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: MemoraColors.brandPrimary,
      onPrimary: MemoraColors.textPrimary,
      primaryContainer: MemoraColors.surfaceOcean,
      onPrimaryContainer: MemoraColors.textPrimary,
      secondary: MemoraColors.brandBlue,
      onSecondary: MemoraColors.surfaceCanvas,
      secondaryContainer: MemoraColors.controlSelected,
      onSecondaryContainer: MemoraColors.textPrimary,
      tertiary: MemoraColors.brandAqua,
      onTertiary: MemoraColors.textPrimary,
      error: MemoraColors.feedbackCritical,
      onError: MemoraColors.surfaceCanvas,
      errorContainer: const Color(0xFFFDE8E8),
      onErrorContainer: MemoraColors.feedbackCritical,
      surface: MemoraColors.surfaceCanvas,
      onSurface: MemoraColors.textPrimary,
      surfaceContainerLowest: MemoraColors.surfaceCanvas,
      surfaceContainerLow: MemoraColors.surfaceSoft,
      surfaceContainer: MemoraColors.surfaceOcean,
      surfaceContainerHigh: MemoraColors.surfaceLilac,
      outline: MemoraColors.borderDefault,
      outlineVariant: MemoraColors.controlRest,
    );

    final TextTheme textTheme = TextTheme(
      displayLarge: MemoraTypography.display,
      headlineLarge: MemoraTypography.pageTitle,
      headlineMedium: MemoraTypography.sectionTitle,
      headlineSmall: MemoraTypography.question,
      titleLarge: MemoraTypography.sectionTitle,
      titleMedium: MemoraTypography.cardTitle,
      titleSmall: MemoraTypography.bodyStrong,
      bodyLarge: MemoraTypography.body,
      bodyMedium: MemoraTypography.bodyStrong,
      bodySmall: MemoraTypography.metadata,
      labelLarge: MemoraTypography.button,
      labelMedium: MemoraTypography.metadata,
      labelSmall: MemoraTypography.navigation,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MemoraColors.surfaceSoft,
      fontFamily: MemoraTypography.fontExo,
      fontFamilyFallback: MemoraTypography.fontFallbacks,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[MemoraColorTokens.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: MemoraColors.surfaceOcean,
        foregroundColor: MemoraColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: MemoraTypography.pageTitle,
      ),
      cardTheme: const CardThemeData(
        color: MemoraColors.surfaceOcean,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: MemoraRadii.primaryCard,
          side: MemoraElevations.defaultBorderSide,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: MemoraColors.brandPrimary,
          foregroundColor: MemoraColors.textPrimary,
          textStyle: MemoraTypography.button,
          minimumSize: const Size.fromHeight(MemoraSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: MemoraRadii.control,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space24,
            vertical: MemoraSpacing.space12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: MemoraColors.surfaceCanvas,
          foregroundColor: MemoraColors.textPrimary,
          textStyle: MemoraTypography.button,
          side: const BorderSide(color: MemoraColors.brandBlue, width: 1.5),
          minimumSize: const Size.fromHeight(MemoraSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: MemoraRadii.control,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space24,
            vertical: MemoraSpacing.space12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MemoraColors.brandBlue,
          textStyle: MemoraTypography.button,
          minimumSize: const Size(
            MemoraSpacing.minTouchTarget,
            MemoraSpacing.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraSpacing.space16,
            vertical: MemoraSpacing.space8,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: MemoraColors.surfaceOcean,
        contentPadding: EdgeInsets.symmetric(
          horizontal: MemoraSpacing.space16,
          vertical: MemoraSpacing.space12,
        ),
        hintStyle: TextStyle(
          color: MemoraColors.textMuted,
          fontFamily: MemoraTypography.fontInter,
          fontFamilyFallback: MemoraTypography.fontFallbacks,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: MemoraRadii.control,
          borderSide: BorderSide(color: MemoraColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: MemoraRadii.control,
          borderSide: BorderSide(color: MemoraColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: MemoraRadii.control,
          borderSide: BorderSide(color: MemoraColors.focus, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: MemoraRadii.control,
          borderSide: BorderSide(
            color: MemoraColors.feedbackCritical,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: MemoraRadii.control,
          borderSide: BorderSide(
            color: MemoraColors.feedbackCritical,
            width: 2.0,
          ),
        ),
        errorStyle: TextStyle(
          color: MemoraColors.feedbackCritical,
          fontFamily: MemoraTypography.fontInter,
          fontFamilyFallback: MemoraTypography.fontFallbacks,
          fontSize: 14,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: MemoraColors.surfaceCanvas,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: MemoraRadii.dialog,
          side: MemoraElevations.defaultBorderSide,
        ),
        titleTextStyle: MemoraTypography.sectionTitle,
        contentTextStyle: MemoraTypography.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: MemoraColors.surfaceCanvas,
        modalBackgroundColor: MemoraColors.surfaceCanvas,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: MemoraRadii.sheet),
        showDragHandle: true,
        dragHandleColor: MemoraColors.textMuted,
      ),
      dividerTheme: const DividerThemeData(
        color: MemoraColors.borderDefault,
        thickness: 1,
        space: MemoraSpacing.space16,
      ),
    );
  }
}
