import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryRed = Color(0xFFE53E3E);
  static const Color secondaryBlue = Color(0xFF3182CE);
  static const Color accentGreen = Color(0xFF38A169);
  static const Color warningOrange = Color(0xFFF56500);
  
  // Gradient Colors
  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF416C),
      Color(0xFFFF4B2B),
    ],
  );
  
  static const LinearGradient hospitalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667eea),
      Color(0xFF764ba2),
    ],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1a1a2e),
      Color(0xFF16213e),
      Color(0xFF0f3460),
    ],
  );

  // Glass Morphism Colors
  static const Color glassColor = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: secondaryBlue,
        tertiary: accentGreen,
        surface: Color(0xFF1a1a2e),
        background: Color(0xFF0f0f23),
        error: Color(0xFFFF6B6B),
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shadowColor: primaryRed.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: glassColor,
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white60,
        ),
      ),
    );
  }
}