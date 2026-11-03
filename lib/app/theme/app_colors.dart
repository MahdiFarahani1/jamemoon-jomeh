import 'package:flutter/material.dart';

// Brand colors and gradients for Jam'emoon Jomeh! party game
class AppColors {
  // Main background & surfaces
  static const Color background = Color(0xFF111522);
  static const Color surface = Color(0xFF1D2334);
  static const Color surfaceLight = Color(0xFF293249);
  static const Color surfaceBorder = Color(0xFF394258);

  // Brand accent colors
  static const Color primary = Color(0xFFB8C3FF);
  static const Color secondary = Color(0xFF83DEC2);
  static const Color accent = Color(0xFFFFD778);
  static const Color success = Color(0xFF83DEC2);
  static const Color error = Color(0xFFFF8E9B);
  static const Color info = Color(0xFF92CEFF);

  // Text colors
  static const Color textHeadline = Color(0xFFF7F7FC);
  static const Color textParagraph = Color(0xFFCFD3E2);
  static const Color textMuted = Color(0xFFA4ADC3);

  // 1. Taboo (حرف نزن، بفهمون!)
  static const Color tabooPrimary = Color(0xFFFFA18E);
  static const Color tabooSecondary = Color(0xFFFFCC9F);
  static const LinearGradient tabooGradient = LinearGradient(
    colors: [Color(0xFFB74E40), Color(0xFF73332F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 2. Hot Potato (بمب دست کیه؟)
  static const Color bombPrimary = Color(0xFFFF9BAA);
  static const Color bombSecondary = Color(0xFFE45C7C);
  static const LinearGradient bombGradient = LinearGradient(
    colors: [Color(0xFF9C3C62), Color(0xFF512F53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 3. Charades (پانتومیم انفجاری)
  static const Color charadesPrimary = Color(0xFFC9B3FF);
  static const Color charadesSecondary = Color(0xFFE5C5FF);
  static const LinearGradient charadesGradient = LinearGradient(
    colors: [Color(0xFF7252A4), Color(0xFF493B6C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 4. 5-Second Rule (سه‌تا بگو!)
  static const Color fiveSecPrimary = Color(0xFF98D7FF);
  static const Color fiveSecSecondary = Color(0xFFB9E9FF);
  static const LinearGradient fiveSecGradient = LinearGradient(
    colors: [Color(0xFF286B96), Color(0xFF26465F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 5. Drawing (نقاشی افتضاح!)
  static const Color drawPrimary = Color(0xFF83DEC2);
  static const Color drawSecondary = Color(0xFFB3F0CC);
  static const LinearGradient drawGradient = LinearGradient(
    colors: [Color(0xFF256F65), Color(0xFF254B4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Tournament (مسابقه پنجگانه)
  static const LinearGradient tournamentGradient = LinearGradient(
    colors: [Color(0xFF51452D), Color(0xFF302C32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Card & Button Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFF8A652A), Color(0xFF5D4325)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF695493), Color(0xFF364F82)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Team Colors
  static const List<Color> teamPalette = [
    Color(0xFFFF5252), // Red
    Color(0xFF448AFF), // Blue
    Color(0xFF69F0AE), // Mint Green
    Color(0xFFFFD740), // Yellow
    Color(0xFFE040FB), // Magenta
    Color(0xFFFFAB40), // Orange
    Color(0xFF26C6DA), // Cyan
    Color(0xFFB388FF), // Violet
  ];
  static Color gameAccent(String key) => switch (key) {
    'taboo' => tabooPrimary,
    'hot_potato' => bombPrimary,
    'charades' => charadesPrimary,
    'five_seconds' => fiveSecPrimary,
    'drawing' => drawPrimary,
    _ => accent,
  };
}
