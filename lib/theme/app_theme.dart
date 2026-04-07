import 'package:flutter/material.dart';

class AppTheme {
  // Saffron/Orange palette
  static const Color primary = Color(0xFFFF6F00);
  static const Color primaryDark = Color(0xFF1B3C00);
  static const Color secondary = Color(0xFF7C4DFF);

  static const Color background = Color(0xFFF7F7F7);
  static const Color divider = Color(0xFFE7E7E7);

  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6A6A6A);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFD32F2F);

  static const Color cardShadow = Color(0x1A000000);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: textPrimary),
    ),
  );
}

