import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class GameAtmosphere extends StatefulWidget {
  const GameAtmosphere({super.key, required this.gameKey, required this.child});

  final String gameKey;
  final Widget child;

  @override
  State<GameAtmosphere> createState() => _GameAtmosphereState();
}

class _GameAtmosphereState extends State<GameAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool? _motionDisabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_motionDisabled == disabled) return;
    _motionDisabled = disabled;
    if (disabled) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      if (widget.gameKey == 'hot_potato') {
        // The bomb arena is a live fuse and must outlive the first cycle.
        _controller.repeat();
      } else if (!_controller.isCompleted) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final t = _controller.value;
      final shake = widget.gameKey == 'hot_potato' && !_motionDisabled!
          ? Offset(
              math.sin(t * math.pi * 18) * 1.2,
              math.cos(t * math.pi * 22) * .7,
            )
          : Offset.zero;
      return Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _AtmospherePainter(
                      gameKey: widget.gameKey,
                      progress: t,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(offset: shake, child: child),
          ),
        ],
      );
    },
  );
}

class GameResultCelebration extends StatefulWidget {
  const GameResultCelebration({
    super.key,
    required this.gameKey,
    required this.child,
  });

  final String gameKey;
  final Widget child;

  @override
  State<GameResultCelebration> createState() => _GameResultCelebrationState();
}

class _GameResultCelebrationState extends State<GameResultCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: widget.child),
      Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _ResultEffectPainter(
                    gameKey: widget.gameKey,
                    progress: _controller.value,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter({required this.gameKey, required this.progress});

  final String gameKey;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = AppColors.gameAccent(gameKey);
    switch (gameKey) {
      case 'hot_potato':
        _bomb(canvas, size, accent);
      case 'charades':
        _stage(canvas, size, accent);
      case 'taboo':
        _taboo(canvas, size, accent);
      case 'drawing':
        _drawing(canvas, size, accent);
      case 'five_seconds':
        _speed(canvas, size, accent);
    }
  }

  void _bomb(Canvas canvas, Size size, Color accent) {
    final smoke = Paint()
      ..color = const Color(0xFFB5232F).withValues(alpha: .08);
    for (var i = 0; i < 5; i++) {
      final x = size.width * (.08 + i * .22);
      final y = size.height * (.2 + .08 * math.sin(progress * math.pi * 2 + i));
      canvas.drawCircle(Offset(x, y), 28 + i * 7, smoke);
    }
    final spark = Paint()
      ..color = const Color(0xFFFFC857).withValues(alpha: .55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final angle = i * math.pi * 2 / 9 + progress * math.pi * 2;
      final center = Offset(size.width * .88, size.height * .18);
      final start = center + Offset(math.cos(angle), math.sin(angle)) * 16;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * 28;
      canvas.drawLine(start, end, spark);
    }
  }

  void _stage(Canvas canvas, Size size, Color accent) {
    final beam = Path()
      ..moveTo(size.width * .32, 0)
      ..lineTo(size.width * .08, size.height)
      ..lineTo(size.width * .56, size.height)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withValues(alpha: .13), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    final curtain = Paint()..color = accent.withValues(alpha: .12);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * .14, 0)
        ..quadraticBezierTo(size.width * .2, size.height * .5, 0, size.height)
        ..close(),
      curtain,
    );
    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * .14, 0)
        ..quadraticBezierTo(size.width * .2, size.height * .5, 0, size.height)
        ..close(),
      curtain,
    );
    canvas.restore();
  }

  void _taboo(Canvas canvas, Size size, Color accent) {
    final card = Paint()
      ..color = accent.withValues(alpha: .08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      final y = (size.height * (.12 + i * .17) + progress * 18) % size.height;
      canvas.save();
      canvas.translate(i.isEven ? 22 : size.width - 66, y);
      canvas.rotate((i.isEven ? -1 : 1) * .12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 44, 58),
          const Radius.circular(9),
        ),
        card,
      );
      canvas.restore();
    }
    canvas.drawLine(
      Offset(size.width * .78, size.height * .08),
      Offset(size.width * .96, size.height * .28),
      Paint()
        ..color = const Color(0xFFFF4D67).withValues(alpha: .35)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawing(Canvas canvas, Size size, Color accent) {
    const colors = [Color(0xFFFF5E7D), Color(0xFF54D6C5), Color(0xFFFFC857)];
    for (var i = 0; i < colors.length; i++) {
      final pulse = 1 + math.sin(progress * math.pi * 2 + i) * .12;
      final center = Offset(
        i == 1 ? size.width * .9 : size.width * (.06 + i * .18),
        size.height * (.18 + i * .3),
      );
      canvas.drawCircle(
        center,
        (16 + i * 5) * pulse,
        Paint()..color = colors[i].withValues(alpha: .13),
      );
      for (var j = 0; j < 4; j++) {
        canvas.drawCircle(
          center + Offset(math.cos(j * 1.7), math.sin(j * 1.7)) * (25 + i * 4),
          3 + j.toDouble(),
          Paint()..color = colors[i].withValues(alpha: .15),
        );
      }
    }
    final pencilX = size.width * (.2 + .6 * progress);
    canvas.save();
    canvas.translate(pencilX, size.height * .92);
    canvas.rotate(-.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-30, -4, 60, 8),
        const Radius.circular(3),
      ),
      Paint()..color = accent.withValues(alpha: .28),
    );
    canvas.restore();
  }

  void _speed(Canvas canvas, Size size, Color accent) {
    final center = Offset(size.width * .88, size.height * .16);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 54),
      math.pi * .75,
      math.pi * 1.5,
      false,
      Paint()
        ..color = accent.withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    final angle = math.pi * (.75 + 1.5 * progress);
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * 42,
      Paint()
        ..color = const Color(0xFFFFD166).withValues(alpha: .65)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final bolt = Path()
      ..moveTo(size.width * .05, size.height * .16)
      ..lineTo(size.width * .14, size.height * .16)
      ..lineTo(size.width * .09, size.height * .27)
      ..lineTo(size.width * .19, size.height * .27)
      ..lineTo(size.width * .06, size.height * .43)
      ..lineTo(size.width * .1, size.height * .31)
      ..lineTo(size.width * .02, size.height * .31)
      ..close();
    canvas.drawPath(
      bolt,
      Paint()..color = const Color(0xFFFFD166).withValues(alpha: .2),
    );
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.gameKey != gameKey || oldDelegate.progress != progress;
}

class _ResultEffectPainter extends CustomPainter {
  const _ResultEffectPainter({required this.gameKey, required this.progress});

  final String gameKey;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    switch (gameKey) {
      case 'hot_potato':
        _explosion(canvas, size);
      case 'taboo':
        _fallingCards(canvas, size);
      case 'drawing':
        _paintSplash(canvas, size);
      case 'charades':
        _spotlights(canvas, size);
      case 'five_seconds':
        _electric(canvas, size);
      default:
        _stars(canvas, size);
    }
  }

  void _explosion(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .22);
    final eased = Curves.easeOut.transform(progress);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        center,
        (35 + i * 30) * eased,
        Paint()
          ..color = [
            const Color(0xFFFFD166),
            const Color(0xFFFF7A00),
            const Color(0xFFE92F45),
          ][i].withValues(alpha: (1 - progress).clamp(0, 1) * .28),
      );
    }
    final spark = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: 1 - progress * .7)
      ..strokeWidth = 3;
    for (var i = 0; i < 14; i++) {
      final angle = i * math.pi * 2 / 14;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * 30,
        center +
            Offset(math.cos(angle), math.sin(angle)) * (45 + progress * 110),
        spark,
      );
    }
  }

  void _fallingCards(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.tabooPrimary.withValues(alpha: .24);
    for (var i = 0; i < 14; i++) {
      final x = size.width * ((i * .173) % 1);
      final y = size.height * ((progress * 1.35 + i * .113) % 1);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 3 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -17, 24, 34),
          const Radius.circular(5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _paintSplash(Canvas canvas, Size size) {
    const colors = [Color(0xFFFF5E7D), Color(0xFF42C6B7), Color(0xFFFFC857)];
    for (var i = 0; i < 18; i++) {
      final angle = i * math.pi * 2 / 18;
      final radius = progress * (50 + (i % 5) * 24);
      final center = Offset(size.width / 2, size.height * .24);
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        4 + (i % 4) * 2,
        Paint()..color = colors[i % colors.length].withValues(alpha: .5),
      );
    }
  }

  void _spotlights(Canvas canvas, Size size) {
    for (var i = 0; i < 2; i++) {
      final topX = i == 0 ? size.width * .18 : size.width * .82;
      final bottomX =
          size.width * (.5 + math.sin(progress * math.pi * 2 + i) * .22);
      final path = Path()
        ..moveTo(topX - 12, 0)
        ..lineTo(topX + 12, 0)
        ..lineTo(bottomX + 100, size.height)
        ..lineTo(bottomX - 100, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.white.withValues(alpha: .18), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Offset.zero & size),
      );
    }
  }

  void _electric(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var side in [0.08, 0.92]) {
      final x = size.width * side;
      final path = Path()..moveTo(x, size.height * .08);
      for (var i = 1; i < 8; i++) {
        path.lineTo(
          x + (i.isEven ? -10 : 10),
          size.height * (.08 + i * .08 * progress),
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  void _stars(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.accent.withValues(alpha: .45);
    for (var i = 0; i < 12; i++) {
      canvas.drawCircle(
        Offset(
          size.width * ((i * .19) % 1),
          size.height * ((i * .13 + progress) % 1),
        ),
        2 + i % 3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ResultEffectPainter oldDelegate) =>
      oldDelegate.gameKey != gameKey || oldDelegate.progress != progress;
}
