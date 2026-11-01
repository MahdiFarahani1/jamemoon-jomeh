import 'dart:math';
import 'package:flutter/material.dart';

// High performance Confetti Celebration Effect (Zero setState)
class ConfettiOverlay extends StatelessWidget {
  final Widget child;
  final bool showConfetti;

  const ConfettiOverlay({
    super.key,
    required this.child,
    required this.showConfetti,
  });

  @override
  Widget build(BuildContext context) {
    if (!showConfetti) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 3),
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(progress: value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final colors = [
      const Color(0xFFFF5252),
      const Color(0xFFFFD740),
      const Color(0xFF69F0AE),
      const Color(0xFF40C4FF),
      const Color(0xFFE040FB),
      const Color(0xFFFF6E40),
    ];

    for (int i = 0; i < 70; i++) {
      final startX = size.width * (0.2 + 0.6 * random.nextDouble());
      final spreadX = (random.nextDouble() - 0.5) * size.width * 0.8;
      final speedY = 0.5 + random.nextDouble() * 0.8;

      final currentX = startX + spreadX * progress;
      final currentY = -20 + (size.height + 40) * (progress * speedY);
      final rotation = progress * pi * 4 * (i % 2 == 0 ? 1 : -1);

      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity((1.0 - progress * 0.4).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(rotation);

      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 4.0, paint);
      } else {
        canvas.drawRect(const Rect.fromLTWH(-6, -3, 12, 6), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

