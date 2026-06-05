import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF00BFA5); // teal accent
  static const _secondaryColor = Color(0xFF1DE9B6);
  static const _bgDark = Color(0xFF0F1117);
  static const _surfaceDark = Color(0xFF1A1D27);
  static const _surfaceVariantDark = Color(0xFF252836);
  static const _onSurfaceDark = Color(0xFFE8EAED);
  static const _subtleText = Color(0xFF9AA0AB);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryColor,
      onPrimary: Colors.black,
      secondary: _secondaryColor,
      onSecondary: Colors.black,
      error: const Color(0xFFCF6679),
      onError: Colors.black,
      surface: _surfaceDark,
      onSurface: _onSurfaceDark,
      surfaceContainerHighest: _surfaceVariantDark,
      outline: const Color(0xFF3A3D4A),
      outlineVariant: const Color(0xFF2A2D38),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgDark,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceDark,
        foregroundColor: _onSurfaceDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _onSurfaceDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A3D4A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
        ),
        hintStyle: const TextStyle(color: _subtleText, fontSize: 14),
        labelStyle: const TextStyle(color: _subtleText),
        floatingLabelStyle: const TextStyle(color: _primaryColor),
        prefixIconColor: _subtleText,
        suffixIconColor: _subtleText,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2D38),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: _primaryColor,
        titleTextStyle: TextStyle(
          color: _onSurfaceDark,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: _subtleText,
          fontSize: 13,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceVariantDark,
        contentTextStyle: const TextStyle(color: _onSurfaceDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Sent message bubble gradient
  static const sentBubbleColor = Color(0xFF005C4B);
  static const receivedBubbleColor = Color(0xFF252836);
  static const subtleTextColor = _subtleText;
  static const primaryColor = _primaryColor;
  static const bgDark = _bgDark;
  static const surfaceDark = _surfaceDark;
  static const surfaceVariantDark = _surfaceVariantDark;
}
