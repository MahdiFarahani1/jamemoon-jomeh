import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/app/theme/app_colors.dart';
import 'package:flutter_application_1/app/theme/app_typography.dart';
import 'package:flutter_application_1/core/widgets/animated_party_background.dart';
import 'package:flutter_application_1/core/widgets/party_button.dart';
import 'package:flutter_application_1/core/widgets/party_card.dart';
import 'package:flutter_application_1/core/widgets/party_dialog.dart';
import 'package:flutter_application_1/core/widgets/brand_mark.dart';
import 'package:flutter_application_1/core/widgets/game_emblem.dart';
import 'package:flutter_application_1/core/utils/ranking.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter_application_1/features/teams/presentation/cubit/teams_state.dart';

import '../cubit/tournament_cubit.dart';
import '../cubit/tournament_state.dart';
import 'tournament_podium_page.dart';

// Tournament 5-Stage Dashboard (Zero setState)
class TournamentLobbyPage extends StatelessWidget {
  const TournamentLobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TournamentCubit, TournamentState>(
      listener: (context, state) {
        if (state.isFinished) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TournamentPodiumPage()),
          );
        }
      },
      builder: (context, state) {
        final currentGame = state.currentGame;

        return Scaffold(
          appBar: AppBar(
            title: const Text('جام پنجگانه'),
            actions: [
              IconButton(
                tooltip: 'شروع مجدد مسابقه',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.accent,
                ),
                onPressed: () async {
                  final confirm = await PartyDialog.show(
                    context,
                    title: 'شروع مجدد تورنمنت',
                    message: 'آیا می‌خواهید جام را از مرحله اول و با امتیاز صفر مجدداً شروع کنید؟',
                    confirmLabel: 'بله، از اول',
                  );
                  if (confirm == true && context.mounted) {
                    context.read<TournamentCubit>().startTournament();
                  }
                },
              ),
            ],
          ),
          body: AnimatedPartyBackground(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                children: [
                  // Tournament Header Banner
                  PartyCard(
                    gradient: AppColors.tournamentGradient,
                    child: Column(
                      children: [
                        const TrophyArt(size: 152),
                        const SizedBox(height: 8),
                        const Text(
                          'جام قهرمانی جمعمون جمعه!',
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'مرحله ${(state.currentStageIndex + 1)} از ${state.stages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current Stage Action Card
                  PartyCard(
                    borderColor: AppColors.accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            GameEmblem(gameKey: currentGame.key, size: 76),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'چالش این مرحله:',
                                    style: AppTypography.bodySmall,
                                  ),
                                  Text(
                                    currentGame.titleFa,
                                    style: AppTypography.headlineLarge,
                                  ),
                                  Text(
                                    currentGame.subtitleFa,
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        PartyButton(
                          label: 'شروع رقابت در ${currentGame.titleFa}',
                          icon: Icons.play_arrow_rounded,
                          color: AppColors.accent,
                          textColor: Colors.black87,
                          onPressed: () async {
                            final completed = await Navigator.of(context)
                                .pushNamed('/game/${currentGame.key}');
                            if (completed == true && context.mounted) {
                              context
                                  .read<TournamentCubit>()
                                  .completeCurrentStage();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Live Leaderboard
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'جدول رده‌بندی لحظه‌ای',
                          style: AppTypography.headlineMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'ویرایش تیم‌ها',
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/teams'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  BlocBuilder<TeamsCubit, TeamsState>(
                    builder: (context, teamsState) {
                      final sortedTeams = List.from(teamsState.teams)
                        ..sort((a, b) => b.score.compareTo(a.score));
                      final ranks = denseRanks(
                        sortedTeams.map((team) => team.score as int),
                      );

                      return Column(
                        children: sortedTeams.asMap().entries.map((entry) {
                          final rank = ranks[entry.key];
                          final team = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: rank == 1
                                    ? AppColors.accent
                                    : AppColors.surfaceBorder,
                                width: rank == 1 ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: rank == 1
                                        ? AppColors.accent
                                        : AppColors.surfaceLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: rank == 1
                                            ? Colors.black87
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Color(team.colorValue),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    team.name,
                                    style: AppTypography.headlineMedium,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '${team.score} امتیاز',
                                    textAlign: TextAlign.end,
                                    softWrap: true,
                                    style: AppTypography.titleLarge.copyWith(
                                      color: rank == 1
                                          ? AppColors.accent
                                          : AppColors.textHeadline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Stages Pipeline View
                  const Text(
                    'مراحل مسابقه پنجگانه',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 12),

                  ...state.stages.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final game = entry.value;
                    final isDone = idx < state.currentStageIndex;
                    final isCurrent = idx == state.currentStageIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.surfaceLight
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.primary
                              : (isDone
                                    ? AppColors.success
                                    : AppColors.surfaceBorder),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : (isCurrent
                                      ? Icons.play_circle_fill_rounded
                                      : Icons.lock_outline_rounded),
                            color: isDone
                                ? AppColors.success
                                : (isCurrent
                                      ? AppColors.primary
                                      : AppColors.textMuted),
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'مرحله ${(idx + 1)}: ${game.titleFa}',
                              style: AppTypography.bodyLarge.copyWith(
                                color: isCurrent || isDone
                                    ? AppColors.textHeadline
                                    : AppColors.textMuted,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isDone)
                            const Text(
                              'تکمیل شد',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
