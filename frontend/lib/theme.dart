import 'package:flutter/material.dart';

class AuraTheme {
  // 🎨 Palette: Bright, Clean & High-Tech
  static const Color background = Color(0xFFFBFBFD); // Premium light gray
  static const Color surface = Colors.white;
  static const Color accentBlue = Color(0xFF00A8E8); // Vivid High-Tech Teal/Blue
  static const Color accentPastelPurple = Color(0xFF005C8A); // Deeper contrast blue
  static const Color textPrimary = Color(0xFF1D1D1F); // Stark Black/Dark Gray
  static const Color textSecondary = Color(0xFF86868B);
  static const Color borderLight = Color(0xFFE5E5EA);
  
  static ThemeData get lightTheme { // Switched to lightTheme
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.light(
        primary: accentBlue,
        secondary: accentPastelPurple,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: accentBlue,
        ),
      ),
    );
  }

  // ✨ Modern Flat Decoration (No Glass)
  static BoxDecoration solidDecoration({double opacity = 1.0, double radius = 24, bool shadow = true}) {
    return BoxDecoration(
      color: surface.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderLight, width: 1.5),
      boxShadow: shadow ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 8),
        )
      ] : [],
    );
  }
}
