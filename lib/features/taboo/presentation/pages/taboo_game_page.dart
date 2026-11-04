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

import '../cubit/taboo_cubit.dart';
import '../cubit/taboo_state.dart';
import '../../data/taboo_repository.dart';
import '../widgets/taboo_card_view.dart';

// Taboo Game Page (Zero setState)
class TabooGamePage extends StatelessWidget {
  final GameSetupConfig? setup;
  final bool isQuickMode;
  final bool resumeSaved;
  final String? tournamentId;

  const TabooGamePage({
    super.key,
    this.setup,
    this.isQuickMode = false,
    this.resumeSaved = false,
    this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    return GameContentGate(
      load: () => sl<TabooRepository>().loadCards(),
      child: BlocProvider(
        create: (context) => TabooCubit(
          setup: setup,
          repository: sl<TabooRepository>(),
          isQuickMode: isQuickMode,
          resumeSaved: resumeSaved,
          teamsCubit: isQuickMode ? null : context.read<TeamsCubit>(),
        ),
        child: Builder(
          builder: (context) => GameLifecycleGuard(
            initiallyCovered: context.read<TabooCubit>().hasRestoredSession,
            onPause: () => context.read<TabooCubit>().pause(),
            onResume: () => context.read<TabooCubit>().resume(),
            child: const _TabooGameView(),
          ),
        ),
      ),
    );
  }
}

class _TabooGameView extends StatelessWidget {
  const _TabooGameView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabooCubit, TabooState>(
      builder: (context, state) {
        final assignment = state.isQuickMode
            ? null
            : context.read<TabooCubit>().currentAssignment;
        if (state.isGameOver) {
          return GameCompletionView(
            gameKey: 'taboo',
            result: context.read<TabooCubit>().result,
            onComplete: () => context.read<TabooCubit>().finishAndClear(),
          );
        }
        if (state.isPassPhonePhase) {
          return Scaffold(
            body: PassPhoneOverlay(
              teamName: state.activeTeamName,
              playerName: assignment?.performer,
              partnerName: assignment?.guesser,
              gameTitle: 'حرف نزن، بفهمون! (تابو)',
              onReady: () => context.read<TabooCubit>().startRound(),
            ),
          );
        }

        if (state.isRoundOver) {
          return _buildRoundSummary(context, state);
        }

        return Scaffold(
          appBar: AppBar(
            bottom: const GameSceneRibbon(gameKey: 'taboo'),
            title: Text(state.activeTeamName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                GameLifecycleGuard.of(context).cover();
                final confirm = await PartyDialog.show(
                  context,
                  title: 'خروج از بازی',
                  message: 'آیا می‌خواهید از این بازی خارج شوید؟',
                  confirmLabel: 'بله، خروج',
                );
                if (confirm == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              const GameEmblem(gameKey: 'taboo', size: 36),
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
                tooltip: 'قوانین بازی',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () {
                  GameLifecycleGuard.of(context).cover();
                  HowToPlaySheet.show(context, 'taboo');
                },
              ),
            ],
          ),
          body: AnimatedPartyBackground(
            gameKey: 'taboo',
            score: state.roundScore,
            roundKey: 'taboo_${state.activeTeamIndex}_${state.currentRound}',
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
                    color: AppColors.tabooPrimary,
                    quick: state.isQuickMode,
                  ),
                  if (assignment != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${assignment.performer} توضیح می‌دهد • ${assignment.guesser} حدس می‌زند',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.tabooPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Card Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: state.currentCard != null
                            ? TabooCardView(card: state.currentCard!)
                            : const CircularProgressIndicator(),
                      ),
                    ),
                  ),

                  // Bottom action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        // Foul button (-1)
                        Expanded(
                          child: PartyButton(
                            label: 'تخلف (-۱)',
                            icon: Icons.close_rounded,
                            color: AppColors.error,
                            onPressed: () =>
                                context.read<TabooCubit>().onFoul(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Skip button (0)
                        Expanded(
                          child: PartyButton(
                            label: 'رد کردن',
                            icon: Icons.skip_next_rounded,
                            color: AppColors.surfaceLight,
                            textColor: AppColors.textParagraph,
                            shadowColor: AppColors.surfaceBorder,
                            onPressed: () =>
                                context.read<TabooCubit>().onSkip(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Correct button (+1)
                        Expanded(
                          child: PartyButton(
                            label: 'درست (+۱)',
                            icon: Icons.check_rounded,
                            color: AppColors.success,
                            onPressed: () =>
                                context.read<TabooCubit>().onCorrect(),
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

  Widget _buildRoundSummary(BuildContext context, TabooState state) {
    return Scaffold(
      body: AnimatedPartyBackground(
        gameKey: 'taboo',
        score: state.roundScore,
        roundKey: 'taboo_${state.activeTeamIndex}_${state.currentRound}',
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: PartyCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.alarm_off_rounded,
                    color: AppColors.primary,
                    size: 54,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'زمان این دور تمام شد!',
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
                          'کلمات حدس‌زده درست:',
                          '${state.correctCount}',
                          AppColors.success,
                        ),
                        const SizedBox(height: 8),
                        _buildStatRow(
                          'تخلف‌ها:',
                          '${state.foulCount}',
                          AppColors.error,
                        ),
                        const SizedBox(height: 8),
                        _buildStatRow(
                          'رد شده‌ها:',
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
                    label: context.read<TabooCubit>().isFinalTurn
                        ? 'نمایش نتیجه'
                        : 'نوبت بعدی',
                    icon: context.read<TabooCubit>().isFinalTurn
                        ? Icons.emoji_events_rounded
                        : Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    onPressed: () => context.read<TabooCubit>().nextTurn(),
                  ),
                  const SizedBox(height: 10),
                  PartyButton(
                    label: 'پایان بازی و بازگشت',
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
