import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/app/theme/app_typography.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/widgets/animated_party_background.dart';
import 'package:flutter_application_1/core/widgets/how_to_play_sheet.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/core/widgets/party_card.dart';
import 'package:flutter_application_1/core/widgets/party_dialog.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import '../cubit/hot_potato_cubit.dart';
import '../cubit/hot_potato_state.dart';
import '../../data/hot_potato_repository.dart';
import '../widgets/bomb_animation_view.dart';

// Hot Potato Game Page (Zero setState)
class HotPotatoGamePage extends StatelessWidget {
  final bool isQuickMode;

  const HotPotatoGamePage({super.key, this.isQuickMode = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HotPotatoCubit(
        repository: sl<HotPotatoRepository>(),
        isQuickMode: isQuickMode,
        teamsCubit: isQuickMode ? null : context.read<TeamsCubit>(),
      ),
      child: const _HotPotatoGameView(),
    );
  }
}

class _HotPotatoGameView extends StatelessWidget {
  const _HotPotatoGameView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HotPotatoCubit, HotPotatoState>(
      builder: (context, state) {
        if (state.isExploded) {
          return _buildExplosionResult(context, state);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('بمب دست کیه؟'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                final confirm = await PartyDialog.show(
                  context,
                  title: 'خروج از مسابقه بمب',
                  message: 'آیا می‌خواهید از بازی خارج شوید؟',
                  confirmLabel: 'بله، خروج',
                );
                if (confirm == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              IconButton(
                tooltip: 'راهنمای بازی',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => HowToPlaySheet.show(context, 'hot_potato'),
              ),
            ],
          ),
          body: AnimatedPartyBackground(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Topic Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PartyCard(
                      borderColor: AppColors.bombPrimary,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.bombPrimary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              state.currentTopic?.category ?? 'موضوع',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.bombPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            state.currentTopic?.topic ?? 'در حال بارگذاری...',
                            style: AppTypography.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Bomb Animation
                  Expanded(
                    child: BombAnimationView(
                      tensionRatio: state.tensionRatio,
                      isExploded: state.isExploded,
                    ),
                  ),

                  // Holding indicator badge
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceBorder, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.touch_app_rounded, color: AppColors.accent, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'الان بمب دست: ',
                          style: AppTypography.bodyLarge,
                        ),
                        Text(
                          state.holdingTeamOrPlayer,
                          style: AppTypography.headlineLarge.copyWith(color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Giant Pass Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: PartyButton(
                      label: 'جواب دادم! پاس به بعدی',
                      icon: Icons.send_rounded,
                      height: 64,
                      color: AppColors.bombPrimary,
                      onPressed: () => context.read<HotPotatoCubit>().passToNext(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExplosionResult(BuildContext context, HotPotatoState state) {
    return Scaffold(
      body: AnimatedPartyBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PartyCard(
              borderColor: AppColors.bombPrimary,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.whatshot_rounded, color: AppColors.bombPrimary, size: 68),
                  const SizedBox(height: 12),
                  const Text('بوووووم! بمب ترکید!', style: AppTypography.displayLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        const Text('بازنده این دور:', style: AppTypography.bodyLarge),
                        const SizedBox(height: 6),
                        Text(
                          state.loserName ?? 'نامشخص',
                          style: AppTypography.displayMedium.copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تعداد کل پاس‌ها در این دور: ${state.turnPassCount} بار',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PartyButton(
                    label: 'دور جدید با موضوع تازه',
                    icon: Icons.refresh_rounded,
                    color: AppColors.primary,
                    onPressed: () => context.read<HotPotatoCubit>().startNewRound(),
                  ),
                  const SizedBox(height: 10),
                  PartyButton(
                    label: 'خروج به منوی اصلی',
                    color: AppColors.surfaceLight,
                    textColor: AppColors.textHeadline,
                    shadowColor: AppColors.surfaceBorder,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
