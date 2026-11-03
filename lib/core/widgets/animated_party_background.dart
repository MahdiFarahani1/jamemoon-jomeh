import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'game_scene.dart';

/// Separate art direction for each arena. Static paint is isolated from clocks.
class AnimatedPartyBackground extends StatelessWidget {
  const AnimatedPartyBackground({
    super.key,
    required this.child,
    this.gameKey,
    this.score,
    this.roundKey,
  });
  final Widget child;
  final String? gameKey;
  final int? score;
  final Object? roundKey;
  @override
  Widget build(BuildContext context) {
    final accent = gameKey == null
        ? AppColors.primary
        : AppColors.gameAccent(gameKey!);
    final content = Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: ArenaPainter(gameKey: gameKey, accent: accent),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
    return score == null
        ? content
        : ScoreBurst(
            score: score!,
            roundKey: roundKey ?? gameKey ?? '',
            child: content,
          );
  }
}

class ArenaPainter extends CustomPainter {
  const ArenaPainter({required this.gameKey, required this.accent});
  final String? gameKey;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.8, -.75),
          radius: 1.4,
          colors: [
            Color.lerp(AppColors.background, accent, .20)!,
            AppColors.background,
          ],
        ).createShader(rect),
    );
    final stroke = Paint()
      ..color = accent.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    switch (gameKey) {
      case 'charades':
        for (final right in [false, true]) {
          final x = right ? size.width : 0.0;
          final beam = Path()
            ..moveTo(x, 0)
            ..lineTo(size.width * (right ? .15 : .85), size.height * .85)
            ..lineTo(size.width * (right ? .7 : .3), size.height * .85)
            ..close();
          canvas.drawPath(
            beam,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: .08),
                  accent.withValues(alpha: 0),
                ],
              ).createShader(rect),
          );
          for (var i = 0; i < 4; i++) {
            final dx = right ? size.width - i * 12 : i * 12.0;
            canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), stroke);
          }
        }
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height + 35),
            width: size.width * 1.7,
            height: 170,
          ),
          Paint()..color = accent.withValues(alpha: .07),
        );
      case 'drawing':
        for (var x = 12.0; x < size.width; x += 24) {
          for (var y = 12.0; y < size.height; y += 24) {
            canvas.drawCircle(
              Offset(x, y),
              1,
              Paint()..color = accent.withValues(alpha: .13),
            );
          }
        }
        for (var i = 0; i < 4; i++) {
          final y = size.height * (.23 + i * .18);
          canvas.drawPath(
            Path()
              ..moveTo(-12, y)
              ..cubicTo(15, y - 34, 32, y + 38, 50, y),
            Paint()
              ..color = accent.withValues(alpha: .18)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
          );
        }
      case 'five_seconds':
        for (var i = -4; i < 15; i++) {
          final x = i * 54.0;
          canvas.drawLine(
            Offset(x, 0),
            Offset(x - size.height * .3, size.height),
            stroke,
          );
        }
        final center = Offset(size.width / 2, size.height * .42);
        for (var i = 0; i < 24; i++) {
          final angle = i * math.pi / 12;
          final radius = size.width * .6;
          final dir = Offset(math.cos(angle), math.sin(angle));
          canvas.drawLine(
            center + dir * radius,
            center + dir * (radius + 10),
            stroke..strokeWidth = 2,
          );
        }
      case 'decoder':
        for (var i = 0; i < 8; i++) {
          final y = 40 + i * 96.0;
          final x = i.isEven ? 24.0 : size.width - 24;
          final dir = i.isEven ? 1 : -1;
          canvas.drawPath(
            Path()
              ..moveTo(x, y)
              ..lineTo(x + dir * 34, y)
              ..lineTo(x + dir * 55, y + 21)
              ..lineTo(x + dir * 55, y + 56),
            stroke,
          );
          canvas.drawCircle(Offset(x + dir * 55, y + 56), 4, stroke);
        }
      case 'hot_potato':
        final center = Offset(size.width / 2, size.height * .46);
        for (var i = 1; i < 6; i++) {
          canvas.drawCircle(center, i * 64.0, stroke);
        }
        for (var x = -30.0; x < size.width; x += 34) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + 24, size.height - 22),
            Paint()
              ..color = accent.withValues(alpha: .12)
              ..strokeWidth = 10,
          );
        }
      case 'taboo':
        for (var i = 0; i < 6; i++) {
          canvas.save();
          canvas.translate(i.isEven ? -22 : size.width - 58, i * 135.0 + 20);
          canvas.rotate(i.isEven ? -.16 : .16);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(0, 0, 90, 64),
              const Radius.circular(20),
            ),
            stroke,
          );
          canvas.drawPath(
            Path()
              ..moveTo(16, 64)
              ..lineTo(12, 80)
              ..lineTo(35, 64),
            stroke,
          );
          canvas.restore();
        }
      default:
        for (var i = 0; i < 10; i++) {
          canvas.drawCircle(
            Offset(i.isEven ? 15 : size.width - 15, 50 + i * 100.0),
            25 + i % 3 * 12.0,
            stroke,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant ArenaPainter oldDelegate) =>
      oldDelegate.gameKey != gameKey || oldDelegate.accent != accent;
}
