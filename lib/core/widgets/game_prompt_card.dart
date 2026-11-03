import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'game_emblem.dart';

/// A readable, scrollable challenge card even with accessibility text sizing.
class GamePromptCard extends StatelessWidget {
  const GamePromptCard({
    super.key,
    required this.gameKey,
    required this.category,
    required this.prompt,
    this.points,
    this.hint,
  });
  final String gameKey, category, prompt;
  final int? points;
  final String? hint;
  @override
  Widget build(BuildContext context) {
    final accent = AppColors.gameAccent(gameKey);
    final isStage = gameKey == 'charades';
    final ink = isStage ? const Color(0xFF32234D) : AppColors.textHeadline;
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isStage ? const Color(0xFFF5EDFF) : const Color(0xFF24445F),
              isStage ? const Color(0xFFE4D5FA) : const Color(0xFF1D283D),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: .3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _Badge(label: category, color: isStage ? ink : accent),
                if (points != null)
                  _Badge(
                    label: '$points امتیاز',
                    color: isStage ? const Color(0xFF75501F) : AppColors.accent,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GameEmblem(gameKey: gameKey, size: 72),
            const SizedBox(height: 16),
            Text(
              prompt,
              style: AppTypography.gameCardTitle.copyWith(
                fontSize: 30,
                color: ink,
              ),
              textAlign: TextAlign.center,
            ),
            if (hint != null) ...[
              const SizedBox(height: 22),
              Text(
                hint!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isStage
                      ? const Color(0xFF554467)
                      : AppColors.textParagraph,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: AppTypography.bodySmall.copyWith(color: color),
      textAlign: TextAlign.center,
    ),
  );
}
