import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class CustomTimerWidget extends StatelessWidget {
  const CustomTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 100,
    this.activeColor,
  });
  final int remainingSeconds, totalSeconds;
  final double size;
  final Color? activeColor;
  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0
        ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;
    final critical = remainingSeconds <= (totalSeconds <= 5 ? 2 : 5);
    final color = critical
        ? AppColors.error
        : (activeColor ?? AppColors.accent);
    return Semantics(
      label: '$remainingSeconds ثانیه باقی مانده',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: critical ? .12 : .06),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: size > 80 ? 6 : 4,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: AppColors.surfaceLight,
                  ),
                ),
              ),
              Text(
                '$remainingSeconds',
                style: AppTypography.timerDigits.copyWith(
                  fontSize: size * .36,
                  color: critical ? color : AppColors.textHeadline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
