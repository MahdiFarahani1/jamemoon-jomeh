import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/game_emblem.dart';

class BombAnimationView extends StatelessWidget {
  const BombAnimationView({
    super.key,
    required this.tensionRatio,
    required this.isExploded,
  });
  final double tensionRatio;
  final bool isExploded;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final tension = tensionRatio.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide.clamp(80.0, 240.0);
        return Center(
          child: AnimatedScale(
            scale: reduced
                ? 1
                : isExploded
                ? 1.06
                : 1 + tension * .06,
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: size,
                  child: CustomPaint(painter: _FuseOrbit(tension)),
                ),
                AnimatedContainer(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isExploded ? AppColors.accent : AppColors.bombPrimary)
                            .withValues(
                              alpha: isExploded ? .3 : .06 + tension * .12,
                            ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                if (isExploded)
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: size * .55,
                    color: AppColors.accent,
                  )
                else
                  GameEmblem(gameKey: 'hot_potato', size: size * .82),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Atmospheric sparks follow tension without displaying remaining fuse time.
class _FuseOrbit extends CustomPainter {
  const _FuseOrbit(this.tension);
  final double tension;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .43;
    final paint = Paint()
      ..color = AppColors.bombPrimary.withValues(alpha: .25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, paint);
    for (var i = 0; i < 4; i++) {
      final dx = i.isEven ? .18 : .82;
      final dy = i < 2 ? .2 : .8;
      final point = Offset(size.width * dx, size.height * dy);
      canvas.drawCircle(
        point,
        3 + tension * 2,
        Paint()
          ..color = (i.isEven ? AppColors.accent : AppColors.bombPrimary)
              .withValues(alpha: .4 + tension * .5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FuseOrbit oldDelegate) =>
      oldDelegate.tension != tension;
}
