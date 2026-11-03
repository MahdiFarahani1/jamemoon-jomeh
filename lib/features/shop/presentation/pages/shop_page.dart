import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/game_emblem.dart';
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
    appBar: AppBar(title: const Text('کتابخانه بسته‌ها')),
    body: AnimatedPartyBackground(
      child: SafeArea(
        top: false,
        child: BlocConsumer<ShopCubit, ShopState>(
          listener: (context, state) {
            if (state.messageFa != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.messageFa!)));
            }
          },
          builder: (context, state) {
            final available = context.read<ShopCubit>().purchasesAvailable;
            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const Text('بسته‌های بازی', style: AppTypography.displayMedium),
                const SizedBox(height: 8),
                Text(
                  available ? 'محتوای بیشتری برای دورهمی انتخاب کنید.' : 'خرید جدید در حال حاضر در دسترس نیست. دسترسی‌های قبلی شما حفظ شده‌اند.',
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: 24),
                for (final product in state.products)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surfaceBorder),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.titleFa,
                                    style: AppTypography.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.purchasedIds.contains(product.id) ||
                                            state.purchasedIds.contains(
                                              'season_1_bundle',
                                            )
                                        ? 'در کتابخانه شما'
                                        : 'بسته محتوایی',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _details(
                            context,
                            product.id,
                            product.titleFa,
                            product.priceToman,
                            available,
                            state.purchasedIds.contains(product.id) ||
                                state.purchasedIds.contains('season_1_bundle'),
                          ),
                          child: const Text('مشاهده جزئیات'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
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
      return 'کارت‌های پایه: $free\nکارت‌های افزوده این بسته: $full';
    } catch (_) {
      return 'اطلاعات محتوای بسته در دسترس نیست.';
    }
  }
}
