import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand colours - Calm, editorial light theme
  static const _primaryAccent = Color(0xFF2E5C50); // Calm Forest Green
  static const _bgLight = Color(0xFFF9F9F7); // Sand / Off-white
  static const _surfaceLight = Color(0xFFFFFFFF); // Pure white for cards
  static const _textPrimary = Color(0xFF1A1C19); // Almost black / Charcoal
  static const _textSecondary = Color(0xFF6B6E6A); // Soft gray
  static const _borderLight = Color(0xFFE5E5DF); // Very subtle gray border
  static const _errorRed = Color(0xFFD9423E); // Muted editorial red

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _bgLight,
      colorScheme: const ColorScheme.light(
        primary: _primaryAccent,
        secondary: _primaryAccent,
        surface: _surfaceLight,
        error: _errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _textPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgLight,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: _surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryAccent),
        ),
        hintStyle: const TextStyle(color: _textSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: _borderLight,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _textPrimary, fontSize: 32,
          fontWeight: FontWeight.w400, letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: _textPrimary, fontSize: 24,
          fontWeight: FontWeight.w500, letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: _textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: _textSecondary, fontSize: 14),
        labelSmall: TextStyle(color: _textSecondary, fontSize: 12),
      ),
    );
  }
}
