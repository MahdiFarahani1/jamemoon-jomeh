import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

// Visual Bomb with pulsing fuse and explosion states (Zero setState)
class BombAnimationView extends StatelessWidget {
  final double tensionRatio;
  final bool isExploded;

  const BombAnimationView({
    super.key,
    required this.tensionRatio,
    required this.isExploded,
  });

  @override
  Widget build(BuildContext context) {
    if (isExploded) {
      return Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.2, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFFFEB3B),
                      Color(0xFFFF5722),
                      Color(0xFFD50000),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.whatshot_rounded,
                    size: 110,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Tension-based scaling
    final pulseScale = 1.0 + (tensionRatio * 0.18);
    final bombColor = Color.lerp(
      const Color(0xFF263238),
      const Color(0xFFD50000),
      tensionRatio,
    )!;

    return Center(
      child: Transform.scale(
        scale: pulseScale,
        child: SizedBox(
          width: 170,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fuse spark at top
              Positioned(
                top: 0,
                right: 50,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.8),
                        blurRadius: 14,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              // Fuse cord
              Positioned(
                top: 14,
                right: 58,
                child: Container(
                  width: 16,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange, width: 3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Bomb Cap
              Positioned(
                top: 36,
                child: Container(
                  width: 44,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Bomb Body
              Positioned(
                top: 46,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bombColor,
                    boxShadow: [
                      BoxShadow(
                        color: bombColor.withOpacity(0.6),
                        blurRadius: 26,
                        spreadRadius: tensionRatio * 6,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Bomb shine reflection
                      Positioned(
                        top: 24,
                        left: 28,
                        child: Container(
                          width: 22,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 54,
                        color: tensionRatio > 0.6 ? Colors.white : Colors.white24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
