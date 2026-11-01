import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';

// Custom Card Maker for user's personal gathering words (Zero setState)
class CustomCardsPage extends StatelessWidget {
  const CustomCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = sl<StorageService>();
    final customCardsNotifier = ValueNotifier<List<Map<String, dynamic>>>(storage.getCustomCards());

    final wordController = TextEditingController();
    final categoryController = TextEditingController();

    void showAddCardDialog() {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceBorder, width: 2),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('افزودن کارت اختصاصی', style: AppTypography.headlineLarge, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                TextField(
                  controller: wordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'کلمه یا عبارت (مثلاً: خاطره شمال)',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'دسته‌بندی (مثلاً: خانوادگی)',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 22),
                PartyButton(
                  label: 'ثبت کارت جدید',
                  color: AppColors.success,
                  onPressed: () async {
                    final word = wordController.text.trim();
                    final cat = categoryController.text.trim();
                    if (word.isNotEmpty) {
                      final newCard = {
                        'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        'word': word,
                        'category': cat.isEmpty ? 'شخصی' : cat,
                      };
                      final updated = List<Map<String, dynamic>>.from(customCardsNotifier.value)..add(newCard);
                      await storage.saveCustomCards(updated);
                      customCardsNotifier.value = updated;
                      wordController.clear();
                      categoryController.clear();
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('کارت‌های اختصاصی شما'),
        actions: [
          IconButton(
            tooltip: 'افزودن کارت',
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
            onPressed: showAddCardDialog,
          ),
        ],
      ),
      body: AnimatedPartyBackground(
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: customCardsNotifier,
          builder: (context, cards, _) {
            if (cards.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.note_add_rounded, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text('هنوز کارت اختصاصی نساخته‌اید!', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text(
                        'می‌توانید کلمات، شوخی‌های جمع و اصطلاحات خودتان را برای بازی‌های دورهمی اضافه کنید.',
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      PartyButton(
                        label: 'ساخت اولین کارت',
                        icon: Icons.add_rounded,
                        color: AppColors.primary,
                        onPressed: showAddCardDialog,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          card['category'] ?? 'شخصی',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          card['word'] ?? '',
                          style: AppTypography.headlineMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        onPressed: () async {
                          final updated = List<Map<String, dynamic>>.from(customCardsNotifier.value)..removeAt(index);
                          await storage.saveCustomCards(updated);
                          customCardsNotifier.value = updated;
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
