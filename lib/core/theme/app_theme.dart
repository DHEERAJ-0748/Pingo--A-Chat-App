import 'package:flutter/material.dart';

/// Centralized design system for the Pingo app.
/// All colors, typography, and surface definitions follow the
/// **Pingo Obsidian Flow** identity. This file contains only the UI theme –
/// it does not modify any business logic or backend configuration.
class AppTheme {
  // ---------------------------------------------------------------------
  //   Color palette – matches the specification precisely.
  // ---------------------------------------------------------------------
  static const _primaryBackground = Color(0xFF050706); // deep black
  static const _secondaryBackground = Color(0xFF0B100E);
  static const _cardBackground = Color(0xFF101714);
  static const _elevatedSurface = Color(0xFF151E1A);

  static const _primaryMint = Color(0xFFB9F5DD);
  static const secondaryMint = Color(0xFF83DDBD);
  static const _tealAccent = Color(0xFF37B995);

  static const _primaryText = Color(0xFFF1F7F3);
  static const _secondaryText = Color(0xFF94A49B);
  static const _mutedText = Color(0xFF64736B);
  // Divider: a very subtle transparent gray‑green (use opacity 0.2)
  static const _divider = Color(0x332A2D38);

  // Exposed color shortcuts used directly by widgets.
  static const primaryText = _primaryText;
  static const secondaryText = _secondaryText;
  static const mutedText = _mutedText;
  static const primaryColor = _tealAccent;
  static const surfaceDark = _secondaryBackground;
  static const surfaceVariantDark = _cardBackground;

  // ---------------------------------------------------------------------
  //   ThemeData – Material 3 dark theme with custom color scheme.
  // ---------------------------------------------------------------------
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _tealAccent,
      onPrimary: Colors.black,
      secondary: _primaryMint,
      onSecondary: Colors.black,
      error: const Color(0xFFCF6679),
      onError: Colors.black,
      surface: _elevatedSurface,
      onSurface: _primaryText,
      surfaceContainerHighest: _cardBackground,
      outline: _divider,
      outlineVariant: const Color(0xFF2A2D38),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _primaryBackground,
      fontFamily: 'Roboto',
      textTheme: TextTheme(
        displayLarge: TextStyle(color: _primaryText, fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: _primaryText, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: _primaryText, fontSize: 18, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(color: _secondaryText, fontSize: 15, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: _mutedText, fontSize: 13, fontWeight: FontWeight.w400),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _secondaryBackground,
        foregroundColor: _primaryText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: _tealAccent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardBackground,
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
          borderSide: BorderSide(color: _tealAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A49B), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF94A49B)),
        floatingLabelStyle: TextStyle(color: _tealAccent),
        prefixIconColor: Color(0xFF94A49B),
        suffixIconColor: Color(0xFF94A49B),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryMint,
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
          foregroundColor: _tealAccent,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _divider,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: _tealAccent,
        titleTextStyle: TextStyle(
          color: _primaryText,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: _mutedText,
          fontSize: 13,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _cardBackground,
        contentTextStyle: const TextStyle(color: _primaryText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------------------
  //   Message bubble colors – used by message widget implementations.
  // ---------------------------------------------------------------------
  static const sentBubbleColor = Color(0xFF37B995); // teal accent
  static const receivedBubbleColor = Color(0xFF101714); // card background
  static const subtleTextColor = _mutedText;
}
