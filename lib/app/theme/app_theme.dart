import 'package:flutter/material.dart';

/// Central smooth claymorphism design system for Cut the Cable.
/// Uses soft ambient drop shadows + inner white highlights for seamless background blending.
class AppTheme {
  // ── Brand colours ────────────────────────────────────────────────────────
  static const Color background    = Color(0xFFFDF5EA);
  static const Color primary       = Color(0xFFFF7A45);
  static const Color primaryOrange = Color(0xFFFF7A45);
  static const Color orangeLip     = Color(0xFFE65100);
  static const Color secondary     = Color(0xFF8B7CF6);
  static const Color accent        = Color(0xFFFFC837);
  static const Color goldYellow    = Color(0xFFFFC837);
  static const Color goldLip       = Color(0xFFF59E0B);
  static const Color success       = Color(0xFF4CD964);
  static const Color successGreen  = Color(0xFF4CD964);
  static const Color greenLip      = Color(0xFF16A34A);
  static const Color danger        = Color(0xFFF16B73);
  static const Color textDark      = Color(0xFF2D2638);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color cardBg        = Color(0xFFFFFFFF);
  static const Color cardBorder    = Color(0xFFF0E4D7);
  static const Color cardLip       = Color(0xFFE2D0BE);

  // ── Smooth Claymorphism & 3D tokens ────────────────────────────────────
  static const double cornerRadius = 22.0;
  static const double buttonCorner = 32.0;

  /// Soft, smooth claymorphic dual shadows (blends seamlessly into background)
  static List<BoxShadow> clayShadow(Color color, {double elevation = 6.0}) => [
        // Soft ambient drop shadow
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          offset: Offset(0, elevation),
          blurRadius: elevation * 2.2,
          spreadRadius: -1,
        ),
        // Soft top/inner glow
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.8),
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
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
      );

  // Smooth 3D Cards & Buttons (no harsh solid cutouts, smooth ambient depth)
  static BoxDecoration card3D() {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        // Soft bottom lip
        BoxShadow(
          color: Color(0x33DFCBB8),
          offset: Offset(0, 6),
          blurRadius: 10,
          spreadRadius: 0,
        ),
        // Subtle ambient shadow
        BoxShadow(
          color: Color(0x1A000000),
          offset: Offset(0, 3),
          blurRadius: 8,
        ),
      ],
    );
  }

  static BoxDecoration primaryButton3D() {
    return BoxDecoration(
      color: primaryOrange,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: orangeLip.withValues(alpha: 0.45),
          offset: const Offset(0, 6),
          blurRadius: 12,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.35),
          offset: const Offset(0, -2),
          blurRadius: 4,
        ),
      ],
    );
  }

  static BoxDecoration successButton3D() {
    return BoxDecoration(
      color: successGreen,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: greenLip.withValues(alpha: 0.45),
          offset: const Offset(0, 6),
          blurRadius: 12,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.35),
          offset: const Offset(0, -2),
          blurRadius: 4,
        ),
      ],
    );
  }

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

/// Alias class for backward compatibility
typedef GameTheme = AppTheme;
