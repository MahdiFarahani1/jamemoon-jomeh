import 'package:flutter_application_1/core/widgets/game_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/models/game_setup_config.dart';
import 'package:flutter_application_1/core/widgets/game_scene.dart';
import 'package:flutter_application_1/core/widgets/game_lifecycle_guard.dart';
import 'package:flutter_application_1/core/widgets/game_emblem.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/app/theme/app_typography.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/widgets/animated_party_background.dart';
import 'package:flutter_application_1/core/widgets/round_status.dart';
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
  final GameSetupConfig? setup;
  final bool isQuickMode;
  final bool resumeSaved;
  final String? tournamentId;

  const CharadesGamePage({
    super.key,
    this.setup,
    this.isQuickMode = false,
    this.resumeSaved = false,
    this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    return GameContentGate(
      load: () => sl<CharadesRepository>().loadWords(),
      child: BlocProvider(
        create: (context) => CharadesCubit(
          setup: setup,
          repository: sl<CharadesRepository>(),
          isQuickMode: isQuickMode,
          resumeSaved: resumeSaved,
          teamsCubit: isQuickMode ? null : context.read<TeamsCubit>(),
        ),
        child: Builder(
          builder: (context) => GameLifecycleGuard(
            initiallyCovered: context.read<CharadesCubit>().hasRestoredSession,
            onPause: () => context.read<CharadesCubit>().pause(),
            onResume: () => context.read<CharadesCubit>().resume(),
            child: const _CharadesGameView(),
          ),
        ),
      ),
    );
  }
}

class _CharadesGameView extends StatelessWidget {
  const _CharadesGameView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharadesCubit, CharadesState>(
      builder: (context, state) {
        if (state.isGameOver) {
          return GameCompletionView(
            gameKey: 'charades',
            result: context.read<CharadesCubit>().result,
            onComplete: () => context.read<CharadesCubit>().finishAndClear(),
          );
        }
        if (state.isPassPhonePhase) {
          final assignment = state.isQuickMode
              ? null
              : context.read<CharadesCubit>().currentAssignment;
          return Scaffold(
            body: PassPhoneOverlay(
              teamName: state.activeTeamName,
              playerName: assignment?.performer,
              partnerName: assignment?.guesser,
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
            bottom: const GameSceneRibbon(gameKey: 'charades'),
            title: Text(state.activeTeamName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                GameLifecycleGuard.of(context).cover();
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
              const GameEmblem(gameKey: 'charades', size: 36),
              IconButton(
                tooltip: state.isTimerRunning ? 'توقف' : 'ادامه',
                icon: Icon(
                  state.isTimerRunning
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  color: AppColors.accent,
                ),
                onPressed: () => GameLifecycleGuard.of(context).cover(),
              ),
              IconButton(
                tooltip: 'راهنما و قوانین',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () {
                  GameLifecycleGuard.of(context).cover();
                  HowToPlaySheet.show(context, 'charades');
                },
              ),
            ],
          ),
          body: AnimatedPartyBackground(
            gameKey: 'charades',
            score: state.roundScore,
            roundKey: 'charades_${state.activeTeamIndex}_${state.currentRound}',
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  RoundStatus(
                    score: state.roundScore,
                    remaining: state.remainingSeconds,
                    totalSeconds: state.totalSeconds,
                    round: state.currentRound,
                    totalRounds: state.totalRounds,
                    color: AppColors.charadesPrimary,
                    quick: state.isQuickMode,
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: GamePromptCard(
                          gameKey: 'charades',
                          prompt: currentWord?.word ?? 'در حال بارگذاری...',
                          points: points,
                          hint:
                              'فقط با ایما و اشاره بازی کنید! حرف زدن ممنوعه.',
                        ),
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PartyButton(
                            label: 'رد کردن',
                            icon: Icons.skip_next_rounded,
                            color: AppColors.surfaceLight,
                            textColor: AppColors.textParagraph,
                            shadowColor: AppColors.surfaceBorder,
                            onPressed: () =>
                                context.read<CharadesCubit>().onSkip(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: PartyButton(
                            label: 'حدس درست!',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            onPressed: () =>
                                context.read<CharadesCubit>().onCorrect(),
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
        gameKey: 'charades',
        score: state.roundScore,
        roundKey: 'charades_${state.activeTeamIndex}_${state.currentRound}',
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: PartyCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.theater_comedy_rounded,
                    color: AppColors.charadesSecondary,
                    size: 54,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'زمان پانتومیم تمام شد!',
                    style: AppTypography.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          'کلمات حدس‌زده شده:',
                          '${state.correctCount}',
                          AppColors.success,
                        ),
                        const SizedBox(height: 8),
                        _buildStatRow(
                          'کلمات رد شده:',
                          '${state.skipCount}',
                          AppColors.textParagraph,
                        ),
                        const Divider(
                          color: AppColors.surfaceBorder,
                          height: 20,
                        ),
                        _buildStatRow(
                          'مجموع امتیاز این نوبت:',
                          '${state.roundScore}',
                          AppColors.accent,
                          isBig: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PartyButton(
                    label: context.read<CharadesCubit>().isFinalTurn
                        ? 'نمایش نتیجه'
                        : 'نوبت تیم بعدی',
                    icon: context.read<CharadesCubit>().isFinalTurn
                        ? Icons.emoji_events_rounded
                        : Icons.arrow_forward_rounded,
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

  Widget _buildStatRow(
    String label,
    String value,
    Color color, {
    bool isBig = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBig ? AppTypography.headlineMedium : AppTypography.bodyLarge,
        ),
        Text(
          value,
          style:
              (isBig ? AppTypography.headlineLarge : AppTypography.titleLarge)
                  .copyWith(color: color),
        ),
      ],
    );
  }
}
