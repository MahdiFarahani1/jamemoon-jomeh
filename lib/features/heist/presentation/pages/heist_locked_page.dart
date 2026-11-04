import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/game_emblem.dart';
import '../../../../core/widgets/party_button.dart';

class HeistLockedPage extends StatelessWidget {
  const HeistLockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سرقت بزرگ'),
      ),
      body: AnimatedPartyBackground(
        gameKey: 'heist',
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        const GameEmblem(gameKey: 'heist', size: 108),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 24,
                            color: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'بازی «سرقت بزرگ» ویژه مشترکین است',
                      style: AppTypography.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'نقش مخفی، دزدی از بانک‌ها، خنثی‌کردن تله‌ها و خیانت به هم‌تیمی‌ها در اشتراک طلایی جمعمون جمعه منتظر شماست!',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textParagraph,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: .3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.stars_rounded, color: AppColors.accent, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'با خرید اشتراک طلایی (۹۹٬۰۰۰ تومان):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _benefit('باز شدن کامل بازی اختصاصی و استراتژیک سرقت بزرگ'),
                          _benefit('بیش از ۲٬۰۰۰ کارت و کلمه جدید در ۵ بازی اصلی'),
                          _benefit('دسترسی همیشگی و ۱۰۰٪ آفلاین در تمام دورهمی‌ها'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    PartyButton(
                      label: 'مشاهده و خرید اشتراک (۹۹٬۰۰۰ تومان)',
                      icon: Icons.shopping_bag_rounded,
                      color: AppColors.accent,
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/shop'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('بازگشت به بازی‌های رایگان'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.accent, fontSize: 16)),
          Expanded(
            child: Text(text, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

