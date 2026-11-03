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
import 'package:flutter_application_1/core/widgets/custom_timer_widget.dart';
import 'package:flutter_application_1/core/widgets/how_to_play_sheet.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/core/widgets/party_dialog.dart';
import 'package:flutter_application_1/core/widgets/pass_phone_overlay.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';

import '../cubit/five_seconds_cubit.dart';
import '../cubit/five_seconds_state.dart';
import '../../data/five_seconds_repository.dart';

// 5-Second Rule Game Page (Zero setState)
class FiveSecondsGamePage extends StatelessWidget {
  final GameSetupConfig? setup;
  final bool isQuickMode;
  final bool resumeSaved;
  final String? tournamentId;

  const FiveSecondsGamePage({
    super.key,
    this.setup,
    this.isQuickMode = false,
    this.resumeSaved = false,
    this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    return GameContentGate(
      load: () => sl<FiveSecondsRepository>().loadQuestions(),
      child: BlocProvider(
        create: (context) => FiveSecondsCubit(
          setup: setup,
          repository: sl<FiveSecondsRepository>(),
          isQuickMode: isQuickMode,
          resumeSaved: resumeSaved,
          teamsCubit: isQuickMode ? null : context.read<TeamsCubit>(),
        ),
        child: Builder(
          builder: (context) => GameLifecycleGuard(
            initiallyCovered: context
                .read<FiveSecondsCubit>()
                .hasRestoredSession,
            onPause: () => context.read<FiveSecondsCubit>().pause(),
            onResume: () => context.read<FiveSecondsCubit>().resume(),
            child: const _FiveSecondsGameView(),
          ),
        ),
      ),
    );
  }
}

class _FiveSecondsGameView extends StatelessWidget {
  const _FiveSecondsGameView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FiveSecondsCubit, FiveSecondsState>(
      builder: (context, state) {
        if (state.isGameOver) {
          return GameCompletionView(
            gameKey: 'five_seconds',
            result: context.read<FiveSecondsCubit>().result,
            onComplete: () => context.read<FiveSecondsCubit>().finishAndClear(),
          );
        }
        if (state.isPassPhonePhase) {
          return Scaffold(
            body: PassPhoneOverlay(
              teamName: state.activeTeamName,
              gameTitle: 'سه‌تا بگو! (قانون ۵ ثانیه)',
              onReady: () => context.read<FiveSecondsCubit>().startQuestion(),
            ),
          );
        }

        final currentQ = state.currentQuestion;

        return Scaffold(
          appBar: AppBar(
            bottom: const GameSceneRibbon(gameKey: 'five_seconds'),
            title: Text(state.activeTeamName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                GameLifecycleGuard.of(context).cover();
                final confirm = await PartyDialog.show(
                  context,
                  title: 'خروج از سه‌تا بگو',
                  message: 'آیا می‌خواهید از بازی خارج شوید؟',
                  confirmLabel: 'بله، خروج',
                );
                if (confirm == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              const GameEmblem(gameKey: 'five_seconds', size: 36),
              IconButton(
                tooltip: 'راهنما و قوانین',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () {
                  GameLifecycleGuard.of(context).cover();
                  HowToPlaySheet.show(context, 'five_seconds');
                },
              ),
            ],
          ),
          body: AnimatedPartyBackground(
            gameKey: 'five_seconds',
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Round & Score indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                  const SizedBox(height: 16),

                  // Giant 5s Circular Timer
                  CustomTimerWidget(
                    remainingSeconds: state.remainingSeconds,
                    totalSeconds: 5,
                    size: 110,
                    activeColor: AppColors.fiveSecPrimary,
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: GamePromptCard(
                          gameKey: 'five_seconds',
                          category: currentQ?.category ?? 'چالش سرعتی',
                          prompt: currentQ?.question ?? 'در حال آماده‌سازی...',
                          hint: 'سریع فکر کن و بلند جواب بده!',
                        ),
                      ),
                    ),
                  ),

                  // Voting / Decision Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: state.isCountdownFinished
                        ? Row(
                            children: [
                              Expanded(
                                child: PartyButton(
                                  label: 'سوخت! (ناموفق)',
                                  icon: Icons.cancel_rounded,
                                  color: AppColors.error,
                                  onPressed: () =>
                                      context.read<FiveSecondsCubit>().onFail(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PartyButton(
                                  label: 'گفت! (موفق +۱)',
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  onPressed: () => context
                                      .read<FiveSecondsCubit>()
                                      .onSuccess(),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: const Text(
                              'سریع ۳ تا پاسخ رو با صدای بلند بگو!',
                              style: AppTypography.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
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
}
