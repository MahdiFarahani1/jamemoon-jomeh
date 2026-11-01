import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/app/theme/app_typography.dart';
import 'package:flutter_application_1/app/di/service_locator.dart';
import 'package:flutter_application_1/core/services/audio_service.dart';
import 'package:flutter_application_1/core/widgets/animated_party_background.dart';
import 'package:flutter_application_1/core/widgets/confetti_overlay.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/core/widgets/party_card.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_state.dart';
import '../cubit/tournament_cubit.dart';

// Championship Celebration & Podium (Zero setState)
class TournamentPodiumPage extends StatelessWidget {
  const TournamentPodiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Play fanfare once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sl<AudioService>().playVictory();
    });

    return Scaffold(
      body: ConfettiOverlay(
        showConfetti: true,
        child: AnimatedPartyBackground(
          child: SafeArea(
            child: BlocBuilder<TeamsCubit, TeamsState>(
              builder: (context, state) {
                final sortedTeams = List.from(state.teams)
                  ..sort((a, b) => b.score.compareTo(a.score));

                final winner = sortedTeams.isNotEmpty ? sortedTeams.first : null;
                final runnerUp = sortedTeams.length > 1 ? sortedTeams[1] : null;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const Spacer(),

                      // Trophy Icon with Glow
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.55),
                              blurRadius: 36,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.emoji_events_rounded, size: 64, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('قهرمان مسابقه پنجگانه!', style: AppTypography.displayLarge, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        'تبریک به تیم برنده جام طلایی جمعمون جمعه',
                        style: AppTypography.bodyLarge.copyWith(color: AppColors.accent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Winner Card
                      if (winner != null)
                        PartyCard(
                          borderColor: AppColors.accent,
                          gradient: AppColors.goldGradient,
                          child: Column(
                            children: [
                              Text(
                                '🥇 رتبه اول و قهرمان کل',
                                style: TextStyle(
                                  color: Colors.black87.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                winner.name,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'مجموع امتیاز: ${winner.score}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Runner-Up Card
                      if (runnerUp != null)
                        PartyCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🥈 رتبه دوم:', style: AppTypography.bodySmall),
                                  Text(runnerUp.name, style: AppTypography.headlineMedium),
                                ],
                              ),
                              Text(
                                '${runnerUp.score} امتیاز',
                                style: AppTypography.headlineMedium.copyWith(color: AppColors.textParagraph),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      // Action Buttons
                      PartyButton(
                        label: 'شروع یک جام دیگر',
                        icon: Icons.refresh_rounded,
                        color: AppColors.primary,
                        onPressed: () {
                          context.read<TournamentCubit>().resetTournament();
                          Navigator.of(context).pushReplacementNamed('/tournament');
                        },
                      ),
                      const SizedBox(height: 10),
                      PartyButton(
                        label: 'بازگشت به صفحه اصلی',
                        color: AppColors.surfaceLight,
                        textColor: AppColors.textHeadline,
                        shadowColor: AppColors.surfaceBorder,
                        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
