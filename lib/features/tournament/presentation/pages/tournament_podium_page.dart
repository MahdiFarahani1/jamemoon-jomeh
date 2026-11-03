import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/models/game_result.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/widgets/animated_party_background.dart';
import '../../../../core/widgets/confetti_overlay.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/party_button.dart';
import '../cubit/tournament_cubit.dart';
import '../cubit/tournament_state.dart';

class TournamentPodiumPage extends StatefulWidget {
  const TournamentPodiumPage({super.key});
  @override
  State<TournamentPodiumPage> createState() => _TournamentPodiumPageState();
}

class _TournamentPodiumPageState extends State<TournamentPodiumPage> {
  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<AudioService>()) sl<AudioService>().playVictory();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ConfettiOverlay(
      showConfetti: !MediaQuery.disableAnimationsOf(context),
      child: AnimatedPartyBackground(
        child: SafeArea(
          child: BlocBuilder<TournamentCubit, TournamentState>(
            builder: (context, state) {
              final teams = state.rankedTeams;
              final result = GameResult.fromTeams(teams);
              final tied = result?.isTie ?? false;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Center(child: TrophyArt(size: 200)),
                      const SizedBox(height: 10),
                      Text(
                        teams.isEmpty
                            ? 'پایان مسابقه'
                            : tied
                            ? 'مسابقه مساوی شد!'
                            : 'قهرمان دورهمی: ${result?.winnerName}',
                        style: AppTypography.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'جام پنجگانه به پایان رسید',
                        style: AppTypography.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      for (var i = 0; i < teams.length; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color:
                                result?.winners.any(
                                      (winner) => winner.id == teams[i].id,
                                    ) ==
                                    true
                                ? const Color(0xFF58402E)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  result?.winners.any(
                                        (winner) => winner.id == teams[i].id,
                                      ) ==
                                      true
                                  ? AppColors.accent
                                  : AppColors.surfaceBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(teams[i].colorValue),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  teams[i].name,
                                  style: AppTypography.headlineMedium,
                                ),
                              ),
                              Text(
                                '${teams[i].score} امتیاز',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      PartyButton(
                        label: 'شروع یک جام دیگر',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          context.read<TournamentCubit>().resetTournament();
                          Navigator.pushReplacementNamed(
                            context,
                            '/tournament',
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      PartyButton(
                        label: 'بازگشت به خانه',
                        color: AppColors.surfaceLight,
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (_) => false,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
