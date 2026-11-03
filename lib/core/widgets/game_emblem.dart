import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Small sculptural illustrations, painted at native resolution on every screen.
class GameEmblem extends StatelessWidget {
  const GameEmblem({super.key, required this.gameKey, this.size = 96});
  final String gameKey;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: Center(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _GameArtPainter(gameKey)),
        ),
      ),
    ),
  );
}

class _GameArtPainter extends CustomPainter {
  const _GameArtPainter(this.game);
  final String game;
  static const ink = Color(0xFF26334C);

  void _object(Canvas c, Path path, Color color, {bool shadow = true}) {
    if (shadow) {
      c.drawShadow(path, Colors.black.withValues(alpha: .45), 4, false);
    }
    c.save();
    c.translate(0, 3);
    c.drawPath(path, Paint()..color = Color.lerp(color, ink, .26)!);
    c.restore();
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(color, Colors.white, .4)!,
            color,
            Color.lerp(color, ink, .1)!,
          ],
          stops: const [0, .55, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(path.getBounds()),
    );
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = Colors.white.withValues(alpha: .4),
    );
  }

  void _line(Canvas c, List<Offset> points, Color color, double width) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _round(Rect rect, double radius) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  void _spark(Canvas c, Offset p, double s, Color color) {
    final path = Path()
      ..moveTo(p.dx, p.dy - s)
      ..quadraticBezierTo(p.dx + s * .2, p.dy - s * .2, p.dx + s, p.dy)
      ..quadraticBezierTo(p.dx + s * .2, p.dy + s * .2, p.dx, p.dy + s)
      ..quadraticBezierTo(p.dx - s * .2, p.dy + s * .2, p.dx - s, p.dy)
      ..quadraticBezierTo(p.dx - s * .2, p.dy - s * .2, p.dx, p.dy - s)
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 120, size.height / 120);
    final color = AppColors.gameAccent(game);
    c.drawOval(
      const Rect.fromLTWH(24, 98, 76, 9),
      Paint()
        ..color = Colors.black.withValues(alpha: .12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    _spark(c, const Offset(100, 27), 7, AppColors.accent);
    c.drawCircle(
      const Offset(17, 74),
      3,
      Paint()..color = color.withValues(alpha: .8),
    );
    switch (game) {
      case 'taboo':
        c.save();
        c.translate(60, 60);
        c.rotate(-.12);
        c.translate(-60, -60);
        _object(c, _round(const Rect.fromLTWH(20, 22, 78, 64), 22), color);
        _object(
          c,
          Path()
            ..moveTo(36, 81)
            ..lineTo(33, 101)
            ..quadraticBezierTo(48, 94, 55, 82)
            ..close(),
          color,
          shadow: false,
        );
        for (final x in [40.0, 59.0, 78.0]) {
          c.drawCircle(
            Offset(x, 53),
            5,
            Paint()..color = ink.withValues(alpha: .7),
          );
          c.drawCircle(
            Offset(x - 1, 51),
            1.3,
            Paint()..color = Colors.white.withValues(alpha: .4),
          );
        }
        _line(
          c,
          [const Offset(32, 36), const Offset(40, 32)],
          Colors.white.withValues(alpha: .55),
          3,
        );
        c.restore();
      case 'hot_potato':
        _line(
          c,
          [
            const Offset(61, 40),
            const Offset(62, 25),
            const Offset(76, 22),
            const Offset(79, 13),
          ],
          AppColors.accent,
          5,
        );
        _spark(c, const Offset(81, 12), 9, AppColors.accent);
        _object(c, _round(const Rect.fromLTWH(47, 33, 26, 15), 5), color);
        _object(c, Path()..addOval(const Rect.fromLTWH(24, 40, 74, 64)), color);
        c.drawOval(
          const Rect.fromLTWH(36, 49, 18, 10),
          Paint()..color = Colors.white.withValues(alpha: .45),
        );
        c.drawCircle(const Offset(48, 73), 3.4, Paint()..color = ink);
        c.drawCircle(const Offset(72, 73), 3.4, Paint()..color = ink);
        _line(c, [const Offset(57, 85), const Offset(63, 85)], ink, 3);
      case 'charades':
        c.save();
        c.translate(65, 62);
        c.rotate(.18);
        c.translate(-65, -62);
        final back = Path()
          ..moveTo(49, 21)
          ..quadraticBezierTo(76, 29, 99, 21)
          ..lineTo(97, 58)
          ..quadraticBezierTo(77, 86, 51, 58)
          ..close();
        _object(c, back, const Color(0xFF9DAEFF));
        _line(c, [const Offset(61, 41), const Offset(67, 39)], ink, 4);
        _line(c, [const Offset(82, 39), const Offset(88, 41)], ink, 4);
        c.restore();
        c.save();
        c.translate(47, 65);
        c.rotate(-.15);
        c.translate(-47, -65);
        final face = Path()
          ..moveTo(17, 42)
          ..quadraticBezierTo(43, 49, 76, 42)
          ..lineTo(72, 78)
          ..quadraticBezierTo(48, 111, 22, 79)
          ..close();
        _object(c, face, color);
        c.drawOval(const Rect.fromLTWH(29, 59, 9, 7), Paint()..color = ink);
        c.drawOval(const Rect.fromLTWH(55, 59, 9, 7), Paint()..color = ink);
        c.drawArc(
          const Rect.fromLTWH(34, 67, 26, 19),
          0,
          3.14,
          false,
          Paint()
            ..color = ink
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
        c.restore();
      case 'five_seconds':
        _object(
          c,
          _round(const Rect.fromLTWH(48, 15, 24, 10), 4),
          AppColors.accent,
        );
        _line(c, [const Offset(60, 25), const Offset(60, 33)], color, 9);
        _line(
          c,
          [const Offset(87, 36), const Offset(93, 30)],
          AppColors.accent,
          8,
        );
        _object(c, Path()..addOval(const Rect.fromLTWH(21, 30, 78, 75)), color);
        c.drawCircle(
          const Offset(60, 67),
          29,
          Paint()..color = const Color(0xFFF0F7FF),
        );
        for (final p in [
          const Offset(60, 43),
          const Offset(36, 67),
          const Offset(60, 91),
          const Offset(84, 67),
        ]) {
          c.drawCircle(p, 2, Paint()..color = ink.withValues(alpha: .35));
        }
        _line(
          c,
          [const Offset(60, 48), const Offset(60, 67), const Offset(72, 75)],
          ink,
          5,
        );
        c.drawCircle(const Offset(60, 67), 4, Paint()..color = color);
      case 'drawing':
        c.save();
        c.translate(60, 60);
        c.rotate(.58);
        c.translate(-60, -60);
        _object(c, _round(const Rect.fromLTWH(46, 17, 27, 65), 6), color);
        _object(
          c,
          _round(const Rect.fromLTWH(46, 15, 27, 18), 6),
          AppColors.tabooPrimary,
        );
        _object(
          c,
          _round(const Rect.fromLTWH(46, 31, 27, 9), 1),
          const Color(0xFFDCE5EC),
          shadow: false,
        );
        _object(
          c,
          Path()
            ..moveTo(46, 81)
            ..lineTo(73, 81)
            ..lineTo(59.5, 106)
            ..close(),
          const Color(0xFFF6D5AA),
        );
        c.drawPath(
          Path()
            ..moveTo(54, 97)
            ..lineTo(65, 97)
            ..lineTo(59.5, 107)
            ..close(),
          Paint()..color = ink,
        );
        _line(
          c,
          [const Offset(51, 46), const Offset(51, 74)],
          Colors.white.withValues(alpha: .5),
          3,
        );
        c.restore();
      case 'decoder':
        c.save();
        c.translate(60, 60);
        c.rotate(-.08);
        c.translate(-60, -60);
        final shackle = Path()
          ..moveTo(39, 54)
          ..lineTo(39, 36)
          ..arcToPoint(const Offset(81, 36), radius: const Radius.circular(21))
          ..lineTo(81, 54)
          ..lineTo(72, 54)
          ..lineTo(72, 38)
          ..arcToPoint(const Offset(48, 38), radius: const Radius.circular(12))
          ..lineTo(48, 54)
          ..close();
        _object(c, shackle, const Color(0xFFD3DCE8));
        _object(
          c,
          _round(const Rect.fromLTWH(26, 46, 68, 53), 16),
          color,
        );
        final innerPlate = _round(const Rect.fromLTWH(34, 54, 52, 37), 10);
        c.drawPath(
          innerPlate,
          Paint()..color = ink.withValues(alpha: .22),
        );
        c.drawPath(
          innerPlate,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white.withValues(alpha: .25),
        );
        final keyhole = Path()
          ..addOval(const Rect.fromLTWH(55, 61, 10, 10))
          ..moveTo(57, 69)
          ..lineTo(56, 81)
          ..lineTo(64, 81)
          ..lineTo(63, 69)
          ..close();
        c.drawShadow(keyhole, Colors.black, 2, false);
        c.drawPath(keyhole, Paint()..color = ink);
        _line(
          c,
          [const Offset(33, 52), const Offset(43, 50)],
          Colors.white.withValues(alpha: .6),
          3,
        );
        for (final x in [42.0, 78.0]) {
          c.drawCircle(Offset(x, 72), 2.5, Paint()..color = ink.withValues(alpha: .45));
          c.drawCircle(Offset(x, 71.5), 1, Paint()..color = Colors.white.withValues(alpha: .5));
        }
        c.restore();
      default:
        _object(
          c,
          Path()
            ..moveTo(60, 16)
            ..lineTo(74, 44)
            ..lineTo(104, 49)
            ..lineTo(82, 71)
            ..lineTo(87, 101)
            ..lineTo(60, 87)
            ..lineTo(33, 101)
            ..lineTo(38, 71)
            ..lineTo(16, 49)
            ..lineTo(46, 44)
            ..close(),
          AppColors.accent,
        );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _GameArtPainter oldDelegate) =>
      oldDelegate.game != game;
}
