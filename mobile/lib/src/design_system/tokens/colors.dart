import 'package:flutter/material.dart';

/// Memora semantic color tokens as defined in Memora UI/UX Design Specification Section 4.2.
abstract final class MemoraColors {
  // Brand tokens
  static const Color brandPrimary = Color(0xFF00AFFF);
  static const Color brandAqua = Color(0xFF00E1FF);
  static const Color brandBlue = Color(0xFF067FFF);

  // Surface tokens
  static const Color surfaceCanvas = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF5F9FF);
  static const Color surfaceOcean = Color(0xFFDDEEFF);
  static const Color surfaceMint = Color(0xFFF6FBEF);
  static const Color surfaceLilac = Color(0xFFEFE7EF);

  // Text tokens
  static const Color textPrimary = Color(0xFF1D2228);
  static const Color textSecondary = Color(0xFF203F59);
  static const Color textMuted = Color(0xFF566B7D);

  // Border & divider tokens
  static const Color borderDefault = Color(0xFFAACFEA);

  // Control tokens
  static const Color controlRest = Color(0xFF86BBE7);
  static const Color controlSelected = Color(0xFFD4F2FF);

  // Feedback tokens
  static const Color feedbackPositive = Color(0xFF137A4B);
  static const Color feedbackAttention = Color(0xFF9A5B00);
  static const Color feedbackCritical = Color(0xFFB42318);

  // Focus ring token
  static const Color focus = Color(0xFF067FFF);

  // Brand gradient (cyan to aqua)
  static const LinearGradient brandGradient = LinearGradient(
    colors: <Color>[brandPrimary, brandAqua],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
