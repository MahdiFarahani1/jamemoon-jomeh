import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'custom_timer_widget.dart';

class RoundStatus extends StatelessWidget {
  const RoundStatus({
    super.key,
    required this.score,
    required this.remaining,
    required this.totalSeconds,
    required this.round,
    required this.totalRounds,
    required this.color,
    this.quick = false,
  });
  final int score, remaining, totalSeconds, round, totalRounds;
  final Color color;
  final bool quick;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        Expanded(
          child: _Stat(label: 'امتیاز این دور', value: '$score', color: color),
        ),
        const SizedBox(width: 12),
        CustomTimerWidget(
          remainingSeconds: remaining,
          totalSeconds: totalSeconds,
          size: 74,
          activeColor: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(
            label: 'دور بازی',
            value: '$round از $totalRounds',
            color: AppColors.textHeadline,
          ),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: .9, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            value,
            key: ValueKey(value),
            style: AppTypography.headlineMedium.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
