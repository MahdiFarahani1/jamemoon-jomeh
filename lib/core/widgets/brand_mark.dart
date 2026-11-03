import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Jamemoon's smiling conversation-die: friends, games and one shared laugh.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: BrandMarkPainter()),
    ),
  );
}

class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final back = Path()
      ..moveTo(29, 29)
      ..lineTo(53, 29)
      ..quadraticBezierTo(72, 29, 72, 48)
      ..lineTo(72, 60)
      ..quadraticBezierTo(72, 79, 53, 79)
      ..lineTo(36, 79)
      ..lineTo(15, 91)
      ..lineTo(19, 75)
      ..quadraticBezierTo(10, 70, 10, 60)
      ..lineTo(10, 48)
      ..quadraticBezierTo(10, 29, 29, 29)
      ..close();
    canvas.drawPath(back, Paint()..color = AppColors.success);
    final face = Path()
      ..moveTo(48, 12)
      ..lineTo(70, 12)
      ..quadraticBezierTo(91, 12, 91, 33)
      ..lineTo(91, 49)
      ..quadraticBezierTo(91, 58, 84, 64)
      ..lineTo(88, 79)
      ..lineTo(67, 69)
      ..lineTo(48, 69)
      ..quadraticBezierTo(27, 69, 27, 49)
      ..lineTo(27, 33)
      ..quadraticBezierTo(27, 12, 48, 12)
      ..close();
    canvas.drawPath(
      face.shift(const Offset(0, 3)),
      Paint()..color = const Color(0xFF778ACB),
    );
    canvas.drawPath(
      face,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFD5DCFF), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(27, 12, 64, 57)),
    );
    final ink = Paint()..color = AppColors.background;
    canvas.drawCircle(const Offset(47, 34), 3.5, ink);
    canvas.drawCircle(const Offset(71, 34), 3.5, ink);
    canvas.drawPath(
      Path()
        ..moveTo(47, 47)
        ..quadraticBezierTo(59, 60, 71, 47),
      Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(39, 44),
      4,
      Paint()..color = AppColors.tabooPrimary,
    );
    canvas.drawCircle(
      const Offset(79, 44),
      4,
      Paint()..color = AppColors.tabooPrimary,
    );
    final spark = Path()
      ..moveTo(17, 5)
      ..quadraticBezierTo(19, 15, 29, 17)
      ..quadraticBezierTo(19, 19, 17, 29)
      ..quadraticBezierTo(15, 19, 5, 17)
      ..quadraticBezierTo(15, 15, 17, 5)
      ..close();
    canvas.drawPath(spark, Paint()..color = AppColors.accent);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BrandMarkPainter oldDelegate) => false;
}

/// Finite entrance motion, with no controller running during gameplay.
class PartyEntrance extends StatelessWidget {
  const PartyEntrance({
    super.key,
    required this.child,
    this.offset = 18,
    this.duration = const Duration(milliseconds: 550),
  });
  final Widget child;
  final double offset;
  final Duration duration;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, offset * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class TrophyArt extends StatelessWidget {
  const TrophyArt({super.key, this.size = 160});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/art/party-trophy.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
    ),
  );
}
