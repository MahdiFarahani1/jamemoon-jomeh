import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/app/theme/app_typography.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/widgets/animated_party_background.dart';
import 'package:flutter_application_1/core/widgets/custom_timer_widget.dart';
import 'package:flutter_application_1/core/widgets/how_to_play_sheet.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/core/widgets/party_card.dart';
import 'package:flutter_application_1/core/widgets/party_dialog.dart';
import 'package:flutter_application_1/core/widgets/pass_phone_overlay.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import '../cubit/charades_cubit.dart';
import '../cubit/charades_state.dart';
import '../../data/charades_repository.dart';

// Charades Game Page (Zero setState)
class CharadesGamePage extends StatelessWidget {
  final bool isQuickMode;

  const CharadesGamePage({super.key, this.isQuickMode = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CharadesCubit(
        repository: sl<CharadesRepository>(),
        isQuickMode: isQuickMode,
        teamsCubit: isQuickMode ? null : context.read<TeamsCubit>(),
      ),
      child: const _CharadesGameView(),
    );
  }
}

class _CharadesGameView extends StatelessWidget {
  const _CharadesGameView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharadesCubit, CharadesState>(
      builder: (context, state) {
        if (state.isPassPhonePhase) {
          return Scaffold(
            body: PassPhoneOverlay(
              teamName: state.activeTeamName,
              gameTitle: 'پانتومیم انفجاری',
              onReady: () => context.read<CharadesCubit>().startRound(),
            ),
          );
        }

        if (state.isRoundOver) {
          return _buildRoundSummary(context, state);
        }

        final currentWord = state.currentWord;
        final points = currentWord?.points ?? 1;

        return Scaffold(
          appBar: AppBar(
            title: Text(state.activeTeamName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                final confirm = await PartyDialog.show(
                  context,
                  title: 'خروج از پانتومیم',
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
                tooltip: state.isTimerRunning ? 'توقف' : 'ادامه',
                icon: Icon(
                  state.isTimerRunning ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                  color: AppColors.accent,
                ),
                onPressed: () => context.read<CharadesCubit>().togglePause(),
              ),
              IconButton(
                tooltip: 'راهنما و قوانین',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => HowToPlaySheet.show(context, 'charades'),
              ),
            ],
          ),
          body: AnimatedPartyBackground(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Header with Timer and Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Text(
                          'امتیاز این دور: ${state.roundScore}',
                          style: AppTypography.titleLarge.copyWith(color: AppColors.accent),
                        ),
                      ),
                      CustomTimerWidget(
                        remainingSeconds: state.remainingSeconds,
                        totalSeconds: state.totalSeconds,
                        size: 76,
                        activeColor: AppColors.charadesSecondary,
                      ),
                      if (!state.isQuickMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Text(
                            'دور ${state.currentRound} از ${state.totalRounds}',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Secret Word Card for the actor
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppColors.charadesGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.charadesPrimary.withOpacity(0.4),
                                blurRadius: 26,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Category and points row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      currentWord?.category ?? 'عمومی',
                                      style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$points امتیاز',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Word
                              Text(
                                currentWord?.word ?? 'در حال بارگذاری...',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.35,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'فقط با ایما و اشاره بازی کنید! حرف زدن ممنوعه.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: PartyButton(
                            label: 'رد کردن',
                            icon: Icons.skip_next_rounded,
                            color: AppColors.surfaceLight,
                            textColor: AppColors.textParagraph,
                            shadowColor: AppColors.surfaceBorder,
                            onPressed: () => context.read<CharadesCubit>().onSkip(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: PartyButton(
                            label: 'حدس درست (+ $points)',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            onPressed: () => context.read<CharadesCubit>().onCorrect(),
                          ),
                        ),
                      ],
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

  Widget _buildRoundSummary(BuildContext context, CharadesState state) {
    return Scaffold(
      body: AnimatedPartyBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PartyCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.theater_comedy_rounded, color: AppColors.charadesSecondary, size: 54),
                  const SizedBox(height: 12),
                  const Text('زمان پانتومیم تمام شد!', style: AppTypography.displayMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow('کلمات حدس‌زده شده:', '${state.correctCount}', AppColors.success),
                        const SizedBox(height: 8),
                        _buildStatRow('کلمات رد شده:', '${state.skipCount}', AppColors.textParagraph),
                        const Divider(color: AppColors.surfaceBorder, height: 20),
                        _buildStatRow('مجموع امتیاز این نوبت:', '${state.roundScore}', AppColors.accent, isBig: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PartyButton(
                    label: 'نوبت تیم بعدی',
                    icon: Icons.arrow_forward_rounded,
                    color: AppColors.charadesPrimary,
                    onPressed: () => context.read<CharadesCubit>().nextTurn(),
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

  Widget _buildStatRow(String label, String value, Color color, {bool isBig = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isBig ? AppTypography.headlineMedium : AppTypography.bodyLarge),
        Text(
          value,
          style: (isBig ? AppTypography.headlineLarge : AppTypography.titleLarge).copyWith(color: color),
        ),
      ],
    );
  }
}
