import 'package:flutter/material.dart';

class CoraTheme {
  // Standard Empathetic Health Palette
  static const Color primaryColor = Color(0xFFB33A6B);
  static const Color secondaryColor = Color(0xFF2E7D6B);
  static const Color surfaceColor = Color(0xFFFAF7F7);
  static const Color textColor = Color(0xFF261C20);

  // High Legibility (WCAG AAA >= 7:1) Palette for Senior Vitality
  static const Color highLegibilityPrimary = Color(0xFF4A0023);
  static const Color highLegibilityText = Color(0xFF121212);
  static const Color highLegibilityBackground = Color(0xFFFFFFFF);
  static const Color highLegibilityBorder = Color(0xFF000000);

  static ThemeData standard() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textColor,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData highLegibility() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: highLegibilityPrimary,
        onPrimary: Colors.white,
        secondary: Color(0xFF004D40),
        onSecondary: Colors.white,
        surface: highLegibilityBackground,
        onSurface: highLegibilityText,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: highLegibilityText,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(
          color: highLegibilityText,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: highLegibilityText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(56, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: highLegibilityBorder, width: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
