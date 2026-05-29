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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: offWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: lightGrey, fontSize: 15),
        labelStyle: const TextStyle(color: darkGrey, fontSize: 15),
        floatingLabelStyle: const TextStyle(
            color: vermillion, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIconColor: grey,
        suffixIconColor: grey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: paleGrey, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: paleGrey, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: vermillion, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.8),
        ),
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

  // ─── Dark Mode Colors ────────────────────────────────────────
  static const Color darkBg = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceVariant = Color(0xFF252525);
  static const Color darkBorder = Color(0xFF383838);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFCBCBCB);
  static const Color darkTextTertiary = Color(0xFF8F8F8F);

  // ─── Adaptive color helpers (use these in widgets) ───────────
  /// 背景色（ライト: white、ダーク: darkBg）
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : white;

  /// 表面色（カード等、ライト: white、ダーク: darkSurface）
  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : white;

  /// バリアント表面色（ライト: offWhite、ダーク: darkSurfaceVariant）
  static Color surfaceVariant(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurfaceVariant
          : offWhite;

  /// 区切り線/枠線色
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : paleGrey;

  /// メインテキスト色（ライト: black、ダーク: darkText）
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkText : black;

  /// セカンダリーテキスト色
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : darkGrey;

  /// 3次テキスト色（補足情報）
  static Color textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextTertiary
          : grey;

  /// ヴァーミリオン淡色（ハイライト背景）
  static Color vermillionTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0x40E63946) // 25% opacity vermillion
          : vermillionPale;

  /// ダークモード判定
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: vermillion,
      colorScheme: const ColorScheme.dark(
        primary: vermillion,
        secondary: vermillion,
        surface: darkSurface,
        onPrimary: white,
        onSecondary: white,
        onSurface: darkText,
        error: Color(0xFFFF6B6B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkText,
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
          color: darkText,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.8,
          color: darkText,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: darkText,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: darkText,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkTextSecondary,
          letterSpacing: 0.3,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: darkText,
        ),
      ),
      iconTheme: const IconThemeData(
        color: darkText,
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: darkTextTertiary, fontSize: 15),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 15),
        floatingLabelStyle: const TextStyle(
            color: vermillionLight, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIconColor: darkTextTertiary,
        suffixIconColor: darkTextTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: vermillionLight, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.8),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: vermillion,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 0.5,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
      ),
    );
  }
}
