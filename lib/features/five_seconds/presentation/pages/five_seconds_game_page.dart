import 'package:flutter/material.dart';
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
  final bool isQuickMode;

  const FiveSecondsGamePage({super.key, this.isQuickMode = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FiveSecondsCubit(
        repository: sl<FiveSecondsRepository>(),
        isQuickMode: isQuickMode,
        teamsCubit: isQuickMode ? null : context.read<TeamsCubit>(),
      ),
      child: const _FiveSecondsGameView(),
    );
  }
}

class _FiveSecondsGameView extends StatelessWidget {
  const _FiveSecondsGameView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FiveSecondsCubit, FiveSecondsState>(
      builder: (context, state) {
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
            title: Text(state.activeTeamName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
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
              IconButton(
                tooltip: 'راهنما و قوانین',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => HowToPlaySheet.show(context, 'five_seconds'),
              ),
            ],
          ),
          body: AnimatedPartyBackground(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Round & Score indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Text(
                          !state.isQuickMode
                              ? 'دور ${state.currentRound} از ${state.totalRounds}'
                              : 'حالت آزاد',
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

                  // Question Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppColors.fiveSecGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.fiveSecPrimary.withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  currentQ?.category ?? 'چالش سرعتی',
                                  style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                currentQ?.question ?? 'در حال آماده‌سازی...',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Voting / Decision Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: state.isCountdownFinished
                        ? Row(
                            children: [
                              Expanded(
                                child: PartyButton(
                                  label: 'سوخت! (ناموفق)',
                                  icon: Icons.cancel_rounded,
                                  color: AppColors.error,
                                  onPressed: () => context.read<FiveSecondsCubit>().onFail(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PartyButton(
                                  label: 'گفت! (موفق +۱)',
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  onPressed: () => context.read<FiveSecondsCubit>().onSuccess(),
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
