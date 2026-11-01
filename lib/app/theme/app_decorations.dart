import 'package:flutter/material.dart';
import 'app_colors.dart';

// Common visual decorations, shadows, and borders
class AppDecorations {
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 28.0;

  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);

  static final BoxDecoration cardBox = BoxDecoration(
    color: AppColors.surface,
    borderRadius: borderRadiusMedium,
    border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration gradientCard({required Gradient gradient}) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadiusLarge,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration button3D({
    required Color color,
    Color? shadowColor,
  }) {
    final baseShadow = shadowColor ?? Color.lerp(color, Colors.black, 0.45)!;
    return BoxDecoration(
      color: color,
      borderRadius: borderRadiusMedium,
      boxShadow: [
        BoxShadow(
          color: baseShadow,
          offset: const Offset(0, 5),
          blurRadius: 0,
        ),
      ],
    );
  }
}
