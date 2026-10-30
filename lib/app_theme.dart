import 'package:flutter/material.dart';

bool appIsNight = false;

abstract final class AppPalette {
  static const lightCanvas = Color(0xFFF4F6F8);
  static const darkCanvas = Color(0xFF10151D);
  static const lightSurface = Colors.white;
  static const darkSurface = Color(0xFF1B2430);
  static const lightInk = Color(0xFF122033);
  static const darkInk = Color(0xFFE6EDF5);
  static const lightMuted = Color(0xFF6D7B8E);
  static const darkMuted = Color(0xFFA0AEC0);

  static ThemeData theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? darkCanvas : lightCanvas;
    final surface = isDark ? darkSurface : lightSurface;
    final ink = isDark ? darkInk : lightInk;
    const blue = Color(0xFF1769E0);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        brightness: brightness,
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      fontFamily: 'sans',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ink.withValues(alpha: .10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blue, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
