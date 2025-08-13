import 'package:flutter/material.dart';

class AppTheme {
  // Cybersecurity-inspired color palette
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color secondaryTeal = Color(0xFF0D9488);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceCharcoal = Color(0xFF1F2937);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFD1D5DB);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: secondaryTeal,
        tertiary: accentGreen,
        surface: surfaceCharcoal,
        error: errorRed,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      
      // Typography
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.normal,
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: textPrimary,
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: surfaceCharcoal,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCharcoal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCharcoal,
        selectedItemColor: accentGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}