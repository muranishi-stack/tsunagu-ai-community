import 'package:flutter/material.dart';

class AppTheme {
  // TSUNAGU brand colors - Vermillion (朱色) accent
  static const Color vermillion = Color(0xFFE63946);
  static const Color vermillionDark = Color(0xFFC1283A);
  static const Color vermillionLight = Color(0xFFF06A75);
  static const Color vermillionPale = Color(0xFFFDECEE);

  // Neutrals
  static const Color black = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF2A2A2A);
  static const Color darkGrey = Color(0xFF555555);
  static const Color grey = Color(0xFF888888);
  static const Color lightGrey = Color(0xFFB5B5B5);
  static const Color paleGrey = Color(0xFFE8E8E8);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic aliases (for backward compatibility)
  static const Color gold = vermillion;
  static const Color goldLight = vermillionLight;
  static const Color goldDark = vermillionDark;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: white,
      primaryColor: vermillion,
      colorScheme: const ColorScheme.light(
        primary: vermillion,
        secondary: vermillion,
        surface: white,
        onPrimary: white,
        onSecondary: white,
        onSurface: black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 3.0,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.0,
          color: black,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.8,
          color: black,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: black,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: charcoal,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkGrey,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: grey,
          letterSpacing: 0.3,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: black,
        ),
      ),
      iconTheme: const IconThemeData(
        color: black,
        size: 24,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: vermillion,
        unselectedItemColor: lightGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: paleGrey,
        thickness: 0.5,
        space: 1,
      ),
    );
  }
}
