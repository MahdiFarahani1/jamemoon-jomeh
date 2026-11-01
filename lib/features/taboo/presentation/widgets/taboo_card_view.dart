import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../data/taboo_card_model.dart';

// Styled card displaying main word and 5 forbidden words
class TabooCardView extends StatelessWidget {
  final TabooCard card;

  const TabooCardView({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.tabooPrimary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.tabooPrimary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tabooPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              card.category,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.tabooPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main target word
          Text(
            card.word,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.textHeadline,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.surfaceBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'کلمات ممنوعه',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.surfaceBorder)),
            ],
          ),
          const SizedBox(height: 14),

          // 5 Forbidden words
          ...card.forbiddenWords.map((word) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    word,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textHeadline,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
