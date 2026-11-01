import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'party_button.dart';

// Pass the phone interstitial overlay to keep cards secret
class PassPhoneOverlay extends StatelessWidget {
  final String teamName;
  final String? playerName;
  final String gameTitle;
  final VoidCallback onReady;

  const PassPhoneOverlay({
    super.key,
    required this.teamName,
    this.playerName,
    required this.gameTitle,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withOpacity(0.97),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Game title badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Text(
                gameTitle,
                style: AppTypography.titleLarge.copyWith(color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 36),

            // Animated Phone Icon Container
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.primary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.phone_android_rounded,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),

            // Instruction title
            const Text(
              'گوشی رو دست‌به‌دست کنید!',
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Target Team / Player
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  Text(
                    'نوبت تیم:',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teamName,
                    style: AppTypography.headlineLarge.copyWith(color: AppColors.accent),
                  ),
                  if (playerName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'نوبت اجرا: $playerName',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'بقیه نباید کلمات رو ببینن! فقط وقتی گوشی رو تحویل گرفتی دکمه رو بزن.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textParagraph),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // Start button
            PartyButton(
              label: 'آماده‌ام، شروع کن!',
              icon: Icons.play_arrow_rounded,
              color: AppColors.success,
              onPressed: onReady,
            ),
          ],
        ),
      ),
    );
  }
}
