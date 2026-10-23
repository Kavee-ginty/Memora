import 'package:flutter/material.dart';

abstract final class MemoraTheme {
  static ThemeData light() {
    const Color ink = Color(0xFF1D2228);
    const Color primary = Color(0xFF0077B6);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F9FF),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: ink),
      ),
    );
  }
}
