import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/party_button.dart';
import '../../../../core/widgets/party_card.dart';
import '../../../../core/widgets/party_dialog.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

// Settings & Preferences Page (Zero setState)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات بازی'),
      ),
      body: AnimatedPartyBackground(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Sound & Audio settings card
                PartyCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('افکت‌های صوتی', style: AppTypography.headlineMedium),
                                Text(
                                  'تیک‌تاک تایمر، صدای انفجار بمب و جشن پیروزی',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: state.soundEnabled,
                            activeThumbColor: AppColors.primary,
                            onChanged: (_) {
                              context.read<SettingsCubit>().toggleSound();
                              if (!state.soundEnabled) {
                                sl<AudioService>().playTick();
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.surfaceBorder, height: 28),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.vibration_rounded, color: AppColors.secondary, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('لرزش و شوک لمسی', style: AppTypography.headlineMedium),
                                Text(
                                  'لرزش هنگام انفجار بمب، لمس دکمه‌ها و پایان زمان',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: state.vibrationEnabled,
                            activeThumbColor: AppColors.secondary,
                            onChanged: (_) {
                              context.read<SettingsCubit>().toggleVibration();
                              if (!state.vibrationEnabled) {
                                sl<HapticsService>().mediumBump();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Reset Game History
                PartyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('پاک‌سازی و راه‌اندازی مجدد', style: AppTypography.headlineMedium),
                      const SizedBox(height: 6),
                      Text(
                        'صفر کردن تمام امتیازها، تیم‌های ذخیره شده و سوابق مسابقات',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      PartyButton(
                        label: 'ریست کردن کل داده‌های محلی',
                        icon: Icons.delete_forever_rounded,
                        color: AppColors.surfaceLight,
                        textColor: AppColors.error,
                        shadowColor: AppColors.surfaceBorder,
                        onPressed: () async {
                          final confirmed = await PartyDialog.show(
                            context,
                            title: 'حذف و بازنشانی کامل',
                            message: 'آیا اطمینان دارید؟ تمام تیم‌ها، بازیکنان و سوابق شما پاک خواهند شد.',
                            confirmLabel: 'بله، حذف کن',
                          );
                          if (confirmed == true && context.mounted) {
                            await context.read<SettingsCubit>().resetAll();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('داده‌های بازی با موفقیت بازنشانی شدند.')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // About section
                PartyCard(
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 36),
                      const SizedBox(height: 12),
                      const Text('جمعمون جمعه!', style: AppTypography.headlineLarge),
                      const SizedBox(height: 4),
                      Text(
                        'نسخه ۱.۰.۰ مخصوص کافه‌بازار',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.accent),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'طراحی شده با عشق برای گرم‌تر شدن دورهمی‌های ایرانی، خنده‌های از ته دل و رقابت‌های نفس‌گیر دوستانه و خانوادگی.',
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
