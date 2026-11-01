import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

// Dynamic ambient party background with floating geometric particles (Zero setState)
class AnimatedPartyBackground extends StatelessWidget {
  final Widget child;

  const AnimatedPartyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark party surface
        Positioned.fill(
          child: Container(
            color: AppColors.background,
          ),
        ),
        // Ambient soft radial gradient glow
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Subtle floating particles painter
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _PartyShapesPainter(),
            ),
          ),
        ),
        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _PartyShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(12345);
    final paint = Paint()..style = PaintingStyle.fill;

    final colors = [
      AppColors.primary.withOpacity(0.12),
      AppColors.secondary.withOpacity(0.12),
      AppColors.accent.withOpacity(0.10),
      AppColors.success.withOpacity(0.10),
      AppColors.info.withOpacity(0.10),
    ];

    for (int i = 0; i < 24; i++) {
      paint.color = colors[i % colors.length];
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final shapeType = i % 3;

      if (shapeType == 0) {
        // Floating circle
        final radius = 3.0 + random.nextDouble() * 5.0;
        canvas.drawCircle(Offset(x, y), radius, paint);
      } else if (shapeType == 1) {
        // Floating diamond
        final s = 4.0 + random.nextDouble() * 6.0;
        final path = Path()
          ..moveTo(x, y - s)
          ..lineTo(x + s, y)
          ..lineTo(x, y + s)
          ..lineTo(x - s, y)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        // Ring / Hollow Circle
        final strokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = colors[i % colors.length];
        canvas.drawCircle(Offset(x, y), 5.0 + random.nextDouble() * 6.0, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
