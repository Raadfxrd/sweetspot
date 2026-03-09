import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Base neutrals
  static const Color background = Color(0xFF111214);
  static const Color surface = Color(0xFF1C1D20);
  static const Color surfaceVariant = Color(0xFF242528);
  static const Color primary = Color(0xFF2A2B2F);
  static const Color border = Color(0xFF35373D);

  // Accent — a single understated blue-indigo
  static const Color accent = Color(0xFF4F6EF7);
  static const Color highlight =
      Color(0xFF4F6EF7); // alias kept for compatibility

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF453A);

  // Text
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);

  // Canvas / room colours (muted, intentional)
  static const Color gridLine = Color(0xFF2A2B2F);
  static const Color roomBorder = Color(0xFF48484A);
  static const Color leftSpeaker = Color(0xFF4F6EF7);
  static const Color rightSpeaker = Color(0xFFBF5AF2);
  static const Color listeningPos = Color(0xFF30D158);
  static const Color triangleLine = Color(0xFF4F6EF7);
  static const Color reflectionPoint = Color(0xFFFF9F0A);

  // Sweet-spot quality colours
  static const Color sweetSpotGreen = Color(0xFF34C759);
  static const Color sweetSpotYellow = Color(0xFFFF9F0A);
  static const Color sweetSpotRed = Color(0xFFFF453A);

  // Motion tokens
  static const Duration motionFast = Duration(milliseconds: 220);
  static const Duration motionMedium = Duration(milliseconds: 420);
  static const Duration motionSlow = Duration(milliseconds: 700);

  static const Curve easeStandard = Curves.easeOutCubic;
  static const Curve easeEmphasized = Curves.easeInOutCubic;

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      fontFamily:
          'SF Pro Display', // falls back gracefully to system sans-serif
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
        hintStyle: const TextStyle(color: textTertiary, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: const BorderSide(color: border, width: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: primary,
        thumbColor: Colors.white,
        overlayColor: Color(0x334F6EF7),
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4),
        titleMedium: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3),
        titleSmall: TextStyle(
            color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 14),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
        bodySmall: TextStyle(color: textSecondary, fontSize: 11),
        labelLarge:
            TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: textSecondary, fontSize: 11),
        labelSmall: TextStyle(color: textTertiary, fontSize: 10),
      ),
    );
  }
}
