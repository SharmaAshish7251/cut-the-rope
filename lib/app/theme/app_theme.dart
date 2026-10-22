import 'package:flutter/material.dart';

/// Central claymorphism design system for Cut the Cable.
class AppTheme {
  // ── Brand colours ────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFF4E8);
  static const Color primary    = Color(0xFFFF8A65);
  static const Color secondary  = Color(0xFF8B7CF6);
  static const Color accent     = Color(0xFFFFD166);
  static const Color success    = Color(0xFF65C98B);
  static const Color danger     = Color(0xFFF16B73);
  static const Color textDark   = Color(0xFF493A50);
  static const Color surface    = Color(0xFFFFFFFF);

  // ── Claymorphism tokens ────────────────────────────────────────────────
  static const double cornerRadius = 24.0;
  static const double buttonCorner = 32.0;

  static List<BoxShadow> clayShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          offset: const Offset(0, 6),
          blurRadius: 12,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.6),
          offset: const Offset(0, -2),
          blurRadius: 6,
        ),
      ];

  static BoxDecoration clayBox({
    Color color = surface,
    double radius = cornerRadius,
    Color? borderColor,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: clayShadow(color),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
      );

  // ── Text styles ────────────────────────────────────────────────────────
  // Headings & Titles -> Local Fredoka TTF assets
  static const _fredokaBase = TextStyle(fontFamily: 'Fredoka', color: textDark);
  static const _nunitoBase  = TextStyle(fontFamily: 'Nunito', color: textDark);

  static TextStyle display  = _fredokaBase.copyWith(fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: 0.5);
  static TextStyle headline = _fredokaBase.copyWith(fontSize: 28, fontWeight: FontWeight.w600);
  static TextStyle title    = _fredokaBase.copyWith(fontSize: 22, fontWeight: FontWeight.w600);
  static TextStyle label    = _fredokaBase.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.8);

  // Body & Descriptions -> Local Nunito TTF assets
  static TextStyle body     = _nunitoBase.copyWith(fontSize: 16, fontWeight: FontWeight.w500);
  static TextStyle caption  = _nunitoBase.copyWith(fontSize: 12, fontWeight: FontWeight.w400);

  // ── MaterialApp ThemeData ──────────────────────────────────────────────
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          tertiary: accent,
          surface: surface,
          error: danger,
        ),
        textTheme: TextTheme(
          displayLarge:  display,
          headlineLarge: headline,
          titleLarge:    title,
          bodyLarge:     body,
          labelLarge:    label,
          bodySmall:     caption,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonCorner),
            ),
            elevation: 6,
            shadowColor: primary.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: label.copyWith(fontSize: 16, color: Colors.white),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          titleTextStyle: headline.copyWith(fontSize: 22),
          iconTheme: const IconThemeData(color: textDark),
        ),
      );
}
