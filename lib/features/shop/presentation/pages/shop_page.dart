import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../../../core/widgets/party_card.dart';
import '../cubit/shop_cubit.dart';
import '../cubit/shop_state.dart';

// Cafe Bazaar In-App Purchase Store Page (Zero setState)
class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فروشگاه و بسته‌های طلایی'),
        actions: [
          IconButton(
            tooltip: 'بازیابی خریدها',
            icon: const Icon(Icons.restore_rounded),
            onPressed: () {
              context.read<ShopCubit>().restore();
            },
          ),
        ],
      ),
      body: AnimatedPartyBackground(
        child: BlocConsumer<ShopCubit, ShopState>(
          listener: (context, state) {
            if (state.messageFa != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.messageFa!),
                  backgroundColor: AppColors.surfaceLight,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isBusy) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Top Banner
                PartyCard(
                  gradient: AppColors.goldGradient,
                  child: Column(
                    children: [
                      const Icon(Icons.stars_rounded, size: 48, color: Colors.white),
                      const SizedBox(height: 8),
                      const Text(
                        'خرید دائمی و آفلاین',
                        style: AppTypography.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'با یک‌بار خرید، محتوای ویژه برای همیشه در گوشی شما و بدون نیاز به اینترنت فعال می‌ماند.',
                        style: AppTypography.bodyLarge.copyWith(color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Products list
                ...state.products.map((product) {
                  final isPurchased = state.purchasedIds.contains(product.id) ||
                      state.purchasedIds.contains('season_1_bundle');
                  final isBundle = product.id == 'season_1_bundle';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isBundle ? AppColors.accent : AppColors.surfaceBorder,
                        width: isBundle ? 2.5 : 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isBundle
                                    ? AppColors.accent.withOpacity(0.2)
                                    : AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isBundle ? Icons.workspace_premium_rounded : Icons.local_fire_department_rounded,
                                color: isBundle ? AppColors.accent : AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
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
                                    '${product.priceToman} تومان',
                                    style: AppTypography.titleLarge.copyWith(
                                      color: isBundle ? AppColors.accent : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isPurchased)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                                    SizedBox(width: 4),
                                    Text('فعال شده', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.descriptionFa,
                          style: AppTypography.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        if (!isPurchased)
                          PartyButton(
                            label: 'خرید از کافه‌بازار',
                            color: isBundle ? AppColors.accent : AppColors.primary,
                            textColor: isBundle ? Colors.black87 : Colors.white,
                            onPressed: () => context.read<ShopCubit>().buy(product.id),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
