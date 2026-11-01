import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

// Circular Countdown Timer for Mini-Games (Zero setState)
class CustomTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;
  final Color? activeColor;

  const CustomTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 100,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final isCritical = remainingSeconds <= 5;
    final ringColor = isCritical
        ? AppColors.error
        : (activeColor ?? AppColors.accent);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              color: AppColors.surfaceLight,
            ),
          ),
          // Active animated progress
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: ringColor,
            ),
          ),
          // Timer text in center
          Text(
            '$remainingSeconds',
            style: AppTypography.timerDigits.copyWith(
              fontSize: size * 0.4,
              color: isCritical ? AppColors.error : AppColors.textHeadline,
            ),
          ),
        ],
      ),
    );
  }
}
