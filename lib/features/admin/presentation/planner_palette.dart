import 'package:flutter/material.dart';

import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';

/// Color bag for [ShopProductBox] so the partner form can keep dark defaults.
class PlannerPaletteColors {
  const PlannerPaletteColors({
    required this.bg,
    required this.card,
    required this.border,
    required this.text,
    required this.textDim,
    required this.accent,
  });

  final Color bg;
  final Color card;
  final Color border;
  final Color text;
  final Color textDim;
  final Color accent;

  static const partnerDark = PlannerPaletteColors(
    bg: PartnerTheme.bg,
    card: PartnerTheme.card,
    border: PartnerTheme.border,
    text: PartnerTheme.text,
    textDim: PartnerTheme.textDim,
    accent: PartnerTheme.accent,
  );

  static const plannerLight = PlannerPaletteColors(
    bg: PlannerPalette.bg,
    card: PlannerPalette.card,
    border: PlannerPalette.border,
    text: PlannerPalette.text,
    textDim: PlannerPalette.textDim,
    accent: PlannerPalette.accent,
  );
}

/// Light colors for the planned-trip editor chrome (frame, fields, buttons).
///
/// Keeps PartnerTheme dark tokens for other screens. Cursor and selection stay
/// dark so mint never appears on this white surface.
abstract final class PlannerPalette {
  static const Color bg = Color(0xFFF5F7FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFCDD5E0);
  static const Color borderStrong = Color(0xFF9AA8BC);
  static const Color text = Color(0xFF152033);
  static const Color textDim = Color(0xFF5A6A7E);
  static const Color accent = Color(0xFF1F4E79);
  static const Color orange = Color(0xFFC45C12);
  static const Color badgeGreenBg = Color(0xFFE5F5EC);
  static const Color badgeGreenFg = Color(0xFF1B6B3A);
  static const Color badgeOrangeBg = Color(0xFFFFF0E4);
  static const Color badgeOrangeFg = Color(0xFF9A4A10);
  static const Color badgeBlueBg = Color(0xFFE8F1F8);
  static const Color badgeBlueFg = Color(0xFF1F4E79);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color snackBg = Color(0xFF2A3548);
  static const Color disabledFill = Color(0xFFE8ECF2);
  static const Color pressedOverlay = Color(0x1A1F4E79);

  static ThemeData get theme {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: badgeBlueBg,
      onPrimaryContainer: text,
      secondary: orange,
      onSecondary: onAccent,
      secondaryContainer: badgeOrangeBg,
      onSecondaryContainer: badgeOrangeFg,
      tertiary: accent,
      onTertiary: onAccent,
      error: Color(0xFFB42318),
      onError: onAccent,
      surface: card,
      onSurface: text,
      onSurfaceVariant: textDim,
      outline: border,
      outlineVariant: borderStrong,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
      primaryIconTheme: const IconThemeData(color: text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: text),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: disabledFill,
          disabledForegroundColor: textDim,
          overlayColor: pressedOverlay,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          disabledForegroundColor: textDim,
          side: const BorderSide(color: borderStrong),
          overlayColor: pressedOverlay,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          disabledForegroundColor: textDim,
          overlayColor: pressedOverlay,
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: badgeBlueBg,
        labelStyle: TextStyle(color: text),
        side: BorderSide(color: border),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: card,
        textStyle: TextStyle(color: text),
        surfaceTintColor: Colors.transparent,
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(card),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: textDim,
        textColor: text,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(color: textDim, fontSize: 14),
        iconColor: text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: snackBg,
        contentTextStyle: TextStyle(color: onAccent),
        actionTextColor: Color(0xFF9EC5E8),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: card,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return card;
        }),
        checkColor: const WidgetStatePropertyAll(onAccent),
        side: const BorderSide(color: borderStrong),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return textDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.35);
          }
          return border;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return borderStrong;
        }),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: card,
        headerBackgroundColor: accent,
        headerForegroundColor: onAccent,
        dayForegroundColor: WidgetStateProperty.all(text),
        yearForegroundColor: WidgetStateProperty.all(text),
        todayForegroundColor: const WidgetStatePropertyAll(accent),
        todayBorder: const BorderSide(color: accent),
        dayOverlayColor: WidgetStateProperty.all(
          accent.withValues(alpha: 0.12),
        ),
        rangeSelectionBackgroundColor: accent.withValues(alpha: 0.16),
        rangeSelectionOverlayColor: WidgetStateProperty.all(
          accent.withValues(alpha: 0.12),
        ),
        weekdayStyle: const TextStyle(color: textDim),
        yearStyle: const TextStyle(color: text),
        dayStyle: const TextStyle(color: text),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        circularTrackColor: border,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: text,
        selectionColor: Color(0x331F4E79),
        selectionHandleColor: accent,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: text,
          disabledForegroundColor: textDim,
          overlayColor: pressedOverlay,
        ),
      ),
    );
  }
}
