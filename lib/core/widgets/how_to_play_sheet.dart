import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../utils/game_rules_data.dart';
import 'party_button.dart';

// Modal Sheet for Quick Persian Tutorial Rules
class HowToPlaySheet extends StatelessWidget {
  final String gameKey;

  const HowToPlaySheet({super.key, required this.gameKey});

  static Future<void> show(BuildContext context, String gameKey) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HowToPlaySheet(gameKey: gameKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rule = GameRulesData.allRules[gameKey] ??
        const GameRule(
          gameKey: 'general',
          titleFa: 'راهنمای بازی',
          descriptionFa: 'دورهمی شاد و پرانرژی!',
          rules: ['قوانین را با هم هماهنگ کنید و لذت ببرید.'],
        );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag indicator handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'چطوری بازی کنیم؟',
                    style: AppTypography.headlineLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              rule.titleFa,
              style: AppTypography.headlineMedium.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: 8),
            Text(
              rule.descriptionFa,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.surfaceBorder),
            const SizedBox(height: 12),

            // Rules bullet list
            ...rule.rules.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textHeadline,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            PartyButton(
              label: 'متوجه شدم، بزن بریم!',
              color: AppColors.primary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

