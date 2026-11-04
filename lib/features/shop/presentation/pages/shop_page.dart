import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/game_emblem.dart';
import '../../../../core/widgets/party_button.dart';
import '../cubit/shop_cubit.dart';
import '../cubit/shop_state.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  String _key(String icon) => switch (icon) {
    'bomb' => 'hot_potato',
    'five' => 'five_seconds',
    _ => icon,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('اشتراک و بسته‌ها')),
    body: AnimatedPartyBackground(
      child: SafeArea(
        top: false,
        child: BlocConsumer<ShopCubit, ShopState>(
          listener: (context, state) {
            if (state.messageFa != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.messageFa!)),
              );
            }
          },
          builder: (context, state) {
            final available = context.read<ShopCubit>().purchasesAvailable;
            final isOwned = state.purchasedIds.contains('season_1_bundle');

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Header Banner
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: .15),
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      size: 52,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'اشتراک طلایی جمعمون جمعه',
                  style: AppTypography.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  available
                      ? 'یک‌بار برای همیشه؛ کلمات نامحدود و تمام بازی‌های اختصاصی باز می‌شوند.'
                      : 'خرید جدید در حال حاضر در دسترس نیست. دسترسی‌های قبلی شما حفظ شده‌اند.',
                  style: AppTypography.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Main Subscription Card
                for (final product in state.products)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isOwned
                            ? AppColors.success
                            : AppColors.accent.withValues(alpha: .5),
                        width: isOwned ? 2 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isOwned ? AppColors.success : AppColors.accent)
                              .withValues(alpha: .08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            GameEmblem(
                              gameKey: _key(product.iconKey),
                              size: 72,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.titleFa,
                                          style: AppTypography.headlineMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOwned
                                          ? AppColors.success.withValues(alpha: .15)
                                          : AppColors.accent.withValues(alpha: .15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isOwned
                                          ? '✓ فعال در کتابخانه شما'
                                          : '۹۹٬۰۰۰ تومان (دسترسی دائمی)',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isOwned
                                            ? AppColors.success
                                            : AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          product.descriptionFa,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.surfaceBorder),
                        const SizedBox(height: 12),
                        const Text(
                          'امکانات این اشتراک شامل:',
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureItem(
                          icon: Icons.shield_rounded,
                          color: const Color(0xFFE6B85C),
                          title: 'بازی استراتژیک و جذاب «سرقت بزرگ»',
                          desc: 'نقش مخفی، خیانت، دزدی از بانک‌ها و تقسیم غنیمت',
                        ),
                        _buildFeatureItem(
                          icon: Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                          title: '۴۰۰ کارت جدید پانتومیم',
                          desc: 'مجموعاً ۸۰۰ سوژه از کلمات آسان تا ضرب‌المثل‌های دشوار',
                        ),
                        _buildFeatureItem(
                          icon: Icons.forum_rounded,
                          color: AppColors.tabooPrimary,
                          title: '۴۰۰ کارت جدید «حرف نزن، بفهمون!» (تابو)',
                          desc: 'مجموعاً ۸۰۰ کارت با ۲٬۰۰۰ کلمه ممنوعه هیجان‌انگیز',
                        ),
                        _buildFeatureItem(
                          icon: Icons.bolt_rounded,
                          color: AppColors.bombPrimary,
                          title: '۴۰۰ موضوع چالشی «بمب ساعتی»',
                          desc: 'مجموعاً ۸۰۰ موضوع داغ برای پاس‌دادن بمب در جمع',
                        ),
                        _buildFeatureItem(
                          icon: Icons.speed_rounded,
                          color: AppColors.accent,
                          title: '۴۰۰ چالش سرعتی «سه‌تا در ۵ ثانیه»',
                          desc: 'مجموعاً ۸۰۰ پرسش سریع برای سنجش حضور ذهن',
                        ),
                        _buildFeatureItem(
                          icon: Icons.gesture_rounded,
                          color: AppColors.secondary,
                          title: '۴۰۰ سوژه تصویری «نقاشی سریع»',
                          desc: 'مجموعاً ۸۰۰ سوژه خنده‌دار برای کشیدن و حدس‌زدن',
                        ),
                        _buildFeatureItem(
                          icon: Icons.wifi_off_rounded,
                          color: AppColors.textMuted,
                          title: '۱۰۰٪ آفلاین و دائمی',
                          desc: 'بدون نیاز به اینترنت، مصرف حجم یا تمدید ماهیانه',
                        ),
                        const SizedBox(height: 20),

                        // Action Button
                        if (isOwned)
                          PartyButton(
                            label: 'اشتراک شما فعال است',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            onPressed: () {},
                          )
                        else if (available)
                          PartyButton(
                            label: state.isBusy
                                ? 'در حال فعال‌سازی…'
                                : 'خرید اشتراک (۹۹٬۰۰۰ تومان)',
                            icon: Icons.shopping_bag_rounded,
                            color: AppColors.accent,
                            onPressed: state.isBusy
                                ? null
                                : () => context.read<ShopCubit>().buy(product.id),
                          )
                        else
                          OutlinedButton(
                            onPressed: () => _details(
                              context,
                              product.id,
                              product.titleFa,
                              product.priceToman,
                              available,
                              isOwned,
                            ),
                            child: const Text('مشاهده جزئیات'),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.read<ShopCubit>().restore(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('بازیابی خریدهای قبلی'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  static Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textParagraph,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _details(
    BuildContext context,
    String id,
    String title,
    int price,
    bool available,
    bool owned,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              owned
                  ? 'این بسته در کتابخانه شما فعال است.'
                  : available
                  ? 'قیمت: $price تومان'
                  : 'خرید جدید این بسته در حال حاضر در دسترس نیست.',
            ),
            const SizedBox(height: 12),
            FutureBuilder<String>(
              future: _counts(id),
              builder: (context, snapshot) =>
                  Text(snapshot.data ?? 'در حال بررسی محتوای بسته…'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('بستن'),
        ),
        if (available && !owned)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ShopCubit>().buy(id);
            },
            child: const Text('خرید'),
          ),
      ],
    ),
  );

  Future<String> _counts(String id) async {
    const keys = {
      'pack_taboo_full': 'taboo',
      'pack_bomb_full': 'hot_potato',
      'pack_charades_full': 'charades',
      'pack_five_full': 'five_seconds',
      'pack_drawing_full': 'drawing',
    };
    final games = id == 'season_1_bundle'
        ? keys.values.toList()
        : [if (keys[id] != null) keys[id]!];
    if (games.isEmpty) return 'اطلاعات محتوا در دسترس نیست.';
    try {
      var free = 0;
      var full = 0;
      for (final game in games) {
        free += (jsonDecode(
          await rootBundle.loadString('assets/data/$game/pack_free.json'),
        ) as List).length;
        full += (jsonDecode(
          await rootBundle.loadString('assets/data/$game/pack_full.json'),
        ) as List).length;
      }
      return 'کارت‌های پایه: $free\nکارت‌های افزوده این بسته: $full\nشامل بازی اختصاصی سرقت بزرگ';
    } catch (_) {
      return 'اطلاعات محتوای بسته در دسترس نیست.';
    }
  }
}
