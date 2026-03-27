import 'package:flutter/material.dart';

class AppTheme {
  // CRED-Inspired True Black Palette
  static const Color bgColor = Color(0xFF000000);
  static const Color panelBg = Color(0xFF0A0A0A);
  static const Color cardBg = Color(0xFF111111);
  static const Color surfaceLight = Color(0xFF1A1A1A);

  // Accent Colors — Warm Metallics
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentChampagne = Color(0xFFF5E6CC);
  static const Color accentSilver = Color(0xFFC0C0C0);
  static const Color accentColor = accentGold; // Primary accent

  // Legacy aliases for compatibility
  static const Color accentPurple = Color(0xFFB8860B); // Dark goldenrod

  // Text Colors
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF3D3D3D);

  // Borders
  static const Color glassBorder = Color(0x0AFFFFFF); // 4% white
  static const Color subtleBorder = Color(0x14FFFFFF); // 8% white

  // Semantic Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFE6A817);
  static const Color danger = Color(0xFFE74C3C);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      fontFamily: 'Outfit',
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentChampagne,
        surface: panelBg,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1.0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgColor,
        selectedItemColor: accentGold,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: glassBorder),
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1.5,
          fontSize: 36,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.0,
          fontSize: 28,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Outfit',
          color: textPrimary,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Outfit',
          color: textSecondary,
          fontSize: 14,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Outfit',
          color: textSecondary,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Premium Gold Gradient
  static LinearGradient get premiumGradient => const LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF5E6CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle dark gradient for cards
  static LinearGradient get cardGradient => const LinearGradient(
    colors: [Color(0xFF111111), Color(0xFF0D0D0D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Silver shimmer gradient
  static LinearGradient get silverGradient => const LinearGradient(
    colors: [Color(0xFF8C8C8C), Color(0xFFC0C0C0), Color(0xFF8C8C8C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration get glassDecoration => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: glassBorder),
  );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: glassBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Gold accent glow for CTAs
  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: accentGold.withValues(alpha: 0.25),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];
}
