import 'package:flutter/material.dart';

// Brand colors and gradients for Jam'emoon Jomeh! party game
class AppColors {
  // Main background & surfaces
  static const Color background = Color(0xFF0F0E17);
  static const Color surface = Color(0xFF1E1B2E);
  static const Color surfaceLight = Color(0xFF2C2744);
  static const Color surfaceBorder = Color(0xFF3F3765);

  // Brand accent colors
  static const Color primary = Color(0xFFFF8906);
  static const Color secondary = Color(0xFFF25F4C);
  static const Color accent = Color(0xFFFFD166);
  static const Color success = Color(0xFF06D6A0);
  static const Color error = Color(0xFFEF476F);
  static const Color info = Color(0xFF118AB2);

  // Text colors
  static const Color textHeadline = Color(0xFFFFFFFE);
  static const Color textParagraph = Color(0xFFA7A9BE);
  static const Color textMuted = Color(0xFF6C6F93);

  // 1. Taboo (حرف نزن، بفهمون!)
  static const Color tabooPrimary = Color(0xFFFF5722);
  static const Color tabooSecondary = Color(0xFFFF9800);
  static const LinearGradient tabooGradient = LinearGradient(
    colors: [Color(0xFFFF3D00), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 2. Hot Potato (بمب دست کیه؟)
  static const Color bombPrimary = Color(0xFFFF1744);
  static const Color bombSecondary = Color(0xFFD50000);
  static const LinearGradient bombGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFF651FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 3. Charades (پانتومیم انفجاری)
  static const Color charadesPrimary = Color(0xFF9C27B0);
  static const Color charadesSecondary = Color(0xFFE040FB);
  static const LinearGradient charadesGradient = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 4. 5-Second Rule (سه‌تا بگو!)
  static const Color fiveSecPrimary = Color(0xFF00E5FF);
  static const Color fiveSecSecondary = Color(0xFFFFEA00);
  static const LinearGradient fiveSecGradient = LinearGradient(
    colors: [Color(0xFF00B0FF), Color(0xFFFFD600)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 5. Drawing (نقاشی افتضاح!)
  static const Color drawPrimary = Color(0xFF00E676);
  static const Color drawSecondary = Color(0xFF00B0FF);
  static const LinearGradient drawGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Tournament (مسابقه پنجگانه)
  static const LinearGradient tournamentGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Card & Button Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
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
  ];
}

