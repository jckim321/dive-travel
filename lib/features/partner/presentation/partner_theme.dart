import 'package:flutter/material.dart';

/// Affiliate-partner (제휴파트너) dark theme tokens and [ThemeData].
///
/// Apply only to partner home, coming-soon, and temp bookings screens.
/// Do not wrap product/docs/desk/same-boat screens (H0).
abstract final class PartnerTheme {
  static const Color bg = Color(0xFF0B1626);
  static const Color card = Color(0xFF14243A);
  static const Color border = Color(0xFF223653);
  static const Color borderStrong = Color(0xFF2C4468);
  static const Color text = Color(0xFFE9EFF6);
  static const Color textDim = Color(0xFF9BB0C7);
  static const Color accent = Color(0xFF4FD8B4);
  static const Color orange = Color(0xFFE8962A);
  static const Color badgeGreenBg = Color(0xFF123A2C);
  static const Color badgeGreenFg = Color(0xFF8FE3B5);
  static const Color badgeOrangeBg = Color(0xFF4A3412);
  static const Color badgeOrangeFg = Color(0xFFFFCF8A);
  static const Color badgeBlueBg = Color(0xFF14324A);
  static const Color badgeBlueFg = Color(0xFFBFE3F5);

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: bg,
      primaryContainer: borderStrong,
      onPrimaryContainer: text,
      secondary: orange,
      onSecondary: bg,
      secondaryContainer: badgeOrangeBg,
      onSecondaryContainer: badgeOrangeFg,
      tertiary: accent,
      onTertiary: bg,
      error: Color(0xFFFF6B6B),
      onError: bg,
      surface: card,
      onSurface: text,
      onSurfaceVariant: textDim,
      outline: border,
      outlineVariant: borderStrong,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: card,
      dividerColor: border,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: textDim),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(color: text, fontWeight: FontWeight.w700),
        labelLarge: TextStyle(color: text),
        labelMedium: TextStyle(color: textDim),
        labelSmall: TextStyle(color: textDim),
      ),
      iconTheme: const IconThemeData(color: text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        hintStyle: const TextStyle(color: textDim),
        labelStyle: const TextStyle(color: textDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: text),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg,
          disabledBackgroundColor: border,
          disabledForegroundColor: textDim,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: borderStrong),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: borderStrong,
        labelStyle: TextStyle(color: text),
        side: BorderSide(color: border),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: card,
        textStyle: TextStyle(color: text),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textDim,
        textColor: text,
      ),
    );
    return base;
  }

  /// Wrap a partner-only route so nested Material uses [dark].
  static Widget wrap(Widget child) {
    return Theme(data: dark, child: child);
  }
}
