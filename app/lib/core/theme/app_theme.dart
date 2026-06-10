import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Brand colours
  static const _primaryGreen = Color(0xFF00C896);
  static const _bgDark = Color(0xFF0D0F14);
  static const _surfaceDark = Color(0xFF181B22);
  static const _cardDark = Color(0xFF1E2230);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF8B95B0);
  static const _slotAvailable = Color(0xFF00C896);
  static const _slotBooked   = Color(0xFF252B3B); // solid dark surface
  static const _slotSelected = Color(0xFF4F8EF7);
  static const _errorRed = Color(0xFFFF5C5C);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bgDark,
      colorScheme: const ColorScheme.dark(
        primary: _primaryGreen,
        secondary: _slotSelected,
        surface: _surfaceDark,
        error: _errorRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: _textPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: _bgDark,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: _textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _cardDark,
        selectedColor: _primaryGreen.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: _textPrimary, fontSize: 13),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2F3E),
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _textPrimary, fontSize: 28,
          fontWeight: FontWeight.w800, letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: _textPrimary, fontSize: 22,
          fontWeight: FontWeight.w700, letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: _textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: _textSecondary, fontSize: 14),
        labelSmall: TextStyle(color: _textSecondary, fontSize: 12),
      ),
    );
  }

  // Slot chip colors
  static Color slotColor(String status, {bool isSelected = false}) {
    if (isSelected) return _slotSelected;
    return status == 'available' ? _slotAvailable : _slotBooked;
  }

  static Color slotTextColor(String status, {bool isSelected = false}) {
    if (isSelected) return Colors.white;
    // available = solid green chip → black text for contrast
    // booked   = dark chip → muted grey text
    return status == 'available' ? Colors.black : _textSecondary;
  }

  // border color for the chip (keeps the booked state recognisable)
  static Color slotBorderColor(String status, {bool isSelected = false}) {
    if (isSelected) return _slotSelected;
    if (status == 'available') return Colors.transparent;
    return const Color(0xFF3A3F52); // subtle grey border on booked
  }
}
